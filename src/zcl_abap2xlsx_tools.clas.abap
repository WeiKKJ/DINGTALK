class ZCL_ABAP2XLSX_TOOLS definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF ty_excel,
        excel_tabdref   TYPE REF TO data,
        excel_fieldcat  TYPE zexcel_t_fieldcatalog,
        excel_sheetname TYPE zexcel_sheet_title,
      END OF ty_excel .

  class-data:
    exceltab  TYPE TABLE OF ty_excel .
  class-data XDATA type XSTRING read-only .

  class-methods DOWNLOAD
    importing
      value(LO_EXCEL) type ref to ZCL_EXCEL optional
      value(IV_WRITERCLASS_NAME) type CLIKE optional
      value(IV_INFO_MESSAGE) type ABAP_BOOL default ABAP_TRUE
      value(GC_SAVE_FILE_NAME) type STRING optional
      value(METHOD) type CHAR20 default 'DOWNLOAD_FRONTEND'
      value(T_EXCELTAB) like EXCELTAB optional
      value(GC_EMAIL) type STRING optional
    raising
      ZCX_EXCEL .
  class-methods UPLOAD
    exporting
      value(TAB) type ANY TABLE
      value(DREF) type ref to DATA
    raising
      ZCX_EXCEL .
  class-methods LOAD_SMW0
    importing
      !IV_W3OBJID type W3OBJID
    exporting
      !RO_EXCEL type ref to ZCL_EXCEL
    raising
      ZCX_EXCEL .
  PROTECTED SECTION.
private section.

  class-data PATH type STRING .
  class-data SAVE_FILE_NAME type STRING .
  class-data T_RAWDATA type SOLIX_TAB .
  class-data BYTECOUNT type I .
  class-data EMAIL type STRING .

  class-methods SEND_EMAIL .
  class-methods F4_FILE
    returning
      value(SELECTED_FILE) type STRING
    exceptions
      PATH_ERROR .
  class-methods F4_FOLDER
    returning
      value(SELECTED_FOLDER) type STRING
    exceptions
      PATH_ERROR .
  class-methods DOWNLOAD_FRONTEND
    raising
      ZCX_EXCEL .
  class-methods DISPLAY_ONLINE .
ENDCLASS.



CLASS ZCL_ABAP2XLSX_TOOLS IMPLEMENTATION.


  METHOD download.

    DATA:cl_writer TYPE REF TO zif_excel_writer,
         cl_error  TYPE REF TO zcx_excel.
    DATA:"lo_excel     TYPE REF TO zcl_excel,
         lo_worksheet TYPE REF TO zcl_excel_worksheet.
    DATA:ls_table_settings TYPE zexcel_s_table_settings.
    DATA:lv_count TYPE i,
         l_col    TYPE zexcel_cell_column_alpha.
    save_file_name = gc_save_file_name.
    email = gc_email.
    TRY.

        IF iv_writerclass_name IS INITIAL.
          CREATE OBJECT cl_writer TYPE zcl_excel_writer_2007.
        ELSE.
          CREATE OBJECT cl_writer TYPE (iv_writerclass_name).
        ENDIF.
        IF lo_excel IS NOT BOUND.
          " Creates active sheet
          CREATE OBJECT lo_excel.

