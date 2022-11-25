-- recover  name beneficiary
DELIMITER $
 CREATE PROCEDURE GetNameben(IN id_sub varchar(128))
 BEGIN 
    SELECT DISTINCT surname,phone
    FROM beneficiaries b
    INNER JOIN subscribers s ON s.subscriberId = b.subscriberId AND s.subscriberId=id_sub
    INNER JOIN enrollees e ON b.enrolleeId = e.enrolleeId
       END$
DELIMITER;
-- pos_get_beneficiary_phone  pour recuperer le numero de telephone
DELIMITER $
 CREATE PROCEDURE GetNameben(IN id_sub varchar(128))
 BEGIN 
 call GetNameben();
 call pos_getPrescriptions4sms()
    SELECT DISTINCT insurercost,totalcost,bencost,createdAt
    FROM beneficiaries b
    INNER JOIN subscribers s ON s.subscriberId = b.subscriberId AND s.subscriberId=id_sub
    INNER JOIN enrollees e ON b.enrolleeId = e.enrolleeId
       END$
DELIMITER;