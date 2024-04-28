*&---------------------------------------------------------------------*
*& 包含               ZDINGTALKPLUGINS
*&---------------------------------------------------------------------*
*& Form getsign
*&---------------------------------------------------------------------*
*& 按照钉钉文档
*& https://open.dingtalk.com/document/robots/custom-robot-access
*& 计算签名
*&---------------------------------------------------------------------*
*&      --> KEY
*&      <-- SIGN
*&      <-- TIMESTAMP
*&---------------------------------------------------------------------*
FORM getsign  USING    p_key TYPE string
              CHANGING p_sign TYPE string
                       p_timestamp TYPE string.
  DATA:if_data_s        TYPE string,
       if_data          TYPE xstring,
       if_key           TYPE xstring,
       ef_hmacb64string TYPE string,
       stamp            TYPE timestampl,
       stamp_char       TYPE char22.
  CLEAR:p_sign,p_timestamp.
  TRY.
      if_key = cl_abap_hmac=>string_to_xstring( p_key ).
    CATCH cx_abap_message_digest.
      EXIT.
  ENDTRY.
  DATA(cc) = cl_abap_char_utilities=>newline.
  GET TIME STAMP FIELD stamp.
  stamp_char = stamp.
  CALL METHOD cl_pco_utility=>convert_abap_timestamp_to_java
    EXPORTING
      iv_date      = CONV #( stamp_char(8) )
      iv_time      = CONV #( stamp_char+8(6) )
      iv_msec      = CONV #( stamp_char+15(3) )
    IMPORTING
      ev_timestamp = p_timestamp.
  if_data_s = p_timestamp && cc && p_key.
  TRY.
      if_data = cl_abap_hmac=>string_to_xstring( if_data_s ).
    CATCH cx_abap_message_digest.
      EXIT.
  ENDTRY.
  TRY.
      CALL METHOD cl_abap_hmac=>calculate_hmac_for_raw
        EXPORTING
          if_algorithm     = 'SHA256'
          if_key           = if_key
          if_data          = if_data
*         if_length        = 0
        IMPORTING
*         ef_hmacstring    = ef_hmacstring
*         ef_hmacxstring   = ef_hmacxstring
          ef_hmacb64string = ef_hmacb64string.
      .
    CATCH cx_abap_message_digest.
      EXIT.
  ENDTRY.
  p_sign = cl_http_utility=>escape_url( ef_hmacb64string ).
ENDFORM.
