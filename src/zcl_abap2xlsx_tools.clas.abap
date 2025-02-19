class ZCL_ABAP2XLSX_TOOLS definition
  public
  final
  create public .

public section.

  methods DOWNLOAD
    importing
      value(TAB) type ANY TABLE optional
      value(LO_EXCEL) type ref to ZCL_EXCEL optional
      value(IV_WRITERCLASS_NAME) type CLIKE optional
      value(IV_INFO_MESSAGE) type ABAP_BOOL default ABAP_TRUE
      !GC_SAVE_FILE_NAME type STRING
      value(METHOD) type CHAR20 default 'DOWNLOAD_FRONTEND'
    changing
      value(LT_FIELD_CATALOG) type ZEXCEL_T_FIELDCATALOG optional
    raising
      ZCX_EXCEL .
  methods UPLOAD
    exporting
      value(TAB) type ANY TABLE
      value(DREF) type ref to DATA
    raising
      ZCX_EXCEL .
  PROTECTED SECTION.
private section.

  types:
    BEGIN OF ty_excel,
          excel_tab      TYPE REF TO data,
          excel_fieldcat TYPE zexcel_t_fieldcatalog,
        END OF ty_excel .

  data PATH type STRING .
  data GC_SAVE_FILE_NAME type STRING .
  data XDATA type XSTRING .
  data T_RAWDATA type SOLIX_TAB .
  data BYTECOUNT type I .
  data:
    exceltab TYPE TABLE OF ty_excel .

  methods F4_FOLDER
    returning
      value(SELECTED_FOLDER) type STRING
    exceptions
      PATH_ERROR .
  methods F4_FILE
    returning
      value(SELECTED_FILE) type STRING
    exceptions
      PATH_ERROR .
  methods DOWNLOAD_FRONTEND
    raising
      ZCX_EXCEL .
  methods DISPLAY_ONLINE .
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
    TRY.

        IF iv_writerclass_name IS INITIAL.
          CREATE OBJECT cl_writer TYPE zcl_excel_writer_2007.
        ELSE.
          CREATE OBJECT cl_writer TYPE (iv_writerclass_name).
        ENDIF.
        IF lo_excel IS NOT BOUND.
          " Creates active sheet
          CREATE OBJECT lo_excel.

          " Get active sheet
          lo_worksheet = lo_excel->get_active_worksheet( ).
          lo_worksheet->set_title( 'Internal table' ).
          IF lt_field_catalog IS INITIAL.
            lt_field_catalog = zcl_excel_common=>get_fieldcatalog( ip_table = tab ).
          ENDIF.
          ls_table_settings-table_style  = zcl_excel_table=>builtinstyle_medium5.

          lo_worksheet->bind_table( ip_table          = tab
                                    is_table_settings = ls_table_settings
                                    it_field_catalog  = lt_field_catalog ).
          "自动列宽
          lv_count = 1.
          LOOP AT lt_field_catalog INTO DATA(ls_field_catalog) WHERE dynpfld = 'X'.
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
        ENDIF.
        me->xdata = cl_writer->write_file( lo_excel ).
        me->t_rawdata = cl_bcs_convert=>xstring_to_solix( iv_xstring  = me->xdata ).
        me->bytecount = xstrlen( me->xdata ).

        CASE to_lower( method ).
*          WHEN rb_down.
          WHEN 'download_frontend'.
            IF sy-batch IS INITIAL.
              " 选择要保存的文件路径  04.05.2024 10:16:47 by kkw
              CALL METHOD me->f4_folder
                RECEIVING
                  selected_folder = me->path
                EXCEPTIONS
                  path_error      = 1
                  OTHERS          = 2.
              IF sy-subrc <> 0.
                MESSAGE s000(oo) WITH '请选择要保存的路径'.
                RETURN.
              ENDIF.
              me->gc_save_file_name = gc_save_file_name.
              me->download_frontend( ).
            ELSE.
              MESSAGE e802(zabap2xlsx).
            ENDIF.
*
*          WHEN rb_back.
*            cl_output->download_backend( ).
*
          WHEN 'display_online'.
            IF sy-batch IS INITIAL.
              me->display_online( ).
            ELSE.
              MESSAGE e803(zabap2xlsx).
            ENDIF.
*
*          WHEN rb_send.
*            cl_output->send_email( ).
*
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
    CHECK me->path IS NOT INITIAL.
* I don't like p_path here - but for this include it's ok
    filename = me->path.
* Add trailing "\" or "/"
    IF filename CA '/'.
      REPLACE REGEX '([^/])\s*$' IN filename WITH '$1/' .
    ELSE.
      REPLACE REGEX '([^\\])\s*$' IN filename WITH '$1\\'.
    ENDIF.

    CONCATENATE filename me->gc_save_file_name '.xlsx' INTO filename.
* Get trailing blank
    cl_gui_frontend_services=>gui_download(
    EXPORTING bin_filesize = me->bytecount
              filename     = filename
              filetype     = 'BIN'
    CHANGING data_tab     = me->t_rawdata
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
    CLEAR me->path.
    CALL METHOD me->f4_file
      RECEIVING
        selected_file = me->path
      EXCEPTIONS
        path_error    = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
      MESSAGE s000(oo) WITH '发生了错误' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CHECK me->path IS NOT INITIAL.
    FIND REGEX '(\.xlsx|\.xlsm)\s*$' IN me->path SUBMATCHES lv_extension.
    TRANSLATE lv_extension TO UPPER CASE.
    CASE lv_extension.
      WHEN '.XLSX'.
        CREATE OBJECT reader TYPE zcl_excel_reader_2007.
        excel = reader->load_file( i_filename = me->path i_from_applserver = abap_false ).
        "Use template for charts
        excel->use_template = abap_true.
      WHEN '.XLSM'.
        CREATE OBJECT reader TYPE zcl_excel_reader_xlsm.
        excel = reader->load_file( i_filename = me->path i_from_applserver = abap_false ).
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
ENDCLASS.
