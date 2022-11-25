SET SQL_MODE='ORACLE' ;
DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE get_claim_taints2(
    p_connId    varchar(128)

    ,p_caller   char(1)

    ,p_claimid  tainted_claim_details._claimid%type

    ,p_startDate date

    ,p_endDate date

)

    READS SQL DATA

as

   

begin

    call enrolutil.checkLoginStatus(p_connId,p_caller, 'get_claim_taints2');

  

   if p_claimid is not null then

        select tc._claimid claimid, tc.taintid as id, e.lastname as holderlname, e.surname as holdersname, tc.qty, tc.insurercost icost,tc.orig_qty, tc.orig_insurercost orig_icost,

            status_ok_id is not null as accepted, tc.asof createdAt, userid2name(tc.createdBy) as createdBy

            FROM tainted_claim_details tc

            join beneficiaries b on tc.benid=b.benId

            join enrollees e on e.enrolleeId=b.enrolleeId

            left join deleted_claims dcl on dcl._claimid=tc._claimid

            where tc._claimid=p_claimid and dcl._claimid is null;

    else

        declare v_sql text;

        begin

            set p_startDate=ifnull(p_startDate, current_date - interval 1 MONTH);

            set v_sql =

                'select tc._claimid claimid, tc.taintid as id, e.lastname as holderlname, e.surname as holdersname, tc.qty, tc.insurercost icost,tc.orig_qty, tc.orig_insurercost orig_icost,

                    status_ok_id is not null as accepted, tc.asof createdAt, userid2name(tc.createdBy) as createdBy

                    from tainted_claim_details tc

                    join claim_details c on c._claimid=tc._claimid

                    join beneficiaries b on tc.benid=b.benId

                    join enrollees e on e.enrolleeId=b.enrolleeId

                    left join deleted_claims dcl on dcl._claimid=tc._claimid'; 

            if (p_caller='I') then

                set v_sql=v_sql|| ' where c.insurerid='||connid2insurerid(p_connId);

            elsif p_caller='S' then

                set v_sql=v_sql|| ' join unified_claims uc on uc._claimid=c._claimid where uc.dispid is not null and c.spcode='''||sp.connid2spcode(p_connId)||'''';

            elsif p_caller='C' then

                 set v_sql=v_sql|| ' join unified_claims uc on uc._claimid=c._claimid where uc.claimid is not null and c.subscriberid='||subscriber.connid2subscriberid(p_connId);

            elsif p_caller='B' then

                 set v_sql=v_sql|| ' join unified_claims uc on uc._claimid=c._claimid where uc.claimid is not null and c.benid='''||ben_connId2benid(p_connId, true)||'''';

            else

                SIGNAL SQLSTATE '45481' SET MESSAGE_TEXT = 'Unknown caller';

            end if;

            set v_sql=v_sql ||' and dcl._claimid is null and tc.asof>='''||p_startDate||'''';

            if p_endDate is not null then

                set v_sql=v_sql||' and tc.asof<='''||(p_endDate + interval 1 DAY)||'''';

            end if;

            execute immediate v_sql;

        end;

    end if;

end$$
DELIMITER ;