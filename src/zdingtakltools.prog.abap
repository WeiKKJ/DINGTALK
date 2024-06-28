*&---------------------------------------------------------------------*
*& Report ZDINGTAKLTOOLS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdingtakltools.

DATA:cl_dingtalk TYPE REF TO zcl_dingtalk,
     cl_deepalv  TYPE REF TO zcl_deepalv.
DATA:rtype TYPE bapi_mtype,
     rtmsg TYPE bapi_msg,
     ret2  TYPE TABLE OF bapiret2.
DATA:file_xstr TYPE xstring.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE btxt1.
  PARAMETERS:p1 RADIOBUTTON GROUP grd1 DEFAULT 'X' USER-COMMAND ss1,
             p2 RADIOBUTTON GROUP grd1,
             p3 RADIOBUTTON GROUP grd1,
             p4 RADIOBUTTON GROUP grd1,
             p5 RADIOBUTTON GROUP grd1,
             p6 RADIOBUTTON GROUP grd1,
             p7 RADIOBUTTON GROUP grd1.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE btxt2.
  PARAMETERS:p_appid  TYPE ztddconfig-appid MEMORY ID pappid,
             p_deptid TYPE ztddlistsub-dept_id DEFAULT 3038192 MEMORY ID pdeptid MODIF ID m1,
             p_all    AS CHECKBOX TYPE abap_bool DEFAULT abap_false MEMORY ID pall MODIF ID m5,
             p_userid TYPE ztdduser-userid MEMORY ID pmsgtyp MODIF ID m2,
             p_msgtyp TYPE ze_msgtype MEMORY ID pmsgtype MODIF ID m3,
             p_title  TYPE string LOWER CASE MODIF ID m4,
             p_text   TYPE string LOWER CASE MODIF ID m3,
             p_file   LIKE ibipparms-path MEMORY ID pfile MODIF ID m6,
             p_medid  TYPE ze_media_id MEMORY ID pmedid MODIF ID m7 LOWER CASE.

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE btxt3.
  PARAMETERS:p71 RADIOBUTTON GROUP prd3 USER-COMMAND ss3 DEFAULT 'X' MODIF ID p7,
             p72 RADIOBUTTON GROUP prd3 MODIF ID p7.
SELECTION-SCREEN END OF BLOCK b3.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM frm_f4_file.

AT SELECTION-SCREEN OUTPUT.
  btxt1 = '功能选择'(t01).
  btxt2 = '数据筛选'(t02).
  btxt3 = '机器人相关'(t03).

  LOOP AT SCREEN.
    IF p1 = 'X'.
      IF ( screen-group1(1) = 'M' AND NOT ( screen-group1 = 'M1' OR screen-group1 = 'M5' ) ) OR screen-group1(1) = 'P'.
        screen-active = 0.
      ENDIF.
    ELSEIF p2 = 'X'.
      IF ( screen-group1(1) = 'M' AND NOT ( screen-group1 = 'M1' OR screen-group1 = 'M5' ) ) OR screen-group1(1) = 'P'.
        screen-active = 0.
      ENDIF.
    ELSEIF p3 = 'X'.
      IF screen-group1 = 'M1' OR screen-group1 = 'M5' OR screen-group1 = 'M6' OR screen-group1(1) = 'P'.
        screen-active = 0.
      ENDIF.
    ELSEIF p4 = 'X'.
      IF ( screen-group1(1) = 'M' AND NOT ( screen-group1 = 'M3' OR screen-group1 = 'M4' ) ) OR screen-group1(1) = 'P'.
        screen-active = 0.
      ENDIF.
    ELSEIF p5 = 'X'.
      IF ( screen-group1(1) = 'M' AND NOT ( screen-group1 = 'M6' ) ) OR screen-group1(1) = 'P'.
        screen-active = 0.
      ENDIF.
    ELSEIF p6 = 'X'.
      IF ( screen-group1(1) = 'M' AND NOT ( screen-group1 = 'M2' ) ) OR screen-group1(1) = 'P'.
        screen-active = 0.
      ENDIF.
    ELSEIF p7 = 'X'.
      IF screen-group1(1) = 'M'.
        screen-active = 0.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN. "PAI
  CASE sy-ucomm.
    WHEN 'ONLI'.
      PERFORM auth_check.
  ENDCASE.

