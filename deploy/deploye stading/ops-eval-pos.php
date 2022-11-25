<?php
/*
Webservice operations for POS service delivery
mtf@fotang.info
Rewritten: Mon Jan 21 19:34:11 WAT 2019
*/

//log_to_file("${ipaddr} << ${params_attrib}\n". var_dump($params_attrib));

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
function fetch_email_footer(&$offs, $batchid, $requestid=null){
    global $conn;
    
    $requestid= null==$requestid? 'NULL':mysqlquote($requestid,  $conn);
    $batchid= null==$batchid? 'NULL':mysqlquote($batchid,  $conn);
    $footer=fetch_data('get_email_footer',"${batchid},${requestid}", $offs, false);
    if($footer){
     //   log_to_file('Footer1'.PHP_EOL.print_r($footer, true));
        $footer=count($footer)>0? $footer[0]['footer']: null;
    }
    return $footer;
}

function notify_approvers($request, $skip=0){
    /*
     * request is an array of:
     * reqid,auth_class_id.
     * Fetch distinct approvers for reqid
     * $skip: count of records in any previous proc call. there is an error
     *  where new proc calls have their results appended to those of any
     *  previous call. we shall skip such results.
     **/
    global $conn;
    global $dbinst;

//    log_to_file("now running post-op");

    if(count($request)==0)
        return;
    if(!have_internet())
        throw new Exception('No internet connection');
    $serial=$dbinst->getSerial();
    $proc="pos_get_approvers";
    $reqid=$request[0]['reqid'];
    $params=mysqlquote($reqid,  $conn);
    try{
        $result=$dbinst->procCall2($proc, $params);
        $reslen=count($result);
    }catch(exception $e){
        throw new Exception($e->getMessage(), WS_ERR_DB);
    }
    if($skip !==0)
        // skip results of first previous proc call
        $result=array_slice($result,$skip,NULL,false);
//    log_to_file(print_r($result, true));
    if(count($result)==0)
        return;
    $allowed=$result[2][0]; // allowed communication channels: sms, email
    if(!$allowed['sms'] && !$allowed['email']) // not allowed to send sms or email notifications
       return; 
    $approver=$result[0];
    $details=$result[1][0]; /* product and beneficiary */
    $stage=$details['stage']=='D'?"dispensation":"prescription";
    $emailtxt=null;
    $smstxt=null;
    $eaddrs=[];
    $phones=[];
    $url="https://bit.ly/3Nlqkl8"; //https://insure.pether.io/serviceproviders/approval: https://bit.ly/3qYDjQj
    $url_email="/serviceproviders/approval/request/${reqid}";

    /* construct message and recepients */
    foreach($approver as $c){
        if($c["TxMode"]=='email'){
            if(!$allowed['email']) continue;
            $pos=strpos($c['value'],'@');
            if(!$pos || strlen($c['value'])==$pos){
                log_to_file("${GLOBALS['ipaddr']} ${serial} INFO: Value ${c['value']} is invalid for ${c['TxMode']}");
                continue;
            }
            if(!$emailtxt){
                $emailtxt=
"You are set as approver for the ${stage} of the service <em>${details['category']}</em>. Details:<br/>
Beneficiary: ${details['patient']}<br/>
Subscriber: ${details['subscriberName']}<br/>
Provider:  ${details['sp']}/  ${details['city']}<br/>
Service:  ${details['productName']}/   ${details['category']}
<p>
To start the approval process, log in to the system at <a href='${url}' title='start approval'>${url}</a> or, if you are already logged in, <a href='${url_email}' title='start approval'>go directly to the request.</a>. 
</p>";
            }
            $eaddrs[]=['to'=>$c['value'], 'name'=>$c['approver']];
        }else if('sms'==$c["TxMode"]){
            if(!$allowed['sms']) continue;
            if('+' != $c['value'][0]){
                log_to_file("${GLOBALS['ipaddr']} ${serial} INFO: Value ${c['value']} is invalid for ${c['TxMode']}");
                continue;
            }
            if(!$smstxt){
                $tt=".\nVisit ${url}.";
                $smstxt=
                    //"${details['stage']}-Approval needed by ${details['sp_alias']}:\nBenef.:${details['patient']}@${details['subscriber_alias']} for ${details['category']} (${details['productName']})\nApprove at ${url}.";
                    "${details['stage']}-Approval needed by ${details['sp_alias']}:\nBenef.:${details['patient']}@${details['subscriber_alias']} for ${details['productName']}";
                $smstxt=substr($smstxt,0,158-strlen($tt)) . $tt; // try to send only 1 SMS (160 bytes)
            }
            $phones[]=$c['value'];
        }else
            log_to_file(
                "${GLOBALS['ipaddr']} ${serial} INFO: Unknown TxMode ${c['TxMode']} for ${reqid}");
    }

    /* send emails */
    if(count($eaddrs)>0){
        require_once('./send-email.php');

        $footer=fetch_email_footer($reslen, null, $reqid);
        foreach($eaddrs as $to){
            $res=email_approver("Dear ${to['name']},<br/>".$emailtxt, $to['to'],
                $to['name'], "Approval request for ${stage}", $footer);
            if($res){
                $msg="Unable to send email for ${reqid} to ${to['to']}: ".$res->ErrorInfo;
                log_to_file("${GLOBALS['ipaddr']} ${serial} INFO: ${msg}");
            }else
                log_to_file("${GLOBALS['ipaddr']} ${serial} INFO: Sent email to ${to['to']} for ${reqid}");
        }
    }
    /* send SMS */
    if(count($phones)>0){
        require_once('../ws-utils/send-sms.php');
        $to_str=arrayToString($phones,',');
        log_to_file("${GLOBALS['ipaddr']} ${serial} INFO: Sending approver SMS to: ${to_str}");
        $exmsg=[];
        try{
            $result=send_sms2($phones, $smstxt, $exmsg);
        }catch(exception $e){
           $txt="Failed to send sms one or more of ${to_str}: ". $e->getMessage();
           log_to_file("${GLOBALS['ipaddr']} ${serial} FAILED: ${txt}");
           throw new Exception($txt, WS_ERR_OPPROC);
        }
        if(count($exmsg)>0){
            $msg=implode(PHP_EOL, $exmsg);
            log_to_file("${GLOBALS['ipaddr']} ${serial} INFO: Failed approver SMS: ${msg}");
        }
    }
}

