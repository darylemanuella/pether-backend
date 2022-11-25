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
        $len=count($result);
        if($len>0){
            if($skip !==0)
                $result=array_slice($result,$skip,NULL,false);
            $skip=$len;
        }
    }catch(exception $e){
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
 
   
    $data=fetch_data('pos_getsmsclaim',$claimid,$offs);

    if(0===count($data))
        send_error('There is no data for the claimid',$op,WS_ERR_UNK);
    $meta=$data[0];
    $spname=$meta['spname'] ;
    $transdate=$meta['transdate'] ;
    $insurercost=$meta['insurercost'] ;
    $surname=$meta['surname'] ;
    $to=$meta['telno'] ;    
   //var_dump($meta);

    log_to_file("${GLOBALS['ipaddr']} ${serial} ${op} to ${to}");
    $done=false;
    $msg='Failed to send';
    if('p.claimsms'==$op){
 
        require_once('./send-sms.php');
        $output="Dear ".$surname.", a claim of " .$insurercost." GHC from ".$spname." on ".$transdate.
        " has been made for you. Visit Beneficiary App for details. Call 050 168 9577 or 020 020 3967 for enquiries.";

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
	    send_result(make_result("OK BUT NOT MARKED: "));
		    //.$e->getMessage()));
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