INITIALIZATION.

START-OF-SELECTION.
  PERFORM savelog(zreplog) USING sy-repid '' IF FOUND.
  PERFORM getdata.
  PERFORM updatelog(zreplog) IF FOUND.

*&---------------------------------------------------------------------*
*&      Form  auth_check
*&---------------------------------------------------------------------*
FORM auth_check.

ENDFORM.

*&---------------------------------------------------------------------*
*& getdata
*&---------------------------------------------------------------------*
FORM getdata.
  CLEAR:cl_dingtalk.
  IF p_appid IS INITIAL.
    MESSAGE s000(oo) WITH '应用唯一标识不能为空' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  CREATE OBJECT cl_dingtalk
    EXPORTING
      appid = p_appid.
  IF p1 = 'X'.
    PERFORM init_dept.
  ELSEIF p2 = 'X'.
    PERFORM init_user.
  ELSEIF p3 = 'X'.
    PERFORM post2corpconversation.
  ELSEIF p4 ='X'.
    PERFORM post2ddrobot.
  ELSEIF p5 = 'X'.
    CLEAR:p_medid,rtype,rtmsg.
    PERFORM read_upload_file.
    PERFORM upload_media_viafastapi USING p_file file_xstr CHANGING p_medid rtype rtmsg.
    PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg(50) rtmsg+50(50) rtmsg+100(50) rtmsg+150(50).
    PERFORM showmsg(zpubform) TABLES ret2.
  ELSEIF p6 = 'X'.
    PERFORM post2corpc_excel.
  ELSEIF p7 = 'X'.
    IF p71 = 'X'.
      PERFORM robot_groupmessages_send.
    ELSEIF p72 = 'X'.
      PERFORM robot_interactivecards_send.
    ENDIF.
  ELSE.
    EXIT.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form frm_f4_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_f4_file .
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      file_name = p_file.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_dept
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_dept .
  CLEAR:rtype,rtmsg,ret2.
  CHECK cl_dingtalk IS BOUND.
  CALL METHOD cl_dingtalk->init_dept
    EXPORTING
      dept_id  = p_deptid
*     language = 'zh_CN'
      init_all = p_all
    IMPORTING
      rtype    = rtype
      rtmsg    = rtmsg
*     gt_ztddlistsub_total =
    .
*  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
  PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg '' '' ''.

  IF rtype = 'S'.
    CLEAR:cl_deepalv.
    SELECT * FROM ztddlistsub ORDER BY PRIMARY KEY INTO TABLE @DATA(lt_dept).
    CREATE OBJECT cl_deepalv.
    PERFORM showdetail TABLES lt_dept.
  ENDIF.

  PERFORM showmsg(zpubform) TABLES ret2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form init_user
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_user .
  CLEAR:rtype,rtmsg,ret2.
  CHECK cl_dingtalk IS BOUND.
  CALL METHOD cl_dingtalk->init_user
    EXPORTING
      dept_id  = p_deptid
      init_all = p_all
    IMPORTING
      rtype    = rtype
      rtmsg    = rtmsg.
*  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
  PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg '' '' ''.
  IF rtype = 'S'.
    CLEAR:cl_deepalv.
    SELECT * FROM ztdduser ORDER BY PRIMARY KEY INTO TABLE @DATA(lt_user).
    CREATE OBJECT cl_deepalv.
    PERFORM showdetail TABLES lt_user.
  ENDIF.
  PERFORM showmsg(zpubform) TABLES ret2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form showdetail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_USER
*&---------------------------------------------------------------------*
FORM showdetail  TABLES   p_tab.
  CHECK cl_deepalv IS BOUND.
  CALL METHOD cl_deepalv->display_deep_structure_compdes
    EXPORTING
      i_deepstrc              = p_tab[]
      i_callback_user_command = 'FRM_USER_COMMAND'
