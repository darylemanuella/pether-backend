
call pos_mark_batchcode_sms_sent(2898056,'13D9-0DC8-6098-1E31','+23793994625');

-- procedure send sms principal

CREATE DEFINER="fotang"@"%" PROCEDURE "pos_mark_batchcode_sms_sent"(IN p_connId varchar(128),
    p_batch varchar(20), p_to varchar(16))
BEGIN
    call log_activity('pos_prescription','sendsms',p_connId,'batch:'||
        NOTNULL(p_batch)||';'||'to:'||NOTNULL(p_to));
        CALL pos_checkLoginStatus(p_connId, 'pos_mark_batchcode_sms_sent'); 
    INSERT INTO pos_batchcode_sms(batchcode,telno) values(p_batch, p_to);
    update pos_prescription_batches set final=true where batchcode=p_batch;
    call log_activity_final('pos_prescription','sendsms',p_connId,
        'batch:'||(p_batch));
END 
 

-- la premier procedure contlog_activity_finalenue dans la premiere

CREATE DEFINER="fotang"@"%" PROCEDURE "log_activity"(
          IN intopic type of audit_logs.topic,
                  IN inaktion type of audit_logs.aktion,
                  IN inconnId type of audit_logs.connId,
                  IN indetails type of audit_logs.details
        )
begin
        call log_activity0(intopic, inaktion, inconnId, indetails,0);
end 


-- la deuxieme procedure contenue dans la premiere

 | CREATE DEFINER="fotang"@"%" PROCEDURE "pos_checkLoginStatus"(
    INOUT in_connId varchar(256),
    in_procedure VARCHAR(255))
BEGIN
    DECLARE v_remhost TYPE OF pos_logins.RemoteHost;

    SET v_remhost=SUBSTRING_INDEX(in_connId, '@', -1);
    IF v_remhost<>in_connId THEN
        SET in_connId=LEFT(in_connId, LENGTH(in_connId)-LENGTH(v_remhost)-1);
        CALL pos_validate_user_agent(in_connId, v_remhost);
    END IF;
        IF NOT pos_isLoggedIn(in_connId)  THEN
    SIGNAL SQLSTATE '45401' SET MESSAGE_TEXT = 'Not logged in';
    END IF;
END 

-- la  troisieme procedure contenue dans la premiere


CREATE DEFINER="fotang"@"%" PROCEDURE "log_activity_final"(
          IN intopic type of audit_logs.topic,
                  IN inaktion type of audit_logs.aktion,
                  IN inconnId type of audit_logs.connId,
                  IN indetails type of audit_logs.details
        )
begin
        call log_activity0(intopic, inaktion, inconnId, indetails,1);
end 

-- procedure log_activity0

CREATE DEFINER="fotang"@"%" PROCEDURE "log_activity0"(
          IN intopic type of audit_logs.topic,
                  IN inaktion type of audit_logs.aktion,
                  IN inconnId type of audit_logs.connId,
                  IN indetails type of audit_logs.details,
                  IN infinal BOOLEAN)
begin
        DECLARE v_orgId INTEGER DEFAULT NULL;
        DECLARE v_userId INTEGER;


        SET v_userId = connId2userIdA(SUBSTRING_INDEX(inconnId, '@', 1), 0);
        IF v_userId IS NOT NULL THEN SET v_orgId = userId2orgidA(v_userId, 0); END IF;
        BEGIN
                DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

                insert into audit_logs(orgId, topic, aktion, connId, details, final, theTime) values(v_orgId, intopic, inaktion, IFNULL(inconnId,NULLstr()), IFNULL(indetails,NULLstr()), infinal, current_timestamp(6) - INTERVAL CURRENT_TIMEZONE() second);

        END;

end 