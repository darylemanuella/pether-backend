DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_claimid"(IN p_connId varchar(128),IN p_dispId varchar(128))
BEGIN
 SELECT uc._claimid,status 
    FROM pos_dispensations  pd
    JOIN unified_claims  uc ON pd.dispId =uc.dispId 
    join  claim_statuses cs  on uc._claimid=cs._claimid
    where uc.dispId=p_dispId ORDER BY status_id DESC LIMIT 1;
END$$
DELIMITER ;
drop procedure get_claimid;


DELIMITER $$
 CREATE DEFINER="daryle"@"%" PROCEDURE "get_claim2"(IN p_connId varchar(128),IN dispId varchar(8192))
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
call get_claim2('1664978180104.248.170.1090.47420530344751227','3198,3197,3196');
call get_claim2('3198,3197,3196');
DROP PROCEDURE get_claim2;



DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_getsmsclaim5"(
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


call pos_getsmsclaim5('4228334486 3613306910');
call pos_getsmsclaim5('4112282250 2684669214');
call pos_getsmsclaim5('2125972113 401679173');
drop procedure pos_getsmsclaim5 ;
SELECT SUM(prix) AS prix_total
FROM facture
WHERE facture_id = 1


DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "pos_claim_sms_sent"(IN p_connId varchar(128),IN p_claimid VARCHAR(500), p_to varchar(16))
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
drop  PROCEDURE pos_claim_sms_sent;
CALL pos_claim_sms_sent('1664978180104.248.170.1090.47420530344751227','4228334486 3613306910','650214200'); 