*     i_callback_pf_status_set = 'FRM_STATUS_SET'
*     i_custom_fcat           =
*     i_custom_layo           =
    EXCEPTIONS
      type_error              = 1
      OTHERS                  = 2.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_USER_COMMAND
*&---------------------------------------------------------------------*
*& 用户按钮事件响应
*&---------------------------------------------------------------------*
*&      --> R_UCOMM      事件码
*&      --> RS_SELFIELD  操作数据字段信息
*&---------------------------------------------------------------------*
FORM frm_user_command USING r_ucomm LIKE sy-ucomm
      rs_selfield TYPE slis_selfield.
  CASE r_ucomm.
    WHEN '&IC1'.
      cl_deepalv->hotspot_click_compdescr( i_selfield = rs_selfield ).
    WHEN '&F03'.
      cl_deepalv->back_click( ).
    WHEN OTHERS.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form post2corpconversation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM post2corpconversation .
  CLEAR:rtype,rtmsg,ret2.
  CHECK cl_dingtalk IS BOUND.
  CALL METHOD cl_dingtalk->post2corpconversation
    EXPORTING
      msgtype  = p_msgtyp
      userid   = CONV string( p_userid )
      title    = p_title
      text     = p_text
      media_id = p_medid
    IMPORTING
      rtype    = rtype
      rtmsg    = rtmsg.
*  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
  PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg(50) rtmsg+50(50) rtmsg+100(50) rtmsg+150(50).
  PERFORM showmsg(zpubform) TABLES ret2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form post2ddrobot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM post2ddrobot .
  CLEAR:rtype,rtmsg,ret2.
  CHECK cl_dingtalk IS BOUND.
  CALL METHOD cl_dingtalk->post2ddrobot
    EXPORTING
      msgtype = p_msgtyp
      title   = p_title
      text    = p_text
    IMPORTING
      rtype   = rtype
      rtmsg   = rtmsg.
*  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
  PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg(50) rtmsg+50(50) rtmsg+100(50) rtmsg+150(50).
  PERFORM showmsg(zpubform) TABLES ret2.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form read_upload_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_upload_file .
  TYPES: BEGIN OF ty_file,
           line(1024) TYPE x,
         END OF ty_file.
  DATA: file_path   TYPE string,
        file_length TYPE i,
        gt_file     TYPE TABLE OF ty_file,
        result      TYPE abap_bool,
        info_obj    TYPE obj_record.
  CONSTANTS:maxlength TYPE i VALUE 20971520.
  CLEAR:file_xstr.
  file_path = p_file.
  " 判断文件是否存在  29.04.2024 09:46:13 by kkw
  CALL METHOD cl_gui_frontend_services=>file_exist
    EXPORTING
      file                 = file_path
    RECEIVING
      result               = result
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      wrong_parameter      = 3
      not_supported_by_gui = 4
      OTHERS               = 5.
  IF sy-subrc NE 0 OR result = abap_false.
    MESSAGE s000(oo) WITH '所选文件路径有误' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  " 计算文件大小  29.04.2024 09:46:29 by kkw
  CREATE OBJECT info_obj 'SAPINFO' NO FLUSH.
  CALL METHOD OF info_obj 'GetFileSize' = file_length
    EXPORTING #1 = file_path.
  IF file_length GT maxlength.
    rtmsg = |钉钉要求媒体文件最大不能超过{ maxlength / 1048576 }MB，当前大小为{ file_length / 1048576 }MB|.
    MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  " 文件上传  29.04.2024 09:52:56 by kkw
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = file_path
      filetype                = 'BIN'
*     HAS_FIELD_SEPARATOR     = ' '
*     HEADER_LENGTH           = 0
*     READ_BY_LINE            = 'X'
*     DAT_MODE                = ' '
      codepage                = '8400'
