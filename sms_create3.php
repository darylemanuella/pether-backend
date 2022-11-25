<?php
else if('p.sbcsms'==$op){
    // send batch number by sms/email
    if(!have_internet())
        send_error('No internet connection',$op,WS_ERR_UNK);
    $serial=mt_rand();
    $new.sql=mysql_val_or_error('batch',$conn, $method);
    $batch0=php_noquote_NVL('batch');
    $to=php_noquote_NVL('to');
    $offs=0; // php appears to append results from successive calls. mark location of our resul.
    // ici si le numero de telephone n'est pas remplis alors il selectionne le numero le telephone a qui appartiaent le batchcode
    if(NULL==$to){
        $to=NULL;
        $proc_save=$proc;   
        $proc= 'p.sbcsms'==$op?'pos_get_beneficiary_phone';
        $params=$batch;
        $result=fetch_data($proc, $params,$offs);
        $proc=$proc_save;
        if(count($result)>0){
           // log_to_file('contact details:'.PHP_EOL. print_r($result, TRUE));
            $result=$result[0];
            if(count($result)>0)
                $to=$result[0]['p.sbcsms'==$op?'telno'];
        }
        if(NULL==$to)
            send_error("Found no ". ('p.sbcsms'==$op?'phone number'),
                $op, WS_ERR_PARAM);
    }
    if('p.sbcsms'==$op && '+'!=$to[0]){
        log_to_file("${GLOBALS['ipaddr']} ${serial} Value ${to} is invalid for SMS");
        send_error("Invalid phone number ${to}", $op);
    }
    $data=fetch_data('pos_getPrescriptions4sms',$batch,$offs);
//    log_to_file('Prescriptions:'.PHP_EOL.print_r($data, FALSE));
    if(0===count($data))
        send_error('There is no data for the batch',$op,WS_ERR_UNK);
    $prescriptions=$data[1];
/*    if(count($prescriptions)==0)
    send_error('There are no prescriptions','',WS_ERR_UNK);
 */
    $meta=$data[0][0];
    $sp=$meta['sp'] ;

    log_to_file("${GLOBALS['ipaddr']} ${serial} ${op} to ${to}");
    $done=false;
    $msg='Failed to send';
    if('p.sbcsms'==$op){

        require_once('../ws-utils/send-sms.php');
        $output=substr($meta['insurer'],0,16)." batch: ${batch0} (".substr($sp,0,20).'/'.substr($meta['pos'],0,15).').';
        if(count($prescriptions)>0){
            $i=1;
            $output.=' Items:'.count($prescriptions).'.'.PHP_EOL;
            foreach($prescriptions as $p)
                $output .= ($i++). '. '.substr($p['name'],0,20) . "=${p['qty']}\n";
        }
         // var_dump($output);
        $exmsg=[];
        try{
            $result=send_sms2($to, $output, $exmsg, true);
        }catch(exception $e){
            send_error($e->getMessage(), $op, WS_ERR_UNK);
        }
        if( qcount($exmsg)>0){
            foreach($exmsg as $msg)
                log_to_file("${GLOBALS['ipaddr']} ${serial} SMS not sent: ${msg}");
            send_error($exmsg[0], $op, WS_ERR_UNK+1); //todo: send all exception messages, not just the first.
        }
        else
            $done=true;
    }

    if(!$done)
        send_error($msg,$op,WS_ERR_UNK);
    log_to_file("${GLOBALS['ipaddr']} ${serial} ${op} to ${to}: Done.");
    // mark batch as sent
    $to=mysqlquote($to, $conn, $method);
    $params="${userId},${batch},${to}";
    try{
        $result=$dbinst->procCall2($proc, $params);
    }catch(exception $e){
        send_result(make_result("OK BUT NOT MARKED: ".$e->getMessage()));
    }
    if($offs !== 0)
        $result=array_slice($result,$offs,NULL,false);
    send_result(make_result($result));
}
?>