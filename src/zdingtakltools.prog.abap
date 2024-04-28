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
TYPES: BEGIN OF ty_file,
         line(1024) TYPE x,
       END OF ty_file.
DATA: gt_file TYPE TABLE OF ty_file.

DATA: gv_file_name TYPE sdbah-actid,
      gv_file_type TYPE sdbad-funct,
      gv_file      TYPE xstring.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE btxt1.
  PARAMETERS:p1 RADIOBUTTON GROUP grd1 DEFAULT 'X' USER-COMMAND ss1,
             p2 RADIOBUTTON GROUP grd1,
             p3 RADIOBUTTON GROUP grd1,
             p4 RADIOBUTTON GROUP grd1,
             p5 RADIOBUTTON GROUP grd1.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE btxt2.
  PARAMETERS:p_appid  TYPE ztddconfig-appid MEMORY ID pappid,
             p_deptid TYPE ztddlistsub-dept_id DEFAULT 3038192 MEMORY ID pdeptid MODIF ID m1,
             p_all    AS CHECKBOX TYPE abap_bool DEFAULT abap_false MEMORY ID pall MODIF ID m5,
             p_userid TYPE ztdduser-userid MEMORY ID pmsgtyp MODIF ID m2,
             p_msgtyp TYPE ze_msgtype MEMORY ID pmsgtype MODIF ID m3,
             p_title  TYPE string MODIF ID m4,
             p_text   TYPE string MODIF ID m3,
             p_file   LIKE rlgrap-filename MEMORY ID pfile MODIF ID m6,
             p_medid  TYPE string MEMORY ID pmedid MODIF ID m7 LOWER CASE.

SELECTION-SCREEN END OF BLOCK b2.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM frm_f4_file.

AT SELECTION-SCREEN OUTPUT.
  btxt1 = '功能选择'(t01).
  btxt2 = '数据筛选'(t02).

  LOOP AT SCREEN.
    IF p1 = 'X'.
      IF screen-group1 = 'M2' OR screen-group1 = 'M3' OR screen-group1 = 'M4' OR screen-group1 = 'M6' OR screen-group1 = 'M7'.
        screen-active = 0.
      ENDIF.
    ELSEIF p2 = 'X'.
      IF screen-group1 = 'M2' OR screen-group1 = 'M3' OR screen-group1 = 'M4' OR screen-group1 = 'M6' OR screen-group1 = 'M7'.
        screen-active = 0.
      ENDIF.
    ELSEIF p3 = 'X'.
      IF screen-group1 = 'M1' OR screen-group1 = 'M5' OR screen-group1 = 'M6'.
        screen-active = 0.
      ENDIF.
    ELSEIF p4 = 'X'.
      IF screen-group1 = 'M1' OR screen-group1 = 'M2' OR screen-group1 = 'M5' OR screen-group1 = 'M6' OR screen-group1 = 'M7'.
        screen-active = 0.
      ENDIF.
    ELSEIF p5 = 'X'.
      IF screen-group1 = 'M1' OR screen-group1 = 'M2' OR screen-group1 = 'M3' OR screen-group1 = 'M4' OR screen-group1 = 'M5'  OR screen-group1 = 'M7'.
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
    MESSAGE e000(oo) WITH '应用唯一标识不能为空'.
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
    PERFORM read_upload_file.
    PERFORM upload_media.
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
      userid   = p_userid
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
  DATA: lv_file_path   TYPE string,
        lv_file_length TYPE i,
        lv_file_name   TYPE dbmsgora-filename.

  lv_file_path = p_file.
  lv_file_name = p_file.

  CALL FUNCTION 'SPLIT_FILENAME'
    EXPORTING
      long_filename  = lv_file_name "上传文件路径
    IMPORTING
      pure_filename  = gv_file_name "文件名称
      pure_extension = gv_file_type. "文件后缀

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = lv_file_path
      filetype                = 'BIN'
    IMPORTING
      filelength              = lv_file_length
    TABLES
      data_tab                = gt_file
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
  IF sy-subrc <> 0.
    MESSAGE s000(oo) WITH '上传文件失败' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  "转xstring
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_file_length
    IMPORTING
      buffer       = gv_file
    TABLES
      binary_tab   = gt_file
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
    MESSAGE s000(oo) WITH '转xstring失败' DISPLAY LIKE 'E'.
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
FORM upload_media .
  DATA:type     TYPE  ze_media_type,
       media    TYPE  xstring,
       media_id TYPE  string.
  DATA:BEGIN OF header OCCURS 0,
         name  TYPE string,
         value TYPE string,
       END OF header.
  DATA:lv_content_disposition TYPE string.
  DATA: lv_file_name   TYPE savwctxt-fieldcont,
        lv_name_encode TYPE savwctxt-fieldcont.
  CHECK cl_dingtalk IS BOUND.
  CLEAR:header,header[].
  header-name = 'Content-Disposition'.
  "utf-8编码文件名（目的是让上传后的文件名跟原来一样，不然会乱码）
  lv_file_name = gv_file_name.
  CALL FUNCTION 'WWW_URLENCODE'
    EXPORTING
      value         = lv_file_name
    IMPORTING
      value_encoded = lv_name_encode.
  lv_content_disposition = 'form-data; name="media"; filename="' && lv_file_name && '.' && gv_file_type && '"'.
  header-value = lv_content_disposition.
  APPEND header.
  CALL METHOD cl_dingtalk->upload_media
    EXPORTING
      type     = 'file'
      media    = gv_file
      header   = header[]
    IMPORTING
      media_id = media_id
      rtype    = rtype
      rtmsg    = rtmsg.
  PERFORM inmsg(zpubform) TABLES ret2 USING '' rtype '' rtmsg(50) rtmsg+50(50) rtmsg+100(50) rtmsg+150(50).
  PERFORM showmsg(zpubform) TABLES ret2.
ENDFORM.
