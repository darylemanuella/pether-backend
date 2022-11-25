                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | character_set_client | collation_connection | Database Collation |
+------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------+----------------------+--------------------+
| get_claims_full0 | PIPES_AS_CONCAT,ANSI_QUOTES,IGNORE_SPACE,ORACLE,NO_KEY_OPTIONS,NO_TABLE_OPTIONS,NO_FIELD_OPTIONS,STRICT_ALL_TABLES,NO_AUTO_CREATE_USER,SIMULTANEOUS_ASSIGNMENT | CREATE DEFINER="fotang"@"%" PROCEDURE "get_claims_full0"(
    p_connId varchar(128)
    ,p_caller char(1)
    ,p_spcode service_providers.spCode%TYPE
    ,p_poscode points_of_service.poscode%TYPE
    ,p_insurerid organisations.insurerid%TYPE
    ,p_subscriberid subscribers.subscriberId%TYPE
    ,p_batchcode pos_prescriptions.batchcode%TYPE
    ,p_batchid user_claims.batchid%TYPE
    ,p_benid claim_details.benid%TYPE
    ,p_claim_type char(1)
    ,p_status varchar(512)

    ,p_settled boolean
    ,p_transmitted boolean
    ,p_restrict boolean
    ,p_startDate date
    ,p_endDate date
    ,p_startpos int
    ,p_count INOUT int
)
AS
BEGIN
    call get_claims_full1(p_connId,p_caller,p_spcode,p_poscode,p_insurerid,null,p_subscriberid,p_batchcode,p_batchid,p_benid,p_claim_type,p_status,p_settled,p_transmitted,p_restrict,p_startDate,p_endDate,p_startpos,p_count);
END 