*     IGNORE_CERR             = ABAP_TRUE
*     REPLACEMENT             = '#'
*     CHECK_BOM               = ' '
*     VIRUS_SCAN_PROFILE      =
*     NO_AUTH_CHECK           = ' '
    IMPORTING
      filelength              = file_length
*     HEADER                  =
    TABLES
      data_tab                = gt_file
*   CHANGING
*     ISSCANPERFORMED         = ' '
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.

*  cl_gui_frontend_services=>gui_upload( EXPORTING
*                                          filename                = file_path
*                                          filetype                = 'BIN'         " We are basically working with zipped directories --> force binary read
**                                            codepage                = codepage
*                                        IMPORTING
*                                          filelength              = file_length
*                                        CHANGING
*                                          data_tab                = gt_file
*                                        EXCEPTIONS
*                                          file_open_error         = 1
*                                          file_read_error         = 2
*                                          no_batch                = 3
*                                          gui_refuse_filetransfer = 4
*                                          invalid_type            = 5
*                                          no_authority            = 6
*                                          unknown_error           = 7
*                                          bad_data_format         = 8
*                                          header_not_allowed      = 9
*                                          separator_not_allowed   = 10
*                                          header_too_long         = 11
*                                          unknown_dp_error        = 12
*                                          access_denied           = 13
*                                          dp_out_of_memory        = 14
*                                          disk_full               = 15
*                                          dp_timeout              = 16
*                                          not_supported_by_gui    = 17
*                                          error_no_gui            = 18
*                                          OTHERS                  = 19 ).

  IF sy-subrc <> 0.
    MESSAGE s000(oo) WITH '上传文件失败' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  " BINARY_TO_XSTRING  29.04.2024 09:49:14 by kkw
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = file_length
    IMPORTING
      buffer       = file_xstr
    TABLES
      binary_tab   = gt_file
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
    MESSAGE s000(oo) WITH '文件BINARY转XSTRING失败' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form UPLOAD_MEDIA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM upload_media USING p_filename p_xstr CHANGING p_media_id p_rtype p_rtmsg.
  DATA:type     TYPE  ze_media_type,
       media    TYPE  xstring,
       media_id TYPE  string.
  DATA:BEGIN OF header OCCURS 0,
         name  TYPE string,
         value TYPE string,
         cdata TYPE string,
         xdata TYPE xstring,
       END OF header.
  DATA:lv_content_disposition TYPE string.
  DATA:pure_filename    TYPE char255,
       pure_extension   TYPE char10,
       file_name_encode TYPE savwctxt-fieldcont.
  CHECK cl_dingtalk IS BOUND.
  CLEAR:p_media_id,p_rtype,p_rtmsg.
  " 分割文件名和扩展名  29.04.2024 09:47:45 by kkw
  CALL METHOD zcl_dingtalk=>split_filename
    EXPORTING
      long_filename  = CONV char255( p_filename )
    IMPORTING
      pure_filename  = pure_filename
      pure_extension = pure_extension.
  IF pure_extension IS INITIAL.
    p_rtmsg = |文件扩展名有误|.
    p_rtype = 'E'.
    RETURN.
  ENDIF.
  " 中文乱码  29.04.2024 10:06:44 by kkw
  CALL FUNCTION 'WWW_URLENCODE'
    EXPORTING
      value         = CONV savwctxt-fieldcont( pure_filename )
    IMPORTING
      value_encoded = file_name_encode.
  CLEAR:header,header[].
  header-name = 'Content-Disposition'.
  lv_content_disposition = |form-data; name="media"; filename="{ pure_filename }.{ pure_extension }"|.
  header-value = lv_content_disposition.
  header-xdata = p_xstr.
  APPEND header.
  CALL METHOD cl_dingtalk->upload_media
    EXPORTING
      via      = 'INS'
      type     = 'file'
      header   = header[]
    IMPORTING
      media_id = p_media_id
      rtype    = p_rtype
      rtmsg    = p_rtmsg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form post2corpc_excel
