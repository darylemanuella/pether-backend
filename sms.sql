CREATE DEFINER="fotang"@"%" PROCEDURE "pos_getClaims4sms"(
    p_claimid TYPE OF claim_details._claimid
)
BEGIN
    IF NOT EXISTS (SELECT * FROM claim_details
        where _claimid = p_claimid) THEN
        SIGNAL SQLSTATE '45410' SET MESSAGE_TEXT = 'No such claim';
    END IF;
    SELECT o.alias as insurer, sp.name as spname,cd.insurercost as icost,en.lastname,cp.telno,en.dob,en.sex, cd.createdAt
    FROM claim_details cd
    join service_providers sp on sp.spcode=cd.spcode
    JOIN beneficiaries b ON b.benid=cd.benid
    LEFT JOIN client_phones cp ON cp.benid=b.benid
    JOIN enrollees en ON en.enrolleeid=b.enrolleeid
    join organisations o on o.insurerid=cd.insurerId
    where cd._claimid=p_claimid;
END 