function send_ben_auth_code(&$request, $skip=0){
    /*
     * Send authentication code to a beneficiary.
     * request is an array of:benauthcode,posauthcode,email,phone
     *
     * Send authentication code by email or by sms.
     * Send another code to the caller (the POS)
     * $skip: count of records in any previous proc call. there is an error
     *  where new proc calls have their results appended to those of any
     *  previous call. we shall skip such results.
     **/
    global $conn;
    global $dbinst;
    global $op;
    global $ipaddr;

    if(!is_array($request) || count($request)==0)
        return;
    if(array_key_exists('posauthcode', $request[0]) && NULL===$request[0]['posauthcode']){
      //  var_dump($request);
        $request=['code'=>null, 'benid'=>(isset($request[0]['benid'])? $request[0]['benid']:null)];
        return;
    }
    $serial=$dbinst->getSerial();

    if(!( (isset($request[0]['benauthcode']) ||array_key_exists('benauthcode', $request[0])) &&
        (isset($request[0]['benid']) ||array_key_exists('benid', $request[0])) &&
        (isset($request[0]['posauthcode']) ||array_key_exists('posauthcode', $request[0])) &&
        (isset($request[0]['pos']) ||array_key_exists('pos', $request[0])) &&
        (isset($request[0]['name']) ||array_key_exists('name', $request[0])) &&
        (isset($request[0]['sp']) ||array_key_exists('sp', $request[0])) &&
        (isset($request[0]['city']) ||array_key_exists('city', $request[0])))
        ||
        (! (isset($request[0]['phone']) ||array_key_exists('phone', $request[0])) && ! (isset($request[0]['email']) ||array_key_exists('email', $request[0])))){
        log_to_file("${ipaddr} ${serial} FAILED: Invalid result set");
        send_error("Invalid data encountered. Please contact support (ID: ${serial})", $GLOBALS['op'], WS_ERR_UNK);
    }

    if(!have_internet()){
        $txt='No internet connection';
        log_to_file("${ipaddr} ${serial} FAILED: ${txt}");
        send_error("${txt} (incident ID: ${serial})", $op, WS_ERR_UNK);
        // throw new Exception('No internet connection');
    }
    $benauthcode=$request[0]['benauthcode'];
    $posauthcode=$request[0]['posauthcode'];
    $benid=$request[0]['benid'];
    $phone=$request[0]['phone'];
    $email=$request[0]['email'];
    $to_name=$request[0]['name'];
    $pos=$request[0]['pos'];
    $sp=$request[0]['sp'];
    $city=$request[0]['city'];
    $timeout=$request[0]['timeout'];

    $sent_email=false;
    $sent_sms=false;

    if($email !== null){
        require_once('../ws-utils/send-email.php');
  //      $footer=fetch_email_footer($reslen, null, $reqid);

        $emailtxt="<html><body><p>Dear ${to_name},</p><P>\nYou, or someone using your ID, is trying to get health benefits at:<ul><li>Provider: ${sp} (${pos})</li><li>Location: ${city}.</li></ul></P><P>To confirm that you are the one, give the following code to the person who is serving you:</p><P style='font-size:large;text-align:center;letter-spacing: 3px;'><strong>${benauthcode}</strong></p><P><br/>The code will expire in ${timeout} minutes. Thank you.</P></body></html>";
        $res=send_email($email, $to_name, "Confirm Service at ${sp}",
            $emailtxt,
            strip_tags($emailtxt), "Petherinsure POS");
        if($res){
            $msg="Unable to email auth code to ${email}: ".$res->ErrorInfo;
            log_to_file("${ipaddr} ${serial} INFO: ${msg}");
        }
        else
            $sent_email=true;
    }
    if($phone !==null){
        require_once('../ws-utils/send-sms.php');
        $sp_alias=strlen($sp)<41? $sp: isset($request[0]['spalias']) ?$request[0]['spalias']: substr($sp,0,40);
        $city=substr($city,0,15);
        $smstxt="Your PI service code is ${benauthcode}. It expires in ${timeout} minutes. Show it to ${sp_alias}, ${city}.";
        $exmsg=[];
        try{
            $result=send_sms2($phone, $smstxt, $exmsg);
        }catch(exception $e){
           $txt="Failed to send sms ${to_str}: ". $e->getMessage();
           log_to_file("${ipaddr} ${serial} FAILED: ${txt}");
            send_error("${txt} (incidence ID: ${serial})", $op, WS_ERR_UNK);
        }
        if(count($exmsg)>0){
            foreach($exmsg as $msg)
                log_to_file("${ipaddr} ${serial} INFO: ${msg}");
        }else
            $sent_sms=true;
    }
    if(!sent_sms && !sent_email){
        $txt='Unable to send confirmation token';
        log_to_file("${ipaddr} ${serial} FAILED: ${txt}");
         //  throw new Exception('Unable to send a confirmation code');
        send_error("${txt} (incidence ID: ${serial})", $op, WS_ERR_OPPROC);
    }
    if(!sent_email)
        if($email!==null){
            $txt="Unable to send email to ${email}";
             send_error(($sent_sms?'SMS sent but ' .$txt : $txt). "(incidence ID: ${serial})", $op, WS_ERR_UNK);
        }
    
    if(!sent_sms)
        if($phone!==null){
            $txt="Unable to send SMS to ${phone}";
            send_error(($sent_email?'Email sent but ' .$txt : $txt). "(incidence ID: ${serial})", $op, WS_ERR_OPPROC);
            //throw new Exception($sent_email?'Email sent but ' .$txt : $txt);
        }
    $request=['code'=>$posauthcode, 'benid'=>$benid];
}