*&---------------------------------------------------------------------*
*& 测试调用abap2xlsx生成excel发送工作通知消息
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM post2corpc_excel .
  IF p_userid IS INITIAL.
    MESSAGE s000(oo) WITH '员工ID(钉钉的userid)必填' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  DATA:media_id TYPE string.
  DATA:exceltab LIKE zcl_dingtalk=>exceltab.
  SELECT * FROM sflight INTO TABLE @DATA(lt_sflight).
  INSERT INITIAL LINE INTO TABLE exceltab ASSIGNING FIELD-SYMBOL(<exceltab>).
  <exceltab>-excel_sheetname = 'lt_sflight'.
  CREATE DATA <exceltab>-excel_tabdref LIKE lt_sflight.
  ASSIGN <exceltab>-excel_tabdref->* TO FIELD-SYMBOL(<dref>).
  <dref> = lt_sflight.
  <exceltab>-excel_fieldcat = zcl_excel_common=>get_fieldcatalog( ip_table = lt_sflight ).

  SELECT * FROM scarr INTO TABLE @DATA(lt_scarr).
  UNASSIGN:<exceltab>,<dref>.
  INSERT INITIAL LINE INTO TABLE exceltab ASSIGNING <exceltab>.
  <exceltab>-excel_sheetname = 'lt_scarr'.
  CREATE DATA <exceltab>-excel_tabdref LIKE lt_scarr.
  ASSIGN <exceltab>-excel_tabdref->* TO <dref>.
  <dref> = lt_scarr.
  <exceltab>-excel_fieldcat = zcl_excel_common=>get_fieldcatalog( ip_table = lt_scarr ).
  CALL METHOD cl_dingtalk->create_excel
    EXPORTING
      gt_exceltab  = exceltab
    RECEIVING
      xstring_data = file_xstr.
*  DATA(filename) = |ZDINGTAKLTOOLS_{ sy-datum }_{ sy-uzeit }.xlsx|.
  DATA(filename) = |钉钉推送文件测试_{ sy-datum+2(6) }_{ sy-uzeit }.xlsx|.
  CLEAR:media_id,rtype,rtmsg.
*  PERFORM upload_media USING filename file_xstr CHANGING media_id rtype rtmsg.
  PERFORM upload_media_viafastapi USING filename file_xstr CHANGING media_id rtype rtmsg.
  PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg(50) rtmsg+50(50) rtmsg+100(50) rtmsg+150(50).
  IF media_id IS NOT INITIAL.
    CLEAR:rtype,rtmsg.
    CALL METHOD cl_dingtalk->post2corpconversation
      EXPORTING
        msgtype  = 'file'
        userid   = CONV string( p_userid )
*       title    = p_title
*       text     = p_text
        media_id = media_id
      IMPORTING
        rtype    = rtype
        rtmsg    = rtmsg.
*  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
    PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg(50) rtmsg+50(50) rtmsg+100(50) rtmsg+150(50).
  ENDIF.
  PERFORM showmsg(zpubform) TABLES ret2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form upload_media_viafastapi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> FILENAME
*&      --> FILE_XSTR
*&      <-- MEDIA_ID
*&      <-- RTYPE
*&      <-- RTMSG
*&---------------------------------------------------------------------*
FORM upload_media_viafastapi USING p_filename p_xstr CHANGING p_media_id p_rtype p_rtmsg.
  DATA:type     TYPE  ze_media_type,
       media    TYPE  xstring,
       media_id TYPE  string.
  DATA:BEGIN OF header OCCURS 0,
         name  TYPE string,
         value TYPE string,
         cdata TYPE string,
         xdata TYPE xstring,
       END OF header.
  DATA:lv_content_disposition TYPE string.
  DATA:pure_filename    TYPE char255,
       pure_extension   TYPE char10,
       file_name_encode TYPE savwctxt-fieldcont.
  CHECK cl_dingtalk IS BOUND.
  CLEAR:p_media_id,p_rtype,p_rtmsg.
  " 分割文件名和扩展名  29.04.2024 09:47:45 by kkw
  CALL METHOD zcl_dingtalk=>split_filename
    EXPORTING
      long_filename  = CONV char255( p_filename )
    IMPORTING
      pure_filename  = pure_filename
      pure_extension = pure_extension.
  IF pure_extension IS INITIAL.
    p_rtmsg = |文件扩展名有误|.
    p_rtype = 'E'.
    RETURN.
  ENDIF.
  " 中文乱码  29.04.2024 10:06:44 by kkw
  CALL FUNCTION 'WWW_URLENCODE'
    EXPORTING
      value         = CONV savwctxt-fieldcont( pure_filename )
    IMPORTING
      value_encoded = file_name_encode.
  CLEAR:header,header[].
  header-name = 'Content-Disposition'.
