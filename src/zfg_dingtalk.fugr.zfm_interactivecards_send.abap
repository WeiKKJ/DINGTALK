FUNCTION zfm_interactivecards_send.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(WA_ZILOGDATA) TYPE  ZFMDATA
*"----------------------------------------------------------------------
  DATA:carddata LIKE zcl_dingtalk=>lt_kv.
  DATA:rtype TYPE bapi_mtype,
       rtmsg TYPE bapi_msg,
       ret2  TYPE TABLE OF bapiret2.
  DATA:openconversationid TYPE string.
  CONSTANTS newline TYPE abap_char1 VALUE cl_abap_char_utilities=>newline.
  CONSTANTS vertical_tab TYPE abap_char1 VALUE '|'."cl_abap_char_utilities=>vertical_tab.
  DATA:my_logger TYPE REF TO zif_logger.
  DATA:BEGIN OF zabapkeystr,
         name  TYPE zabap_log-name,
         erdat TYPE zabap_log-erdat,
         stamp TYPE zabap_log-stamp,
       END OF zabapkeystr.
  DATA:wa_abapdata TYPE zabap_log.
  CHECK wa_zilogdata IS NOT INITIAL.
  my_logger = zcl_logger_factory=>create_log(
                        object    = 'ZDINGTALK'
                        subobject = 'ZDT_CARD'
                        desc      = 'ZFM_INTERACTIVECARDS_SEND'
                        settings = zcl_logger_factory=>create_settings( ) ) ##no_text.
  SELECT SINGLE * FROM ztddconfig WHERE name LIKE '%SAP推送通知%' INTO @DATA(wa_ddconfig).
  IF wa_ddconfig-cardtemplateid IS INITIAL OR wa_ddconfig-openconversationid IS INITIAL OR wa_ddconfig-callbackroutekey IS INITIAL.
    my_logger->e( obj_to_log = |未能从ztddconfig表查询到name包含'SAP推送通知'的配置| ) .
    RETURN.
  ENDIF.
  SELECT SINGLE * FROM tftit WHERE funcname = @wa_zilogdata-name AND spras = @sy-langu INTO @DATA(wa_tftit).
  MOVE-CORRESPONDING wa_zilogdata TO zabapkeystr.
  MOVE-CORRESPONDING wa_zilogdata TO wa_abapdata.

  DATA(outtrackid) = |{ wa_ddconfig-cardtemplateid }.{ wa_zilogdata-erdat+2(6) }{ wa_zilogdata-stamp }|.
  wa_abapdata-outtrackid = outtrackid.
  wa_abapdata-memo = 'DT'.
  CLEAR:wa_abapdata-clustr,wa_abapdata-clustd.
  EXPORT dingtalk = 'DT' TO DATABASE zabap_log(dt) ID zabapkeystr FROM wa_abapdata.
  CREATE OBJECT cl_dingtalk
    EXPORTING
      appid = wa_ddconfig-appid.
  CHECK cl_dingtalk IS BOUND.

  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING FIELD-SYMBOL(<carddata>).
  <carddata>-key = 'title'.
  <carddata>-value = 'SAP接口没有执行成功'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'lable'.
  <carddata>-value = |SAP@{ sy-mandt }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'markdown'.
  <carddata>-value = |#### SAP接口名:{ wa_zilogdata-name }{ newline }|
                  && |#### 接口描述:{ wa_tftit-stext }{ newline }|
*                  && |{ vertical_tab } 函数名 { vertical_tab } 记录创建日期 { vertical_tab } 时间戳 { vertical_tab }  消息文本 { vertical_tab }{ newline }|
*                  && |{ vertical_tab } :- { vertical_tab } :-: { vertical_tab } -: { vertical_tab } :- { vertical_tab }{ newline }|
*                  && |{ vertical_tab } { wa_zilogdata-name } { vertical_tab } { wa_zilogdata-erdat } { vertical_tab } { wa_zilogdata-stamp } { vertical_tab } { wa_zilogdata-rtmsg } { vertical_tab }{ newline }|
                  && |{ vertical_tab } 记录创建日期 { vertical_tab } 时间戳 { vertical_tab }  消息文本 { vertical_tab }{ newline }|
                  && |{ vertical_tab } :-: { vertical_tab } :-: { vertical_tab } :-: { vertical_tab }{ newline }|
                  && |{ vertical_tab } { wa_zilogdata-erdat } { vertical_tab } { wa_zilogdata-stamp } { vertical_tab } { wa_zilogdata-rtmsg } { vertical_tab }{ newline }|
                  && |> ###### 发送自客户端{ sy-mandt },由用户{ sy-uname }({ cl_abap_syst=>get_alias_user( ) })触发|.

  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'but01_text'.
  <carddata>-value = '尝试重新运行'.
  CASE cl_sql_demo_util=>check_prod_system( ).
    WHEN abap_true.
      INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
      <carddata>-key = 'hover'.
      <carddata>-value = 'SAP互动卡片'.
      INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
      <carddata>-key = 'but02_text'.
      <carddata>-value = '暂不开启该功能'.
      INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
      <carddata>-key = 'but_status'.
      <carddata>-value = '0'.
    WHEN OTHERS.
      INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
      <carddata>-key = 'hover'.
      <carddata>-value = 'SAP测试互动卡片'.
      INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
      <carddata>-key = 'but02_text'.
      <carddata>-value = '已重新执行完毕'.
      INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
      <carddata>-key = 'but_status'.
      <carddata>-value = '1'.
  ENDCASE.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'but03_text'.
  <carddata>-value = '取消执行'.

  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'callback_key'.
  <carddata>-value = |{ outtrackid }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'rtype'.
  <carddata>-value = ''.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'rtmsg'.
  <carddata>-value = '没有回调成功'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'pop_msg'.
  <carddata>-value = '响应超时'.


  CALL METHOD cl_dingtalk->robot_interactivecards_send
    EXPORTING
      cardtemplateid     = wa_ddconfig-cardtemplateid
      openconversationid = wa_ddconfig-openconversationid
      outtrackid         = outtrackid
      robotcode          = wa_ddconfig-appkey
*     conversationtype   = 1
      callbackroutekey   = wa_ddconfig-callbackroutekey
      carddata           = carddata
*     privatedata        =
*     useridtype         = 1
    IMPORTING
      rtype              = rtype
      rtmsg              = rtmsg.
  IF rtype = 'E'.
    my_logger->i( obj_to_log = rtmsg ) .
  ENDIF.
ENDFUNCTION.