require_once('./eval-preamble.inc');
if($more_op_checks==false){ }
else{
$more_op_checks=false;

if('login'==$op){
    if(!isset($_SERVER['HTTP_USER_AGENT']))
        send_error('User agent is not set', $op, WS_ERR_UNK);
    $ua=mysqlquote($_SERVER['HTTP_USER_AGENT'], $conn);

    $remHost =$ipaddr;
	$remHost = mysqlquote($remHost, $conn, $method);
	$machineID = mysql_val_or_error('mid', $conn, $method);
	$machineIDType = mysql_val_or_error('midtype', $conn, $method);
    $params = mysql_val_or_error('user', $conn, $method) . ','. mysql_val_or_error('pass', $conn, $method).','.
        $machineID . "," . $machineIDType . ",${remHost},${ua}";
}
else if('p.aapreqdoc'==$op || 'p.uapreqdoc2'==$op){
    $fileparams[]=mysql_file_or_error('doc', $conn,$method);
    if('p.aapreqdoc'==$op)
        $params=mysql_val_or_error('id',$conn, $method).','.
        mysql_val_or_error('rem',$conn, $method).',?';
    else
        $params=mysql_val_or_error('id',$conn, $method).',?';
}
else if('p.sbcsms'==$op || 'p.sbcemail'==$op){
    // send batch number by sms/email
    if(!have_internet())
        send_error('No internet connection',$op,WS_ERR_UNK);
    $serial=mt_rand();
    $batch=mysql_val_or_error('batch',$conn, $method);
    $batch0=php_noquote_NVL('batch');
    $to=php_noquote_NVL('to');
    $offs=0; // php appears to append results from successive calls. mark location of our resul.
    if(NULL==$to){
        $to=NULL;
        $proc_save=$proc;
        $proc= 'p.sbcsms'==$op?'pos_get_beneficiary_phone':'pos_get_beneficiary_email';
        $params=$batch;
        $result=fetch_data($proc, $params,$offs);
        $proc=$proc_save;
        if(count($result)>0){
           // log_to_file('contact details:'.PHP_EOL. print_r($result, TRUE));
            $result=$result[0];
            if(count($result)>0)
                $to=$result[0]['p.sbcsms'==$op?'telno':'email'];
        }
        if(NULL==$to)
            send_error("Found no ". ('p.sbcsms'==$op?'phone number':'email address'),
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
    $sp=$meta['sp'];

    log_to_file("${GLOBALS['ipaddr']} ${serial} ${op} to ${to}");
    $done=false;
    $msg='Failed to send';
    if('p.sbcemail'==$op){
        require_once('send-email.php');

        // fetch mail footer
        $x=0;
        $footer=fetch_email_footer($x, $batch0);
   //     log_to_file('Footer:'.PHP_EOL.print_r($footer, true));
        $output="Dear ${meta['surname']},<br/>Your prescripions code is: 
<strong>{$batch0}</strong>, generated by ${meta['pos']} (${meta['spname']}). Please present it to the service provider.";
        if(count($prescriptions)>0){
            $output.="<br/><br/>Prescription:
        <table><tr><th>No.</th><th>Ref</th><th>Product</th><th>Qty</th><th>Remark/instruction</th></tr>";
                $i=1;
                foreach($prescriptions as $p){
                    $output.= "<tr><td>${i}</td><td>${p['presid']}</td><td>${p['name']}</td><td>${p['qty']}</td><td>${p['remark']}</td></tr>";
                    $i=$i+1;
                }
                $output.="</table>";
        }
        $res=email_batchcode($output, $to, $meta['surname'], 'Prescriptions code', $footer);
        if($res){
            $msg='Unable to send email: '.$res->ErrorInfo;
            log_to_file("${GLOBALS['ipaddr']} ${serial} ${msg}");
            send_error($msg,$op,WS_ERR_UNK);
        }
        else
            $done=true;
    }else{
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
        if(count($exmsg)>0){
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


/*start daryle eval to send a details claim sms */

else if('p.claimsms'==$op){
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
        $output="Dear ".$surname.", a claim of " .$insurercost."GHC from ".$spname." on ".$transdate.
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



else if('p.qbbyfp'==$op){
    /* http --form https://api.pethersolutions.com/ghi/pos/  data@2000\:100-nfr.dat g=m op=qbbyfp */
    $fileparams[]=mysql_file_or_error('data', $conn,$method);
    /*{
        // log the fp data. /tmp is private to apache; dont use it.
        $fname='/home/mike/del/' . uniqid('_qbbyfp_').'.dat';
        log_to_file("${GLOBALS['ipaddr']} Saving fp ${in_fname} to ${fname}");
        if(!copy($in_fname,$fname))
            log_to_file("${GLOBALS['ipaddr']} Failed to copy ${in_fname}");
        }*/
    $params = "?,".mysqlvarval_NVL('i',$conn, $method).','.
        mysql_val_or_error('g', $conn, $method);
}
/* enrollment */
else if('p.sfoto'==$op){
    $fileparams[]=mysql_file_or_error('data', $conn,$method);
    $params=mysql_val_or_error('e',$conn, $method).',?';
}else if('p.sfpd' == $op || 'p.sfpi' == $op ){
    $finger = mysql_val_or_error('f', $conn, $method);
    $fileparams[]=mysql_file_or_error('data', $conn,$method);
    $params =  mysql_val_or_error('e', $conn, $method) . ','. $finger.',?';
}

else if('version'==$op){
    send_result(make_result(array('version'=>WS_VERS)));
}
else $more_op_checks=true;
}
if($more_op_checks && isset($shared_ops))
    include_once('./ops-shared-eval.inc');
if($more_op_checks && isset($generic_ops))
    require_once('./ops-generic-eval.inc');
if($more_op_checks)
    send_error("Operation not implemented", $op, WS_ERR_NOTIMPL);

//EOF
