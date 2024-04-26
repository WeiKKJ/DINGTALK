FUNCTION zfm_dd_robot.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(WEBHOOK) TYPE  STRING
*"     REFERENCE(KEY) TYPE  STRING
*"     REFERENCE(TEXT) TYPE  STRING
*"     REFERENCE(TITLE) TYPE  STRING
*"  EXPORTING
*"     REFERENCE(DDRESTR) TYPE  STRING
*"     REFERENCE(DDSTA) TYPE  I
*"     REFERENCE(DDREMSG) TYPE  STRING
*"     REFERENCE(DDSTRINPUT) TYPE  STRING
*"     REFERENCE(RTYPE) TYPE  BAPI_MTYPE
*"     REFERENCE(RTMSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  zfmdatasave1 'ZFM_DD_ROBOT'.
  zfmdatasave2 'B'.
  COMMIT WORK.
  TYPES: BEGIN OF t_MARKDOWN2,
           title TYPE string,
           text  TYPE string,
         END OF t_MARKDOWN2.
  TYPES: BEGIN OF t_JSON1,
           markdown TYPE t_MARKDOWN2,
           msgtype  TYPE string,
         END OF t_JSON1.
  DATA:ddurl      TYPE string,
       ddstr      TYPE string,
       sign       TYPE string,
       timestamp  TYPE string,
       gs_ddrobot TYPE t_JSON1.
*  PERFORM getsign USING 'SECa44dd33851c70345a351f9de91b364910607775c1e8711d0b0adb9187ac70d6c' CHANGING sign timestamp.
*  ddurl = 'https://oapi.dingtalk.com/robot/send?access_token=2b6a93292c1a9dce12d7b127be1a95a88bb2de83a1e6afd70c20f7745b5e6466' && '&timestamp=' && timestamp && '&sign=' && sign.
  PERFORM getsign USING key CHANGING sign timestamp.
  IF sign IS INITIAL.
    rtype = 'E'.
    rtmsg = '获取签名失败'.
    zfmdatasave2 'R'.
    EXIT.
  ENDIF.
  ddurl = webhook && '&timestamp=' && timestamp && '&sign=' && sign.
  CONDENSE ddurl NO-GAPS.
  CLEAR: gs_ddrobot,ddstr,ddrestr,ddremsg,ddsta.
  gs_ddrobot-msgtype = 'markdown'.
  gs_ddrobot-markdown-title = title.
  gs_ddrobot-markdown-text = text.

  ddstr = /ui2/cl_json=>serialize( data = gs_ddrobot  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
  ddstrinput = ddstr.
  CALL FUNCTION 'ZFMS_15_HTTP'
    EXPORTING
      input     = ddstr
      url       = ddurl
      reqmethod = 'POST' "HTTP 方法
      http1_1   = 'X' "协议1.1/1.0
    IMPORTING
      output    = ddrestr
      rtmsg     = ddremsg
      status    = ddsta "HTTP状态
    EXCEPTIONS
      OTHERS    = 1.

  zfmdatasave2 'R'.




ENDFUNCTION.
