
DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "get_claimid"(IN p_connId varchar(128),IN p_dispId  varchar(128))
BEGIN
  if p_dispId=''then 

    SIGNAL SQLSTATE '45410' SET MESSAGE_TEXT = 'veuillez enter au moins un dispid';
    end if;
END$$
DELIMITER ;


 drop procedure get_claimid ;
 drop procedure tes_disp ;
 
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
drop procedure tes_disp;


 CREATE DEFINER="fotang"@"%" PROCEDURE "addPrivilegesToRole"(in_RoleID INTEGER,
 in_privs varchar(8192), IN in_connId varchar(128), OUT out_failed varchar(9000))
BEGIN

        DECLARE done INT DEFAULT 0;
        DECLARE v VARCHAR(32);
    declare v_count int default 0;

        CALL verifyPrivilege(in_connId, 'addPrivilegesToRole', 'USER');
        SET out_failed='';
        CALL split(in_privs, ' ');
begin
        DECLARE cur CURSOR FOR SELECT column_values as priv FROM the_split_tbl;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cur;
        REPEAT
                FETCH FROM cur INTO v;
                IF NOT done THEN
                        BEGIN

                                DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' BEGIN
                                        SET out_failed = v||' ' || out_failed;
                                        END;
                                IF (v = 'USER' AND (NOT wheel(connId2userId(in_connId), '', 0) AND NOT isDbAdmin())) THEN
                                        SET out_failed = v||' ' || out_failed;
                                ELSE
                                        INSERT INTO Permissions(mode,RoleID) VALUES(v,in_RoleID);
                    if ROW_COUNT()>0 then
                        set v_count=v_count+1;
                    end if;
                                END IF;
                        END;
                END IF;
        UNTIL done END REPEAT;
        CLOSE cur;
end;
    if v_count>0 then
        call cachePermissionsForRole(in_RoleID);
    end if;
END 

-- split procedure 


| CREATE DEFINER="fotang"@"%" PROCEDURE "split"(text MEDIUMTEXT, delim VARCHAR(10))
BEGIN
      DECLARE a INT;
      DECLARE str varchar(1024);

    set a=length(text);
    if a<IF(@@max_heap_table_size<@@tmp_table_size,@@max_heap_table_size, @@tmp_table_size) then
            CREATE OR REPLACE TEMPORARY TABLE the_split_tbl(column_values varchar(1024)) engine='memory';
    else
            CREATE OR REPLACE TEMPORARY TABLE the_split_tbl(column_values varchar(1024));
    end  if;
    set a=0;
    IF text is not null then
      simple_loop: LOOP
         SET a=a+1;
         SET str=REPLACE(SUBSTRING(SUBSTRING_INDEX(text, delim, a),
                                        LENGTH(SUBSTRING_INDEX(text, delim, a -1)) + 1), delim, '');
         IF str='' THEN
            LEAVE simple_loop;
         END IF;
         insert into the_split_tbl values (str);
        END LOOP simple_loop;
    end if;

END