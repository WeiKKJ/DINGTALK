FUNCTION zfm_corpconversation_send.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(PROGNAME) TYPE  PROGNAME
*"     VALUE(UCOMM) TYPE  SYST_UCOMM
*"     VALUE(TEXT) TYPE  STRING
*"  EXPORTING
*"     VALUE(RTYPE) TYPE  BAPI_MTYPE
*"     VALUE(RTMSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  zfmdatasave1 ''.
  zfmdatasave2 'B'.
  DATA:userid_list TYPE string.
  SELECT SINGLE
    *
    FROM ztdd_prog_ucomm
    WHERE progname = @progname
    AND ucomm = @ucomm
    INTO @DATA(wa_prog_uc).
  IF sy-subrc NE 0.
    rtmsg = |尚未配置[ztdd_prog_ucomm]表当前程序[{ progname }],用户命令[{ ucomm }]对应的钉钉应用唯一标识|.
    zfmdatasave2 'B'.
    RETURN.
  ENDIF.
  SELECT SINGLE
    *
    FROM ztddconfig
    WHERE appid = @wa_prog_uc-appid
    INTO @DATA(wa_ztddconf).
  IF sy-subrc NE 0.
    rtmsg = |尚未配置[ztddconfig]表钉钉应用唯一标识[{ wa_prog_uc-appid }]|.
    zfmdatasave2 'B'.
    RETURN.
  ENDIF.
  SELECT
    *
    FROM ztdd_prog_user
    WHERE progname = @progname
    AND ucomm = @ucomm
    AND userid IS NOT INITIAL
    INTO TABLE @DATA(lt_prog_us).
  IF lt_prog_us IS INITIAL.
    rtmsg = |尚未配置[ztdd_prog_user]表当前程序[{ progname }],用户命令[{ ucomm }]将要推送消息的用户|.
    zfmdatasave2 'B'.
    RETURN.
  ENDIF.
  " 填充将要推送消息的用户列表  06.05.2024 17:36:00 by kkw
  CLEAR:userid_list.
  LOOP AT lt_prog_us ASSIGNING FIELD-SYMBOL(<lt_prog_us>).
    userid_list = |{ userid_list },{ <lt_prog_us>-userid }|.
  ENDLOOP.
  CONDENSE userid_list NO-GAPS.
  SHIFT userid_list LEFT DELETING LEADING ','.
  cl_dingtalk = NEW #( wa_ztddconf-appid ).
  CHECK cl_dingtalk IS BOUND.
  CALL METHOD cl_dingtalk->post2corpconversation
    EXPORTING
      msgtype = 'text'
      userid  = userid_list
*     title   = p_title
      text    = text
*     media_id = media_id
    IMPORTING
      rtype   = rtype
      rtmsg   = rtmsg.
  zfmdatasave2 'R'.
ENDFUNCTION.