*  lv_content_disposition = |form-data; name="file"; filename="{ pure_filename }.{ pure_extension }"|.
  lv_content_disposition = |form-data; name="media"; filename="{ file_name_encode }.{ pure_extension }"|.
  header-value = lv_content_disposition.
  header-xdata = p_xstr.
  APPEND header.

  CLEAR:header.
  header-name = 'Content-Disposition'.
  lv_content_disposition = |form-data; name="type"|.
  header-value = lv_content_disposition.
  header-cdata = 'file'.
  APPEND header.
  CALL METHOD cl_dingtalk->upload_media
    EXPORTING
      type     = 'file'
      via      = 'FASTAPI'
      header   = header[]
    IMPORTING
      media_id = p_media_id
      rtype    = p_rtype
      rtmsg    = p_rtmsg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form robot_groupmessages_send
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM robot_groupmessages_send .
  CLEAR:rtype,rtmsg,ret2.
  CHECK cl_dingtalk IS BOUND.
*  DATA(str) = `{"content":"钉钉，让进步发生"}`.
  DATA(str) = '{"title": "xxxx","text": "'
  && `#### 呆滞物料提醒，-测试消息1-4 \n 物料 | 自编号 | 数量 | 呆滞天数 \n ---- | --- | ---- | ---- \n E0201205193`
  && ` | WBSL221111-09 | 0.290 | 185 \n E0201205192 | WBSL211114-18 | 0.524 | 185 \n E0201205173 | WBSL221029-50 | 0.480 | 185 `
  && `\n E0201205173 | WBSL221029-53 | 4.300 | 185 \n > ###### 16:39:20 发送自客户端252"}`.

  CALL METHOD cl_dingtalk->robot_groupmessages_send
    EXPORTING
      msgparam           = str
*     msgkey             = `sampleText`
      msgkey             = `sampleMarkdown`
      openconversationid = `cidXYPRNjWm2X5bxoE65dGyig==`
      robotcode          = `dinge9jdnvholvqayvgc`
    IMPORTING
      rtype              = rtype
      rtmsg              = rtmsg.
  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ROBOT_INTERACTIVECARDS_SEND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM robot_interactivecards_send .
  DATA:carddata LIKE zcl_dingtalk=>lt_kv.
  CLEAR:rtype,rtmsg,ret2.
  CHECK cl_dingtalk IS BOUND.
  DATA(cardtemplateid) = '6f2cb6bb-f489-495a-a875-7158e6d63fb5.schema'.
  DATA(outtrackid) = |{ cardtemplateid }.{ sy-datum+2(6) }{ sy-uzeit }|.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING FIELD-SYMBOL(<carddata>).
  <carddata>-key = 'title'.
  <carddata>-value = 'SAP推送的测试卡片消息'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'lable'.
  <carddata>-value = 'SAP@KKW'.
  INSERT INITIAL LINE INTO TABLE carddata ASSIGNING <carddata>.
  <carddata>-key = 'markdown'.
  <carddata>-value = |#### 这是SAP发出的提醒,{ outtrackid }|.
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
  <carddata>-value = '已取消执行'.
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
  MESSAGE s000(oo) WITH rtmsg DISPLAY LIKE rtype.
ENDFORM.