**          " Get active sheet
**          lo_worksheet = lo_excel->get_active_worksheet( ).
**          lo_worksheet->set_title( 'Internal table' ).
**          IF lt_field_catalog IS INITIAL.
**            lt_field_catalog = zcl_excel_common=>get_fieldcatalog( ip_table = tab ).
**          ENDIF.
**          ls_table_settings-table_style  = zcl_excel_table=>builtinstyle_medium5.
**
**          lo_worksheet->bind_table( ip_table          = tab
**                                    is_table_settings = ls_table_settings
**                                    it_field_catalog  = lt_field_catalog ).
**          "自动列宽
**          lv_count = 1.
**          LOOP AT lt_field_catalog INTO DATA(ls_field_catalog) WHERE dynpfld = 'X'.
**            zcl_excel_common=>convert_column2alpha(
**              EXPORTING
**                ip_column = lv_count
**              RECEIVING
**                ep_column = l_col
**            ).
**
**            DATA(lo_column) = lo_worksheet->get_column( l_col ).
**            lo_column->set_auto_size( ip_auto_size = abap_true ).
**            ADD 1 TO lv_count.
**          ENDLOOP.
**          lo_worksheet->calculate_column_widths( ).
          LOOP AT t_exceltab ASSIGNING FIELD-SYMBOL(<gt_exceltab>).
            CLEAR:lo_worksheet,ls_table_settings.

            IF sy-tabix = 1.
              " Get active sheet
              lo_worksheet = lo_excel->get_active_worksheet( ).
            ELSE.
              " Add another table
              lo_worksheet = lo_excel->add_new_worksheet( ).
            ENDIF.
            IF <gt_exceltab>-excel_sheetname IS INITIAL.
              lo_worksheet->set_title( 'Internal table' ).
            ELSE.
              lo_worksheet->set_title( <gt_exceltab>-excel_sheetname ).
            ENDIF.

            ls_table_settings-table_style  = zcl_excel_table=>builtinstyle_medium5.
            ASSIGN <gt_exceltab>-excel_tabdref->* TO FIELD-SYMBOL(<tab>).
            IF <tab> IS ASSIGNED.
              lo_worksheet->bind_table( ip_table          = <tab>
                                        is_table_settings = ls_table_settings
                                        it_field_catalog  = <gt_exceltab>-excel_fieldcat ).
              IF <gt_exceltab>-excel_fieldcat IS INITIAL.
                <gt_exceltab>-excel_fieldcat = zcl_excel_common=>get_fieldcatalog( ip_table = <tab> ).
              ENDIF.
            ENDIF.

            "自动列宽
            lv_count = 1.
            LOOP AT <gt_exceltab>-excel_fieldcat INTO DATA(ls_field_catalog) WHERE dynpfld = 'X'.
              zcl_excel_common=>convert_column2alpha(
                EXPORTING
                  ip_column = lv_count
                RECEIVING
                  ep_column = l_col
              ).
              DATA(lo_column) = lo_worksheet->get_column( l_col ).
              lo_column->set_auto_size( ip_auto_size = abap_true ).
              ADD 1 TO lv_count.
            ENDLOOP.
            lo_worksheet->calculate_column_widths( ).
            UNASSIGN <tab>.
          ENDLOOP.
        ENDIF.
        xdata = cl_writer->write_file( lo_excel ).
        t_rawdata = cl_bcs_convert=>xstring_to_solix( iv_xstring  = xdata ).
        bytecount = xstrlen( xdata ).
        CASE to_lower( method ).
*          WHEN rb_down.
          WHEN 'download_frontend'.
            IF sy-batch IS INITIAL.
              " 选择要保存的文件路径  04.05.2024 10:16:47 by kkw
              CALL METHOD f4_folder
                RECEIVING
                  selected_folder = path
                EXCEPTIONS
                  path_error      = 1
                  OTHERS          = 2.
              IF sy-subrc <> 0.
                MESSAGE s000(oo) WITH '请选择要保存的路径'.
                RETURN.
              ENDIF.

              download_frontend( ).
            ELSE.
              MESSAGE e802(zabap2xlsx).
            ENDIF.
*
*          WHEN rb_back.
*            cl_output->download_backend( ).
*
          WHEN 'display_online'.
            IF sy-batch IS INITIAL.
              display_online( ).
            ELSE.
              MESSAGE e803(zabap2xlsx).
            ENDIF.
*
*          WHEN rb_send.
*            cl_output->send_email( ).
*
          WHEN 'send_email'.

            send_email( ).
        ENDCASE.

      CATCH zcx_excel INTO cl_error.
        IF iv_info_message = abap_true.
          MESSAGE cl_error TYPE 'I' DISPLAY LIKE 'E'.
        ELSE.
          RAISE EXCEPTION cl_error.
        ENDIF.
    ENDTRY.
  ENDMETHOD.


  METHOD download_frontend.
    DATA: filename TYPE string,
          message  TYPE string.
    CHECK path IS NOT INITIAL.
* I don't like p_path here - but for this include it's ok
    filename = path.
* Add trailing "\" or "/"
    IF filename CA '/'.
      REPLACE REGEX '([^/])\s*$' IN filename WITH '$1/' .
    ELSE.
      REPLACE REGEX '([^\\])\s*$' IN filename WITH '$1\\'.
    ENDIF.

    CONCATENATE filename save_file_name '.xlsx' INTO filename.
