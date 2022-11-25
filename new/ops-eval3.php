<?php
/*
Webservices for service provider.
Tano Fotang <mtf@fotang.info>

Wed 12 Feb 07:53:52 GMT 2020
 */



function fetch_data($proc, $params, &$skip, $quit_on_error=true){
    global $dbinst;
    $result=null;
    try{
        $result=$dbinst->procCall2($proc, $params);
      //  log_to_file('Footer0'.PHP_EOL.print_r($result, true));
        $len=count($result);
        if($len>0){
            if($skip !==0)
                $result=array_slice($result,$skip,NULL,false);
            $skip=$len;
          //  log_to_file('Result:'.PHP_EOL.print_r($result, true));
        }
    }catch(exception $e){
     //   throw new Exception($e->getMessage());
        $result=null;
        if($quit_on_error)
            send_error($e->getMessage(), '', WS_ERR_DB);
    }
    return $result;
}


/*
function send_ben_auth_code(&$request, $skip=0){
   
     * Send authentication code to a beneficiary.
     * request is an array of:benauthcode,posauthcode,email,phone
     *
     * Send authentication code by email or by sms.
     * Send another code to the caller (the POS)
     * $skip: count of records in any previous proc call. there is an error
     *  where new proc calls have their results appended to those of any
     *  previous call. we shall skip such results.
     *
*/
    global $conn;
    global $dbinst;
    global $op;
    global $ipaddr;

/*start daryle eval to send a details claim sms */

if('p.claimsms'==$op){
    // send claimid number by sms/email
    if(!have_internet())
        send_error('No internet connection',$op,WS_ERR_UNK);
    $serial=mt_rand();
    $claimid=mysql_val_or_error('claimid',$conn, $method);
    $claimid0=php_noquote_NVL('claimid');
    $to=php_noquote_NVL('to');
    $offs=0; // php appears to append results from successive calls. mark location of our resul.
    // ici si le numero de telephone n'est pas remplis alors il selectionne le numero le telephone a qui appartiaent le p_claimidcode
    if(NULL==$to){
        $to=NULL;
        $proc_save=$proc;   
        $proc= 'get_claim_phone';
        $params=$claimid;
        $result=fetch_data($proc, $params,$offs);
        $proc=$proc_save;
        if(count($result)>0){
           // log_to_file('contact details:'.PHP_EOL. print_r($result, TRUE));
            $result=$result[0];
            if(count($result)>0)
                $to=$result['telno'];

        }
        var_dump($result);
        var_dump($to);

        //if(NULL==$to)
           // send_error("Found no ". ('phone number'),
                //$op, WS_ERR_PARAM);
    }
    if('p.claimsms'==$op && '+'!=$to[0]){
        log_to_file("${GLOBALS['ipaddr']} ${serial} Value ${to} is invalid for SMS");
        send_error("Invalid phone number ${to}", $op);
    }
    $data=fetch_data('pos_getsmsclaim',$claimid,$offs);
    var_dump($dada);
//    log_to_file('claims:'.PHP_EOL.print_r($data, FALSE));
    if(0===count($data))
        send_error('There is no data for the claimid',$op,WS_ERR_UNK); 

    $meta=$data[0];
    $spname=$meta['spname'] ;
    $transdate=$meta['transdate'] ;
    $insurercost=$meta['insurercost'] ;
    $lastname=$meta['lastname'] ;
    $to=$meta['telno'] ;
    var_dump($transdate);
    

    log_to_file("${GLOBALS['ipaddr']} ${serial} ${op} to ${to}");
    $done=false;
    $msg='Failed to send';
     if('p.claimsms'==$op){

        require_once('./send-sms.php');
        $output="Dear".$lastname."a claim of." .$insurercost." from ".$name."on".$transdate.
        " has been made for you.Visit Beneficiary App/ Click the link for details. Call PHONE NUMBER for enquiries.";
        $claims=$data[1];
        if(count($claims)>0){
            $i=1;
            $output.=' Claim:'.count($claims).'.'.PHP_EOL;
            foreach($claims as $p)
        $output="Dear".$lastname."a claim of." .$insurercost." from ".$name."on".$transdate.
                $output .= ($i++). '. '.$insurercost. "from".$spname;
        }
         // var_dump($output);
        $exmsg=[];
        try{
            $result=send_sms2($to, $output, $exmsg, true);
        }catch(exception $e){
            send_error($e->getMessage(), $op, WS_ERR_UNK);
        }
        if( count($exmsg)>0){
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
    // mark claimid as sent
    $to=mysqlquote($to, $conn, $method);
    $params="${userId},${claimid},${to}";
    try{
        $result=$dbinst->procCall2($proc, $params);
    }catch(exception $e){
        send_result(make_result("OK BUT NOT MARKED: ".$e->getMessage()));
    }
    if($offs !== 0)
        $result=array_slice($result,$offs,NULL,false);
    send_result(make_result($result));
}

/*  end daryle  */




require_once('./eval-preamble.inc');
if($more_op_checks  && isset($enrol_ops))
    require_once('../../enrolment/ops-eval.inc');
if($more_op_checks && isset($tp_generic_ops))
    require_once('./ops-tp-generic-eval.inc');
if($more_op_checks)
    send_error("Operation not implemented", '', WS_ERR_NOTIMPL);
//EOF
