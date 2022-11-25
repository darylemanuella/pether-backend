<!-- creer mon option -->


<?php

'qubatchmsgs'=>['ghi_central.get_user_batch_comments_toplevel',[WS_ID_FIRST, WS_OPT_NONE],
[['id', ParamAttrib::MANDATORY]]],


'getbensub'=>['ghi_central.GetBeneficiairiesSub',[ WS_OPT_NONE],
[['subscriberId', ParamAttrib::MANDATORY]]],
'getbensub'=>['ghi_central.GetBeneficiairiesSub',
[['subscriberId']]],




// cceci part dans le fichier ops-def.inc : that is structure of my option for call my procedure
'getbensub' =>['GetBeneficiairiesSub',[WS_OPT_NONE],
                [['subscriberId ',ParamAttrib::MANDATORY]]],

                // else if($op == 'getbensub'){
                //     $id = mysql_val_or_error('subscriberId', $conn, $method, $method);
                //     $params = ($subscriberId.",1";
            
                // remplace to the file ops-eval.inc  :use the operation defined
                else if( 'dquest'==$op ){
                    $params= mysql_val_or_error('id', $conn, $method);
                
}

// ici c'est pour vim ops-generic.inc

'getbensub'=>array('GetBeneficiairiesSub', array(WS_ID_NONE, WS_OPT_NONE)),

// ops-generic-eval.inc

else if($op == 'GetBeneficiairiesSub'){
    $params = mysql_val_or_error('subscriberId', $conn, $method);
}


'getbensub'=>['ghi_central.GetBeneficiairiesSub',[WS_ID_FIRST, WS_OPT_NONE],
            [['id', ParamAttrib::MANDATORY]]],



?>