* Get trailing blank
    cl_gui_frontend_services=>gui_download(
    EXPORTING bin_filesize = bytecount
              filename     = filename
              filetype     = 'BIN'
    CHANGING data_tab     = t_rawdata
    EXCEPTIONS
      OTHERS       = 1 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO message.
      RAISE EXCEPTION TYPE zcx_excel EXPORTING error = message.
    ELSE.

    ENDIF.
  ENDMETHOD.


  METHOD f4_file.
    DATA:lv_file_filter TYPE string,
         lt_files       TYPE filetable,
         lv_rc          TYPE i,
         user_action    TYPE i,
         p_path         TYPE char50,
         file_encoding  TYPE abap_encoding VALUE '8400'.
    lv_file_filter = 'Excel Files (*.XLSX;*.XLSM)|*.XLSX;*.XLSM'.
    GET PARAMETER ID 'FILE_PATH' FIELD p_path.
    IF sy-subrc EQ 0.
      selected_file = p_path.
    ENDIF.
    cl_gui_frontend_services=>file_open_dialog( EXPORTING
                                                  default_filename        = selected_file
                                                  file_filter             = lv_file_filter
                                                CHANGING
                                                  file_table              = lt_files
                                                  rc                      = lv_rc
                                                  user_action             = user_action
                                                  file_encoding           = file_encoding
                                                EXCEPTIONS
                                                  OTHERS                  = 1 ).
    CALL METHOD cl_gui_cfw=>flush.
    IF sy-subrc NE 0 OR user_action NE 0.
      RAISE path_error.
    ELSE.
      READ TABLE lt_files INDEX 1 INTO selected_file.
      p_path = selected_file.
      SET PARAMETER ID 'FILE_PATH' FIELD p_path.
    ENDIF.
  ENDMETHOD.


  METHOD f4_folder.
    DATA:initial_folder TYPE string,
         p_path         TYPE char50.
    GET PARAMETER ID 'FOLDER_PATH' FIELD p_path.
    IF sy-subrc EQ 0.
      initial_folder = p_path.
    ENDIF.
    cl_gui_frontend_services=>directory_browse(
    EXPORTING
      window_title         = '选择下载 EXCEL 文件的路径'
      initial_folder       = initial_folder
    CHANGING
      selected_folder      = selected_folder
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4
      ).
    CALL METHOD cl_gui_cfw=>flush.
    IF sy-subrc EQ 0.
      p_path = selected_folder.
      SET PARAMETER ID 'FOLDER_PATH' FIELD p_path.
    ELSE.
      RAISE path_error.
    ENDIF.
  ENDMETHOD.


  METHOD upload.
    DATA:lv_extension TYPE string,
         reader       TYPE REF TO zif_excel_reader,
         excel        TYPE REF TO zcl_excel,
         cl_error     TYPE REF TO zcx_excel,
         lo_worksheet TYPE REF TO zcl_excel_worksheet.
    CALL METHOD f4_file
      RECEIVING
        selected_file = path
      EXCEPTIONS
        path_error    = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
      MESSAGE s000(oo) WITH '发生了错误' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CHECK path IS NOT INITIAL.
    FIND REGEX '(\.xlsx|\.xlsm)\s*$' IN path SUBMATCHES lv_extension.
    TRANSLATE lv_extension TO UPPER CASE.
    CASE lv_extension.
      WHEN '.XLSX'.
        CREATE OBJECT reader TYPE zcl_excel_reader_2007.
        excel = reader->load_file( i_filename = path i_from_applserver = abap_false ).
        "Use template for charts
        excel->use_template = abap_true.
      WHEN '.XLSM'.
        CREATE OBJECT reader TYPE zcl_excel_reader_xlsm.
        excel = reader->load_file( i_filename = path i_from_applserver = abap_false ).
        "Use template for charts
        excel->use_template = abap_true.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_excel EXPORTING error = '不支持的文件类型'.
    ENDCASE.
    TRY.
        lo_worksheet = excel->get_worksheet_by_index( 1 ).
        lo_worksheet->convert_to_table(
        IMPORTING
          er_data = dref
          et_data = tab
          ).
      CATCH zcx_excel INTO cl_error.
        RAISE EXCEPTION cl_error.
    ENDTRY.

  ENDMETHOD.


  METHOD display_online.
    DATA:error       TYPE REF TO i_oi_error,
         t_errors    TYPE STANDARD TABLE OF REF TO i_oi_error WITH NON-UNIQUE DEFAULT KEY,
         cl_control  TYPE REF TO i_oi_container_control, "OIContainerCtrl
         cl_document TYPE REF TO i_oi_document_proxy.   "Office Dokument

    c_oi_container_control_creator=>get_container_control( IMPORTING control = cl_control
                                                                     error   = error ).
    APPEND error TO t_errors.

    cl_control->init_control( EXPORTING  inplace_enabled     = 'X'
                                         no_flush            = 'X'
                                         r3_application_name = 'Demo Document Container'
                                         parent              = cl_gui_container=>screen0
                              IMPORTING  error               = error
                              EXCEPTIONS OTHERS              = 2 ).
    APPEND error TO t_errors.

    cl_control->get_document_proxy( EXPORTING document_type  = 'Excel.Sheet'                " EXCEL
                                              no_flush       = ' '
                                    IMPORTING document_proxy = cl_document
                                              error          = error ).
    APPEND error TO t_errors.
* Errorhandling should be inserted here

    cl_document->open_document_from_table( EXPORTING document_size    = bytecount
                                                     document_table   = t_rawdata
                                                     open_inplace     = 'X' ).

    WRITE: '.'.  " To create an output.  That way screen0 will exist
  ENDMETHOD.


  METHOD load_smw0.
    DATA: lv_excel_data   TYPE xstring,
          lt_mime         TYPE TABLE OF w3mime,
          ls_key          TYPE wwwdatatab,
          lv_errormessage TYPE string,
          lv_filesize     TYPE i,
          lv_filesizec    TYPE c LENGTH 10,
          lo_reader       TYPE REF TO zif_excel_reader.

*--------------------------------------------------------------------*
* Read file into binary string
*--------------------------------------------------------------------*

    ls_key-relid = 'MI'.
    ls_key-objid = iv_w3objid .

    CALL FUNCTION 'WWWDATA_IMPORT'
      EXPORTING
        key    = ls_key
      TABLES
        mime   = lt_mime
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0.
      lv_errormessage = '加载 SMW0 模板时出现问题'(004).
      zcx_excel=>raise_text( lv_errormessage ).
    ENDIF.

    CALL FUNCTION 'WWWPARAMS_READ'
      EXPORTING
        relid = ls_key-relid
        objid = ls_key-objid
        name  = 'filesize'
      IMPORTING
        value = lv_filesizec.

    lv_filesize = lv_filesizec.
    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_filesize
      IMPORTING
        buffer       = lv_excel_data
      TABLES
        binary_tab   = lt_mime
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.

*--------------------------------------------------------------------*
* Parse Excel data into ZCL_EXCEL object from binary string
*--------------------------------------------------------------------*
    CREATE OBJECT lo_reader TYPE zcl_excel_reader_2007.
    ro_excel = lo_reader->load( i_excel2007 = lv_excel_data ).
  ENDMETHOD.


  METHOD send_email.
* Needed to send emails
    DATA: bcs_exception        TYPE REF TO cx_bcs,
          errortext            TYPE string,
          cl_send_request      TYPE REF TO cl_bcs,
          cl_document          TYPE REF TO cl_document_bcs,
          cl_recipient         TYPE REF TO if_recipient_bcs,
          cl_sender            TYPE REF TO cl_cam_address_bcs,
          t_attachment_header  TYPE soli_tab,
          wa_attachment_header LIKE LINE OF t_attachment_header,
          attachment_subject   TYPE sood-objdes,

          sood_bytecount       TYPE sood-objlen,
          mail_title           TYPE so_obj_des,
          t_mailtext           TYPE soli_tab,
          wa_mailtext          LIKE LINE OF t_mailtext,
          send_to              TYPE adr6-smtp_addr,
          sent                 TYPE abap_bool.


    mail_title     = 'Mail title'.
    wa_mailtext    = 'Mailtext'.
    APPEND wa_mailtext TO t_mailtext.

    TRY.
* Create send request
        cl_send_request = cl_bcs=>create_persistent( ).
* Create new document with mailtitle and mailtextg
        cl_document = cl_document_bcs=>create_document( i_type    = 'RAW' "#EC NOTEXT
                                                        i_text    = t_mailtext
                                                        i_subject = mail_title ).
* Add attachment to document
* since the new excelfiles have an 4-character extension .xlsx but the attachment-type only holds 3 charactes .xls,
* we have to specify the real filename via attachment header
* Use attachment_type xls to have SAP display attachment with the excel-icon
        attachment_subject  = save_file_name.
        CONCATENATE '&SO_FILENAME=' attachment_subject INTO wa_attachment_header.
        APPEND wa_attachment_header TO t_attachment_header.
* Attachment
        sood_bytecount = bytecount.  " next method expects sood_bytecount instead of any positive integer *sigh*
        cl_document->add_attachment(  i_attachment_type    = 'XLS' "#EC NOTEXT
                                      i_attachment_subject = attachment_subject
                                      i_attachment_size    = sood_bytecount
                                      i_att_content_hex    = t_rawdata
                                      i_attachment_header  = t_attachment_header ).

* add document to send request
        cl_send_request->set_document( cl_document ).

* add recipient(s) - here only 1 will be needed
        send_to = email.
        IF send_to IS INITIAL.
          send_to = 'no_email@no_email.no_email'.  " Place into SOST in any case for demonstration purposes
        ENDIF.
        cl_recipient = cl_cam_address_bcs=>create_internet_address( send_to ).
        cl_send_request->add_recipient( cl_recipient ).

* Und abschicken
        sent = cl_send_request->send( i_with_error_screen = 'X' ).

        COMMIT WORK.

        IF sent = abap_true.
          MESSAGE s805(zabap2xlsx).
          MESSAGE 'Document ready to be sent - Check SOST or SCOT' TYPE 'S'.
        ELSE.
          MESSAGE e804(zabap2xlsx) WITH email.
        ENDIF.

      CATCH cx_bcs INTO bcs_exception.
        errortext = bcs_exception->if_message~get_text( ).
        MESSAGE errortext TYPE 'E'.

    ENDTRY.
  ENDMETHOD.
ENDCLASS.
