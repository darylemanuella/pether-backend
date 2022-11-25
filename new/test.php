if(NULL==$to){
        $to=NULL;
        $proc_save=$proc;
        $proc= 'get_claim_phone';
        $params=$claimid;
        $result1=fetch_data($proc, $params,$offs);

        //var_dump($result);

        $proc=$proc_save;
        if(count($result1)>0){
           // log_to_file('contact details:'.PHP_EOL. print_r($result, TRUE));
            $result1=$result1[0];
            if(count($result1)>0)
                    $to=$result1['telno'];

             var_dump($to);
        }
        //if(NULL==$to)
           // send_error("Found no ". ('phone number'),
                //$op, WS_ERR_PARAM);
    }
    if('p.claimsms'==$op && '+'!=$to[0]){
        log_to_file("${GLOBALS['ipaddr']} ${serial} Value ${to} is invalid for SMS");
        send_error("Invalid phone number ${to}", $op);
    }
