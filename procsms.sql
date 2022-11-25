-- SET SQL_MODE='ORACLE' ;

'p.qdetts'  =>['pos_get_encounter_detail_types', [WS_ID_FIRST, WS_OPT_NONE],
                [['i',ParamAttrib::MANDATORY]]],

-- name operation : p.claimsms
 'p.claimsms'    =>['ghi_central.pos_claim_sms_sent',[WS_ID_FIRST, WS_OPT_NONE, WS_METHOD_POST]],
             [['id', ParamAttrib::MANDATORY]]],
call get_claimid ('3044');

 'p.getclaimid'    =>['ghi_central.get_claimid',[WS_ID_FIRST, WS_OPT_NONE, WS_METHOD_POST]],

'  '  =>['get_claimid',[WS_ID_FIRST, WS_OPT_NONE],
            [[null,null,TPAPP],
            ['dispId']]],





--start of the  procedure with claimid and table claim_details
DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_getsmsclaim"(
    p_claimid TYPE OF claim_details._claimid
)
BEGIN
    IF NOT EXISTS (SELECT * FROM claim_details
        where _claimid = p_claimid) THEN
        SIGNAL SQLSTATE '45410' SET MESSAGE_TEXT = 'No such id claim';
    END IF;
    SELECT en.lastname,cd.insurercost as insurercost,telno, sp.name as spname,cd.transdate
    FROM claim_details cd
    join service_providers sp on sp.spcode=cd.spcode
    JOIN beneficiaries b ON b.benid=cd.benid
    JOIN client_phones cp ON cp.benid =cd.benid 
    JOIN enrollees en ON en.enrolleeid=b.enrolleeid
    where cd._claimid=p_claimid;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_getsmsclaim2"(
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

call pos_getsmsclaim2('4190785902');
drop procedure  pos_getsmsclaim2;
-- end procedure with table claim_details

-- drop procedure pos_getsmsclaim;
-- call pos_getsmsclaim('10');


-- procedure pour recuperer le numero de telephone dubeneficiaire
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

call get_claim_phone('10');

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
 
 drop procedure  pos_claim_sms_sent;drop procedure  pos_claim_sms_sent;

call pos_claim_sms_sent2('1666193431104.248.170.1090.07902730729340325','10','+237650214200');

-- end insert

-- start procedure to recover the claim id after the dispensation

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_claimid"(p_dispId TYPE OF pos_dispensations.dispid)
BEGIN
 DECLARE p_claimid varchar(100);
    DECLARE c1 CURSOR FOR
 SELECT _claimid
    FROM pos_dispensations  pd
    JOIN unified_claims  uc ON pd.dispId =uc.dispId 
    where uc.dispId=p_dispId;

    OPEN c1;
    FETCH c1 INTO p_claimid;
    CLOSE c1;
    SELECT p_claimid;
    -- call get_message_claim(p_claimid);

    select status 
    from claim_statuses cs
    join  claim_details cd  on cd._claimid=cs._claimid
    where cd._claimid=p_claimid;

END$$
DELIMITER ;
drop procedure get_claimid;
call get_claimid ('3039');
-- end procedure to recover the claim id after the pispensation

-- start recover message the status claim

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_message_claim"(p_claimid TYPE OF claim_statuses._claimid)
BEGIN
DECLARE status varchar(30);
    DECLARE c2 CURSOR FOR
select status 
from claim_statuses cs
join  claim_details cd  on cd._claimid=cs._claimid
where cd._claimid=p_claimid;

    OPEN c2;
    FETCH c2 INTO status;
    CLOSE c2;
    SELECT status;

END$$
DELIMITER ;

-- end recover message status claim

call pos_claim_sms_sent('1666277253104.248.170.1090.07086094661695971','10','+237693994625');
drop procedure pos_claim_sms_sent;


 SELECT  dispId
    FROM claim_details  cd
    JOIN unified_claims  uc ON uc._claimid=cd._claimid 
    where uc._claimid=4190785902;

    
    call get_message_claim(4190785902);
    drop procedure get_message_claim;

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_getPrescriptionsmsclaim2"(
    p_dispId type of pos_dispensations.dispId
)
BEGIN

    IF NOT EXISTS (SELECT * FROM pos_dispensations
            where dispId = p_dispId) THEN
            SIGNAL SQLSTATE '45410' SET MESSAGE_TEXT = 'No such dispensation';
        END IF;

    SELECT sp.name ,transdate,insurer_cost as pinsurercost, 
    lastname  
    FROM pos_dispensations p
    join pos_prescription_batches pb on  pb.posCode= p.posCode 
    join points_of_service pos on pb.poscode=pos.poscode
    join service_providers sp on sp.spCode=pos.spCode
    JOIN beneficiaries b ON b.benid=pb.benid
    JOIN enrollees en ON en.enrolleeid=b.enrolleeid 
    where p.dispId=p_dispId;
    END$$
DELIMITER ;
drop procedure pos_getPrescriptionsmsclaim;
-- call pos_getPrescriptionsmsclaim('110');
-- call pos_getPrescriptionsmsclaim2('97');
--  call pos_get_beneficiary_phone_find('110','1666193431104.248.170.1090.07902730729340325');

    -- join claim_details cd ON cd.posCode= pb.posCode 

-- procedure to retrieve the beneficiary's telephone number for sending the message 
DELIMITER $$
    CREATE DEFINER="daryle"@"%" PROCEDURE "pos_get_beneficiary_phone_find"(
        p_dispId type of pos_dispensations.dispId,
        p_connId VARCHAR (128) )
    BEGIN
        declare v_benid type of beneficiaries.benid;  

        set v_benid=(select benid
            from  pos_dispensations p
                JOIN   pos_prescription_batches pb on pb.posCode=p.posCode
            and  p.dispId=p_dispId);

        if v_benid is not null then
            call client_phones_get_canuse(p_connId,null,'B',v_benid,false);
        else
            select 1 from dual where false;
        end if;

    END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_getPrescriptionsmsclaim2"(
    p_dispId type of pos_dispensations.dispId
)
BEGIN

    IF NOT EXISTS (SELECT * FROM pos_dispensations
            where dispId = p_dispId) THEN
            SIGNAL SQLSTATE '45410' SET MESSAGE_TEXT = 'No such dispensation';
        END IF;

    SELECT sp.name ,transdate,insurer_cost as pinsurercost, 
    lastname  
    FROM pos_dispensations p
    join pos_prescription_batches pb on  pb.posCode= p.posCode 
    join points_of_service pos on pb.poscode=pos.poscode
    join service_providers sp on sp.spCode=pos.spCode
    JOIN beneficiaries b ON b.benid=pb.benid
    JOIN enrollees en ON en.enrolleeid=b.enrolleeid 
    where p.dispId=p_dispId;
    END$$
DELIMITER ;
