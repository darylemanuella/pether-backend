CREATE DEFINER="fotang"@"%" PROCEDURE "pos_finalise_dispensation"(
    p_connId varchar(128)
    ,p_dispId TYPE OF pos_dispensations.dispid
    ,p_insurercost TYPE OF pos_dispensations.insurer_cost
)
BEGIN
    DECLARE v_poscode TYPE OF points_of_service.poscode;
    DECLARE v_rcount int;
    declare v_pkgid TYPE OF pos_dispensations.packageid;
    declare v_rem TYPE OF pos_dispensations.coverageRemark;
    declare v_presid TYPE OF pos_dispensations.presid;
    declare v_qty TYPE OF pos_prescriptions.qty;

    CALL log_activity('pos_dispensation','finalise',p_connId,'id:'||
        NOTNULL(p_dispId));
        CALL pos_checkLoginStatus(p_connId, 'pos_finalise_dispensation');
    SET v_poscode=pos_connId2poscode(p_connId, TRUE);
    select packageid,coverageRemark
        into v_pkgid,v_rem from pos_dispensations
        where dispid=p_dispId;
    IF found_rows()=0 THEN
                SIGNAL SQLSTATE '45106' SET MESSAGE_TEXT = 'No such dispensation record';
        END IF;
    IF v_pkgid IS NULL THEN
        set @msg='No plan. Reason: '||ifnull(v_rem,'-');
        SIGNAL  SQLSTATE '45106' SET MESSAGE_TEXT = @msg;
    END IF;

    IF EXISTS(SELECT * FROM pos_completed_dispensations
                WHERE dispId=p_dispId) THEN
        SIGNAL  SQLSTATE '45111' SET MESSAGE_TEXT = 'Dispensation is already finalised';
    END IF;


    select d.presId, ifnull(mpres.qty,p.qty)
    into v_presid, v_qty
    from pos_dispensations d
    join pos_prescriptions p on p.presId=d.presId and d.posCode=v_poscode
    left join pos_modified_prescriptions mpres on mpres.presid=p.presId
    where d.dispid=p_dispId;

    IF @pos_finalise_dispensation IS NOT NULL THEN
        SIGNAL SQLSTATE '45099' SET MESSAGE_TEXT = 'Fatal error (finalise_dispensation). Contact vendor.';
    END IF;
    call check_claim_stale(p_dispId,current_date,
        (select spcode from points_of_service where poscode=v_poscode),v_pkgid);
    BEGIN
        declare v_id type of claim_details._claimid;
        DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
            set @pos_finalise_dispensation=null;
            ROLLBACK;
            RESIGNAL;
        END;
        set @pos_finalise_dispensation=true;
        START TRANSACTION;
        insert into pos_completed_dispensations(dispId,poscode) values(p_dispId,v_poscode);
        call make_unified_claim(p_dispId,null,null, v_id);

        insert into claim_details(_claimId, benid, insurerid,
            subscriberid, qty,totalcost,insurercost,copay,
            packageid,catid,transdate)
            values(v_id, 0,0,0, 0,0,p_insurercost,0 ,0, '0',0);

        if v_qty<= (select ifnull(sum(c.qty),0)
                from claim_details  
                join claim_statuses st on st._claimid=c._claimid
                join unified_claims unc on unc._claimId=c._claimId
                join pos_completed_dispensations cd on cd.dispid=unc.dispid
                join pos_dispensations d on d.dispid=cd.dispid and d.presid=v_presid
                where st.status NOT IN('canceled','rejected') and st.asof=(select max(asof) from claim_statuses where _claimid=c._claimid))
            then
            UPDATE pos_prescriptions p
                SET p.status='F' WHERE p.presId=v_presid;
        end if;
        COMMIT;
        set @pos_finalise_dispensation=null;
    END;

    CALL log_activity_final('pos_dispensation','finalise',p_connId, 'id:'||p_dispId);
END 