DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_getsmsclaim"(
    p_claimid TYPE OF claim_details._claimid
)
BEGIN
    IF NOT EXISTS (SELECT * FROM claim_details
        where _claimid = p_claimid) THEN
        SIGNAL SQLSTATE '45410' SET MESSAGE_TEXT = 'No such id claim';
    END IF;
    SELECT en.surname,cd.insurercost as insurercost,telno, sp.name as spname,cd.transdate
    FROM claim_details cd
    join service_providers sp on sp.spcode=cd.spcode
    JOIN beneficiaries b ON b.benid=cd.benid
    JOIN client_phones cp ON cp.benid =cd.benid 
    JOIN enrollees en ON en.enrolleeid=b.enrolleeid
    where cd._claimid=p_claimid;
END$$
DELIMITER ;

-- end procedure with table claim_details

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_claim_phone"(
    p_claimid TYPE OF claim_details._claimid
)
BEGIN
    SELECT telno
    FROM client_phones  cp
    JOIN claim_details cd ON cp.benid =cd.benid 
    where cd._claimid=p_claimid;
END$$
DELIMITER ;

--start to insert into claimID and telno in the table pos_claim_sms
DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_claim_sms_sent"(IN p_connId varchar(128),
    p_claimid varchar(10), p_to varchar(16))
BEGIN
    call log_activity('claim_details','sendsms',p_connId,'claimid:'||
        NOTNULL(p_claimid)||';'||'to:'||NOTNULL(p_to));
        CALL pos_checkLoginStatus(p_connId, 'pos_claim_sms_sent'); 
    INSERT INTO pos_claim_sms(claimid,telno) values(p_claimid,p_to);
    call log_activity_final('claim_details','sendsms',p_connId,
        'claimid:'||(p_claimid));
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_claim_sms_sent"(IN p_connId varchar(128),
    p_claimid varchar(10))
BEGIN
    call log_activity('claim_details','sendsms',p_connId,'claimid:'||
        NOTNULL(p_claimid)||';'||'to:'(to));
        CALL pos_checkLoginStatus(p_connId, 'pos_claim_sms_sent'); 
    INSERT INTO pos_claim_sms(claimid,telno) values(p_claimid,to);
    call log_activity_final('claim_details','sendsms',p_connId,
        'claimid:'||(p_claimid));
END$$
DELIMITER ;
 
 drop procedure pos_claim_sms_sent;
-- end insert

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_claimid"(IN p_connId varchar(128),p_dispId TYPE OF pos_dispensations.dispid)
BEGIN
 SELECT uc._claimid,status 
    FROM pos_dispensations  pd
    JOIN unified_claims  uc ON pd.dispId =uc.dispId 
    join  claim_statuses cs  on uc._claimid=cs._claimid
    where uc.dispId=p_dispId ORDER BY status_id DESC LIMIT 1;
END$$
DELIMITER ;
call get_claimid ('3058');
