CREATE DEFINER="fotang"@"%" PROCEDURE "get_beneficiaries4principal"(
     p_connId varchar(128)
)
AS
    v_insurerId organisations.insurerid%TYPE;
BEGIN
DECLARE p_caller  char(1)
DECLARE p_subscriberId beneficiaries.subscriberId
DECLARE p_principal beneficiaries.benid TYPE
DECLARE p_polstatus policy_status_types.pol_status_id TYPE
DECLARE p_tags text
DECLARE
    set p_connId=SUBSTRING_INDEX(p_connId, '@', 1);
    IF p_caller='I' THEN
        SET v_insurerId=connId2insurerId(p_connId);
    ELSIF p_caller='C' THEN
        set p_subscriberId=subscriber.connId2subscriberid(p_connId);
        SET v_insurerId=(select insurerid from subscribers where subscriberId=p_subscriberId);
    ELSE
        SIGNAL SQLSTATE '45168' SET MESSAGE_TEXT = 'Unauthorised caller';
    END IF;
    call searchBeneficiaries(p_caller,v_insurerId,null,p_subscriberId,p_principal,null, null, null,null,null,null,null,null,null,null,null,null,
        IF((p_caller='I', null)
        ,p_tags);
END

 INNER JOIN 
SELECT *
FROM table_1
INNER JOIN table_2 ON table_1.une_colonne = table_2.autre_colonne
INNER JOIN table_3 ON table_1.une_colonne = table_3.autre_colonne;

LEFT JOIN 

SELECT *
FROM table_1
LEFT JOIN table_2 ON table_1.une_colonne = table_2.autre_colonne
LEFT JOIN table_3 ON table_1.une_colonne = table_3.autre_colonne;
benId,subscriberId,enrolleId,surname,lastname,status,expiryDate

SELECT surname,lastname,status,expiryDate
FROM beneficiaries b
INNER JOIN subscribers s ON s.subscriberId = b.subscriberId AND s.subscriberId=2179
INNER JOIN enrollees e ON b.enrolleeId = e.enrolleeId
INNER JOIN beneficiary_policy_statuses bps ON b.benId = bps.benId
INNER JOIN beneficiary_plans bp ON b.benId=bp.benId;

 SELECT surname,lastname,middlename,maidenname,blgroup,sex,phone,email,status,expiryDate
    FROM beneficiaries
    INNER JOIN subscribers s ON s.subscriberId = beneficiaries.subscriberId AND s.subscriberId=2179
    INNER JOIN enrollees e ON beneficiaries.enrolleeId = e.enrolleeId
    INNER JOIN beneficiary_policy_statuses bps ON beneficiaries.benId = bps.benId
    INNER JOIN beneficiary_plans bp ON beneficiaries.benId=bp.benId;
 
DELIMITER $
 CREATE PROCEDURE GetBenSubs(IN id_sub varchar(128))
 BEGIN 
 SELECT surname,lastname,middlename,maidenname,blgroup,sex,phone,email,status,expiryDate
    FROM beneficiaries
    INNER JOIN subscribers s ON s.subscriberId = beneficiaries.subscriberId AND s.subscriberId=id_sub
    INNER JOIN enrollees e ON beneficiaries.enrolleeId = e.enrolleeId
    INNER JOIN beneficiary_policy_statuses bps ON beneficiaries.benId = bps.benId
    INNER JOIN beneficiary_plans bp ON beneficiaries.benId=bp.benId;
    END$
DELIMITER;
call GetBenSubs(2179);

-- PetherTe@mOn#1Mission

DELIMITER $
 CREATE PROCEDURE GetBeneficiairiesSubs(IN id_sub varchar(128))
 BEGIN 
    SELECT DISTINCT surname,lastname,middlename,maidenname,blgroup,sex,phone,email,status
    FROM beneficiaries
    INNER JOIN subscribers s ON s.subscriberId = beneficiaries.subscriberId AND s.subscriberId=2179
    INNER JOIN enrollees e ON beneficiaries.enrolleeId = e.enrolleeId
    INNER JOIN beneficiary_policy_statuses bps ON beneficiaries.benId = bps.benId;
    END$
DELIMITER;

call GetBeneficiairiesSubs(2179);
    select  status  from beneficiary_policy_statuses;

     CREATE PROCEDURE GetBeneficiairiesSubs(IN id_sub varchar(128))
 BEGIN 
    SELECT surname,lastname,middlename,maidenname,blgroup,sex,phone,email
    FROM beneficiaries
    INNER JOIN subscribers s ON s.subscriberId = beneficiaries.subscriberId AND s.subscriberId=2179
    INNER JOIN enrollees e ON beneficiaries.enrolleeId = e.enrolleeId;

DELIMITER $
 CREATE PROCEDURE GetBeneficiairiesSubs(IN id_sub varchar(128))
 BEGIN 
    SELECT DISTINCT lastname,middlename,maidenname,blgroup,sex,phone,email,status,expiryDate
    FROM beneficiaries
    INNER JOIN subscribers s ON s.subscriberId = beneficiaries.subscriberId AND s.subscriberId=id_sub
    INNER JOIN enrollees e ON beneficiaries.enrolleeId = e.enrolleeId
    INNER JOIN beneficiary_policy_statuses bps ON beneficiaries.benId = bps.benId
    INNER JOIN beneficiary_plans bp ON beneficiaries.benId=bp.benId;
       END$
DELIMITER;


call getbenficiariesben(2179);
call GetBeneficiairiesSubs(2179);
