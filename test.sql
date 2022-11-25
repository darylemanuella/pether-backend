DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_claim_sms_daryle"(IN p_connId varchar(128),
    p_claimid varchar(10), p_to varchar(16))
BEGIN
    call log_activity('claim_details','sendsms',p_connId,'claimid:'||
        NOTNULL(p_claimid)||';'||'to:'||NOTNULL(p_to));
        -- CALL pos_checkLoginStatus(p_connId, 'pos_claim_sms_sent'); 
    INSERT INTO pos_claim_sms(claimid,telno,sentAt) values(p_claimid,p_to,NOW());
    call log_activity_final('claim_details','sendsms',p_connId,
        'claimid:'||(p_claimid));
END$$
DELIMITER ;
call pos_claim_sms_daryle ('1666193431104.248.170.1090.07902730729340325','10','+237693994625');


DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_claimid"(p_dispId TYPE OF pos_dispensations.dispid)
BEGIN
 SELECT uc._claimid,status 
    FROM pos_dispensations  pd
    JOIN unified_claims  uc ON pd.dispId =uc.dispId 
    join  claim_statuses cs  on uc._claimid=cs._claimid
    where uc.dispId=p_dispId;

END$$
DELIMITER ;
drop procedure get_claimid;
call get_claimid ('3044');