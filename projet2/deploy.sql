-- procedure to retrieve information for one claimid 
DELIMITER $$
CREATE  PROCEDURE get_claimid(IN p_connId varchar(128),IN p_dispId varchar(128))
BEGIN
 SELECT uc._claimid,status 
    FROM pos_dispensations  pd
    JOIN unified_claims  uc ON pd.dispId =uc.dispId 
    join  claim_statuses cs  on uc._claimid=cs._claimid
    where uc.dispId=p_dispId ORDER BY status_id DESC LIMIT 1;
END$$
DELIMITER ;

-- end get_claimid

-- procedure to retrieve the list of dispid  and returns a list of claimid

DELIMITER $$
 CREATE  PROCEDURE get_claim2(IN p_connId varchar(128),IN dispId varchar(8192))
BEGIN

        DECLARE done INT DEFAULT 0;
        DECLARE v VARCHAR(32);
        declare v_count int default 0;
        CALL split(dispId, ' ');
begin
        DECLARE cur CURSOR FOR SELECT column_values as priv FROM the_split_tbl;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cur;
        REPEAT
                FETCH FROM cur INTO v;
                IF NOT done THEN
                        BEGIN
                        call get_claimid(p_connId,v);
                    if ROW_COUNT()>0 then
                        set v_count=v_count+1;
                    end if;
                        END;
                END IF;
        UNTIL done END REPEAT;
        CLOSE cur;
end;
END$$
DELIMITER ;

-- end get_claim2

-- procedure which takes as input the list of claimid and returns the informations for the message with the total insurercost

DELIMITER $$
CREATE  PROCEDURE pos_getsmsclaim5(
   IN  p_claimid varchar(1000)
)
BEGIN


        DECLARE done INT DEFAULT 0;
        DECLARE icost decimal (22, 2) default 0;
        DECLARE v VARCHAR(32);
        DECLARE claim_f VARCHAR(32);
        DECLARE total_icost decimal (22, 2) default 0;
        declare v_count int default 0;
        CALL split(p_claimid, ',');
begin
        DECLARE cur CURSOR FOR SELECT column_values as priv FROM the_split_tbl;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cur;
        REPEAT
                FETCH FROM cur INTO v;
                IF NOT done THEN
                        BEGIN
                        
                        set claim_f=v;
                        set icost=(select insurercost
                        from claim_details
                        where _claimid=v);

                        set total_icost=total_icost+icost;

                    if ROW_COUNT()>0 then
                        set v_count=v_count+1;
                    end if;
                        END;
                END IF;
                
        UNTIL done END REPEAT;
        CLOSE cur;
end;
        SELECT en.surname,telno, sp.name as spname,cd.transdate,total_icost
                        FROM claim_details cd
                        join service_providers sp on sp.spcode=cd.spcode
                        JOIN beneficiaries b ON b.benid=cd.benid
                        JOIN client_phones cp ON cp.benid =cd.benid 
                        JOIN enrollees en ON en.enrolleeid=b.enrolleeid
                        where cd._claimid=claim_f;
END$$
DELIMITER ;

-- end pos_getsmsclaim5

-- procedure to save the claimid and the telephone number in the logs
DELIMITER $$
CREATE  PROCEDURE pos_claim_sms_sent(IN p_connId varchar(128),IN p_claimid VARCHAR(500), p_to varchar(16))
BEGIN


        DECLARE done INT DEFAULT 0;
        DECLARE v VARCHAR(32);
        declare v_count int default 0;
        CALL split(p_claimid, ' ');
begin
        DECLARE cur CURSOR FOR SELECT column_values as priv FROM the_split_tbl;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cur;
        REPEAT
                FETCH FROM cur INTO v;
                IF NOT done THEN
                        BEGIN
                        
                        call log_activity('claim_details','sendsms',p_connId,'claimid:'||
                                NOTNULL(v)||';'||'to:'||NOTNULL(p_to));
                                -- CALL pos_checkLoginStatus(p_connId, 'pos_claim_sms_sent'); 
                        INSERT INTO pos_claim_sms(claimid,telno) values(v,p_to);
                        call log_activity_final('claim_details','sendsms',p_connId,
                                'claimid:'||(v));

                    if ROW_COUNT()>0 then
                        set v_count=v_count+1;
                    end if;
                        END;
                END IF;
        UNTIL done END REPEAT;
        CLOSE cur;
end;   
END$$
DELIMITER ;
-- end pos_claim_sms_sent

-- creation of the table for the messages to be sent with success
CREATE TABLE pos_claim_sms (
  claimid varchar(128) NOT NULL,
  sentAt timestamp NOT NULL DEFAULT current_timestamp(),
  telno varchar(16) NOT NULL
);
-- end creation table 
