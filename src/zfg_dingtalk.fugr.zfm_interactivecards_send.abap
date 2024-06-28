FUNCTION zfm_interactivecards_send.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(WA_ZILOGDATA) TYPE  ZFMDATA
*"----------------------------------------------------------------------
  DATA:cl_dingtalk TYPE REF TO zcl_dingtalk.
  DATA:carddata LIKE zcl_dingtalk=>lt_kv.
  DATA:rtype TYPE bapi_mtype,
       rtmsg TYPE bapi_msg,
       ret2  TYPE TABLE OF bapiret2.
  CONSTANTS newline TYPE abap_char1 VALUE cl_abap_char_utilities=>newline.
  CONSTANTS vertical_tab TYPE abap_char1 VALUE '|'."cl_abap_char_utilities=>vertical_tab.
  CREATE OBJECT cl_dingtalk
    EXPORTING
      appid = '2dce6c4b-8695-4a79-8c38-eb5be6633cfe'.
  CHECK cl_dingtalk IS BOUND.
  DATA(cardtemplateid) = '6f2cb6bb-f489-495a-a875-7158e6d63fb5.schema'.
  DATA(outtrackid) = |{ cardtemplateid }.{ sy-datum+2(6) }{ sy-uzeit }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING FIELD-SYMBOL(<carddata>).
  <carddata>-key = 'title'.
  <carddata>-value = 'SAP接口没有执行成功'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'lable'.
  <carddata>-value = |SAP@{ sy-mandt }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'markdown'.
  <carddata>-value = |#### SAP接口名:{ wa_zilogdata-name }{ newline }|
                  && |{ vertical_tab } 函数名 { vertical_tab } 记录创建日期 { vertical_tab } 时间戳 { vertical_tab }  消息文本 { vertical_tab }{ newline }|
                  && |{ vertical_tab } :- { vertical_tab } :-: { vertical_tab } -: { vertical_tab } :- { vertical_tab }{ newline }|
                  && |{ vertical_tab } { wa_zilogdata-name } { vertical_tab } { wa_zilogdata-erdat } { vertical_tab } { wa_zilogdata-stamp } { vertical_tab } { wa_zilogdata-rtmsg } { vertical_tab }{ newline }|
                  && |> ###### 发送自客户端{ sy-mandt }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'hover'.
  <carddata>-value = 'SAP测试互动卡片'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'but01_text'.
  <carddata>-value = '尝试重新运行'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'but02_text'.
  <carddata>-value = '已重新执行完毕'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'but03_text'.
  <carddata>-value = '取消执行'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'but_status'.
  <carddata>-value = '1'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'callback_key'.
  <carddata>-value = |{ outtrackid }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'rtype'.
  <carddata>-value = ''.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'rtmsg'.
  <carddata>-value = '没有回调成功'.
  CALL METHOD cl_dingtalk->robot_interactivecards_send
    EXPORTING
      cardtemplateid     = CONV string( cardtemplateid )
      openconversationid = 'cidXYPRNjWm2X5bxoE65dGyig=='
*     openconversationid = 'cidrCDssQmXrr/jiO4N5bH19Q=='
      outtrackid         = outtrackid
      robotcode          = 'dinge9jdnvholvqayvgc'
*     conversationtype   = 1
      callbackroutekey   = 'OA4FgkdsWiz9wgjNbrsQLtga3sgqFXtl'
      carddata           = carddata
*     privatedata        =
*     useridtype         = 1
    IMPORTING
      rtype              = rtype
      rtmsg              = rtmsg.

ENDFUNCTION.
