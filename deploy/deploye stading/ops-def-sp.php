<?php
/*
Webservices for service provider.
Tano Fotang <mtf@fotang.info>

Thu 24 Oct 2019 09:08:05 PM WAT
Fri Jan 24 12:48:28 WAT 2020
*/
$ops = [
    'sp.qaffils'=>['sp.get_affiliations',[WS_ID_FIRST, WS_OPT_NONE],[]],
    'sp.updclaim'=>['sp.modify_claim',[WS_ID_FIRST, WS_OPT_NONE, WS_METHOD_POST],
                [[null,null,null,null,TPAPP],
                ['claimid',ParamAttrib::MANDATORY],
                ['txdate',ParamAttrib::MANDATORY],
                ['product',ParamAttrib::OPTIONAL],
                ['prodcode',ParamAttrib::OPTIONAL],
                ['qty',ParamAttrib::MANDATORY],
                ['cost',ParamAttrib::MANDATORY],
                ['copay'],
                ['catid',ParamAttrib::MANDATORY],
                ['pkgid',ParamAttrib::MANDATORY],
                ['tgid'],
                ['icdcode',ParamAttrib::MANDATORY],
                ['rem']]],

    'sp.acldoc'  =>['SP.add_claims_doc',[WS_ID_FIRST, WS_OPT_NONE, WS_METHOD_POST],
                [[null,null,null,null,TPAPP],
                ['claimid',ParamAttrib::MANDATORY],
                ['type',null,null,null,null],
                ['data',ParamAttrib::FILE_MANDATORY],
                ['fname'],// unnecessary
                ['rem'],
                ['id',null,WS_OPT_OUTPARAM]]],
    'sp.ddoc'  =>['SP.del_claims_doc',[WS_ID_FIRST, WS_OPT_NONE, WS_METHOD_DELETE],
                [[null,null,null,null,TPAPP],
                ['id',ParamAttrib::MANDATORY]]]
];

include_once('./ops-shared-def.inc');
if(isset($shared_ops))
    $ops=array_merge($ops,$shared_ops);

include_once('../../enrolment/ops-def.inc');
if(isset($enrol_ops))
    $ops=array_merge($ops,$enrol_ops);

require_once('./ops-tp-generic.inc');
if(isset($tp_generic_ops))
    $ops=array_merge($ops,$tp_generic_ops);
//EOF
