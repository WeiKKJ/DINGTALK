CLASS zcl_dingtalk DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_excel,
        excel_tabdref   TYPE REF TO data,
        excel_fieldcat  TYPE zexcel_t_fieldcatalog,
        excel_sheetname TYPE zexcel_sheet_title,
      END OF ty_excel .
    TYPES:
      BEGIN OF ty_kv,
        key   TYPE string,
        value TYPE string,
      END OF ty_kv .

    CLASS-DATA:
      lt_ztddlistsub TYPE TABLE OF ztddlistsub .
    CLASS-DATA:
      lt_userid_list TYPE TABLE OF ztdduser-userid .
    CLASS-DATA:
      lt_ztdduser  TYPE TABLE OF ztdduser .
    CLASS-DATA:
      exceltab  TYPE TABLE OF ty_excel .
    CLASS-DATA:
     lt_kv TYPE TABLE OF ty_kv .

    METHODS constructor
      IMPORTING
        VALUE(appid) TYPE ze_appid .
    CLASS-METHODS create_http_client
      IMPORTING
        VALUE(input)     TYPE string OPTIONAL
        VALUE(url)       TYPE string
        VALUE(username)  TYPE string OPTIONAL
        VALUE(password)  TYPE string OPTIONAL
        VALUE(reqmethod) TYPE char4
        VALUE(http1_1)   TYPE abap_bool DEFAULT abap_true
        VALUE(proxy)     TYPE string OPTIONAL
        VALUE(bodytype)  TYPE string DEFAULT 'JSON'
        VALUE(header)    TYPE STANDARD TABLE OPTIONAL
      EXPORTING
        VALUE(output)    TYPE string
        VALUE(rtmsg)     TYPE string
        VALUE(status)    TYPE i .
    CLASS-METHODS split_filename
      IMPORTING
        VALUE(long_filename)  TYPE char255
      EXPORTING
        VALUE(pure_filename)  TYPE char255
        VALUE(pure_extension) TYPE char10 .
    CLASS-METHODS create_excel
      IMPORTING
        VALUE(gt_exceltab)  LIKE exceltab
      RETURNING
        VALUE(xstring_data) TYPE xstring .
    METHODS post2ddrobot
      IMPORTING
        VALUE(msgtype) TYPE ze_msgtype DEFAULT 'text'
        VALUE(title)   TYPE string OPTIONAL
        VALUE(text)    TYPE string OPTIONAL
      EXPORTING
        VALUE(rtype)   TYPE bapi_mtype
        VALUE(rtmsg)   TYPE bapi_msg .
    METHODS post2corpconversation
      IMPORTING
        VALUE(msgtype)  TYPE ze_msgtype DEFAULT 'text'
        VALUE(userid)   TYPE string
        VALUE(title)    TYPE string OPTIONAL
        VALUE(text)     TYPE string OPTIONAL
        VALUE(media_id) TYPE ze_media_id OPTIONAL
        VALUE(duration) TYPE i OPTIONAL
      EXPORTING
        VALUE(rtype)    TYPE bapi_mtype
        VALUE(rtmsg)    TYPE bapi_msg .
    METHODS init_dept
      IMPORTING
        VALUE(dept_id)              TYPE ze_dept_id DEFAULT 1
        VALUE(language)             TYPE char5 DEFAULT 'zh_CN'
        VALUE(init_all)             TYPE abap_bool DEFAULT abap_false
      EXPORTING
        VALUE(rtype)                TYPE bapi_mtype
        VALUE(rtmsg)                TYPE bapi_msg
        VALUE(gt_ztddlistsub_total) LIKE lt_ztddlistsub .
    METHODS init_user
      IMPORTING
        VALUE(dept_id)  TYPE ze_dept_id
        VALUE(init_all) TYPE abap_bool DEFAULT abap_false
      EXPORTING
        VALUE(rtype)    TYPE bapi_mtype
        VALUE(rtmsg)    TYPE bapi_msg .
    METHODS upload_media
      IMPORTING
        VALUE(type)     TYPE ze_media_type
        VALUE(header)   TYPE ANY TABLE
        !via            TYPE string DEFAULT `FASTAPI`
      EXPORTING
        VALUE(media_id) TYPE string
        VALUE(rtype)    TYPE bapi_mtype
        VALUE(rtmsg)    TYPE bapi_msg .
    METHODS robot_groupmessages_send
      IMPORTING
        VALUE(msgparam)           TYPE string
        VALUE(msgkey)             TYPE string DEFAULT `sampleText`
        VALUE(openconversationid) TYPE string
        VALUE(robotcode)          TYPE string
      EXPORTING
        VALUE(rtype)              TYPE bapi_mtype
        VALUE(rtmsg)              TYPE bapi_msg .
    METHODS robot_interactivecards_send
      IMPORTING
        VALUE(cardtemplateid)     TYPE string
        VALUE(openconversationid) TYPE string
        VALUE(outtrackid)         TYPE string
        VALUE(robotcode)          TYPE string
        VALUE(conversationtype)   TYPE i DEFAULT 1
        VALUE(callbackroutekey)   TYPE string OPTIONAL
        VALUE(carddata)           LIKE lt_kv
        VALUE(privatedata)        LIKE lt_kv OPTIONAL
        VALUE(useridtype)         TYPE i DEFAULT 1
      EXPORTING
        VALUE(rtype)              TYPE bapi_mtype
        VALUE(rtmsg)              TYPE bapi_msg .
protected section.
private section.

  data APPID type ZE_APPID .
  data APPNAME type ZE_NAME .
  constants CORPCONVERSATION_URL type STRING value `https://oapi.dingtalk.com/topapi/message/corpconversation/asyncsend_v2` ##NO_TEXT.
  constants GET_DEPT_URL type STRING value `https://oapi.dingtalk.com/topapi/v2/department/listsub` ##NO_TEXT.
  constants GET_TOKEN_URL type STRING value `https://oapi.dingtalk.com/gettoken` ##NO_TEXT.
  constants GET_USER_URL type STRING value `https://oapi.dingtalk.com/topapi/v2/user/get` ##NO_TEXT.
  constants GET_USERLIST_URL type STRING value `https://oapi.dingtalk.com/topapi/user/listid` ##NO_TEXT.
  constants UPLOAD_MEDIA_URL type STRING value `https://oapi.dingtalk.com/media/upload` ##NO_TEXT.
  constants MAXLENGTH type I value 20971520 ##NO_TEXT.
  data MY_LOGGER type ref to ZIF_LOGGER .
  constants UPLOAD_MEDIA_VIAFASTAPI_URL type STRING value `http://10.9.203.28:18888/uploadmedia` ##NO_TEXT.
  constants ROBOT_GROUPMESSAGES_SEND_URL type STRING value `https://api.dingtalk.com/v1.0/robot/groupMessages/send` ##NO_TEXT.
  constants ROBOT_INTERACTIVECARDS_URL type STRING value `https://api.dingtalk.com/v1.0/im/interactiveCards/send` ##NO_TEXT.

  methods GET_DEPTSUBALL
    importing
      value(ZTDDLISTSUB_IN) like LT_ZTDDLISTSUB
      value(ACTION) type CHAR3 default 'GET'
    exporting
      !ZTDDLISTSUB_OUT like LT_ZTDDLISTSUB .
  methods GET_USERLIST
    importing
      value(DEPT_ID) type ZE_DEPT_ID
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG
      value(GT_USERLIST) like LT_USERID_LIST .
  methods GET_DEPT
    importing
      value(DEPT_ID) type ZE_DEPT_ID default 1
      value(LANGUAGE) type CHAR5 default 'zh_CN'
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG
      value(GT_ZTDDLISTSUB) like LT_ZTDDLISTSUB .
  methods GET_USERINFO
    importing
      value(LANGUAGE) type CHAR5 default 'zh_CN'
      value(USERID) type ZE_USERID
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG
      value(GT_ZTDDUSER) like LT_ZTDDUSER .
  methods GETTOKEN
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG
      value(ACCESS_TOKEN) type ZE_ACCESS_TOKEN
      value(AGENTID) type ZE_AGENTID .
  methods GETSIGN
    importing
      value(SECRET) type STRING
    exporting
      value(SIGN) type STRING
      value(TIMESTAMP) type STRING .
ENDCLASS.



CLASS ZCL_DINGTALK IMPLEMENTATION.


  METHOD create_http_client.
    DATA:message       TYPE string,
         name          TYPE string,
         value         TYPE string,
         cdata         TYPE string,
         xdata         TYPE xstring,
         proxy_host    TYPE string,
         proxy_service TYPE string,
         proxy_user    TYPE string,
         proxy_passwd  TYPE string,
         http_object   TYPE REF TO if_http_client,
         http_entity   TYPE REF TO if_http_entity, "http实体
         length        TYPE i,
         fields        TYPE tihttpnvp,
         it_ihttpnvp   TYPE TABLE OF ihttpnvp.
    DATA:lv_content_disposition TYPE string,
         lv_content_type        TYPE string.
    DATA:long_filename  TYPE char255,
         pure_filename  TYPE char255,
         pure_extension TYPE char10.
    FIELD-SYMBOLS:<wa>       TYPE any,
                  <fs_name>  TYPE any,
                  <fs_value> TYPE any,
                  <fs_cdata> TYPE any,
                  <fs_xdata> TYPE any.

    CLEAR:output,length,rtmsg,name,value,status,
    pure_filename,pure_extension,
    lv_content_disposition,lv_content_type,
    proxy_service,proxy_host,proxy_user,proxy_passwd.

    length = strlen( input ).
    IF proxy IS NOT INITIAL.
      SPLIT proxy AT '/'
      INTO proxy_host proxy_service proxy_user proxy_passwd.
    ENDIF.
* 创建URL对象
    CALL METHOD cl_http_client=>create_by_url "/CREATE(直接通过IP端口)
      EXPORTING
        url                = url
        proxy_service      = proxy_service
        proxy_host         = proxy_host
        proxy_user         = proxy_user
        proxy_passwd       = proxy_passwd
      IMPORTING
        client             = http_object
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4.
    IF sy-subrc NE 0.
      http_object->get_last_error( IMPORTING message = message ).
      rtmsg = message.
      RETURN.
    ENDIF.

*不显示登录屏幕
    http_object->propertytype_logon_popup = http_object->co_disabled.
*设定传输请求内容及编码格式

*设置HTTP版本-不设置则默认1.0
    IF http1_1 = 'X'.
      http_object->request->set_version( if_http_request=>co_protocol_version_1_1 ).
    ELSE.
      http_object->request->set_version( if_http_request=>co_protocol_version_1_0 ).
    ENDIF.


*将HTTP代理设置为POST
    CASE reqmethod.
      WHEN 'POST'.
        http_object->request->set_method( if_http_request=>co_request_method_post ).
      WHEN 'GET'.
        http_object->request->set_method( if_http_request=>co_request_method_get ).
      WHEN OTHERS.
        rtmsg = '请求类型必填'.
        RETURN.
    ENDCASE.

*设置账号密码
    IF username IS NOT INITIAL
    AND password IS NOT INITIAL.
      CALL METHOD http_object->authenticate
        EXPORTING
          username = username
          password = password.
    ENDIF.

    CASE bodytype.
      WHEN 'JSON'.
        http_object->request->set_header_field( name = 'Content-Type' value = 'application/json;charset=utf-8' ).
      WHEN 'FORM-DATA'.
*        http_object->request->set_content_type( content_type = 'application/ x-www-form-urlencoded; charset=utf-8' ).
*        http_object->request->set_header_field( name = 'charset' value = 'UTF-8' ).
*        http_object->request->set_header_field( name = 'accept-language' value = 'zh-CN' ).
        http_object->request->set_header_field( name = 'Content-Type' value = 'multipart/form-data' ).
    ENDCASE.

*设置头部数据
    LOOP AT header ASSIGNING <wa>.
      CLEAR:name,value,cdata,xdata.
      ASSIGN COMPONENT 'NAME' OF STRUCTURE <wa> TO <fs_name>.
      IF sy-subrc NE 0.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT 'VALUE' OF STRUCTURE <wa> TO <fs_value>.
      IF sy-subrc NE 0.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT 'CDATA' OF STRUCTURE <wa> TO <fs_cdata>.
      IF sy-subrc NE 0.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT 'XDATA' OF STRUCTURE <wa> TO <fs_xdata>.
      IF sy-subrc NE 0.
        RETURN.
      ENDIF.
      CHECK <fs_name> IS NOT INITIAL AND <fs_value> IS NOT INITIAL.
      name = <fs_name>.
      value = <fs_value>.
      cdata = <fs_cdata>.
      xdata = <fs_xdata>.
      IF bodytype = 'JSON'.
        http_object->request->set_header_field( name = name value = value ).
*设置下 content_type
      ELSEIF bodytype = 'FORM-DATA'.
        FREE http_entity.
        http_entity = http_object->request->if_http_entity~add_multipart( ).
        CASE name.
          WHEN 'Content-Disposition'.
            IF cdata IS NOT INITIAL." 文本类型  05.06.2024 19:51:02 by kkw
              http_entity->set_header_field( name = name value = value ).
              http_entity->append_cdata( data = cdata ).
              CONTINUE.
            ENDIF.
            " 文件类型  05.06.2024 19:51:16 by kkw
            SPLIT condense( replace( val  = value
                             pcre = `\s`
                             with = ``
                             occ  = 0 ) ) AT `;` INTO TABLE DATA(lt_split).

            LOOP AT lt_split ASSIGNING FIELD-SYMBOL(<lt_split>).
              IF <lt_split>(8) = 'filename' AND <lt_split>(9) NE 'filename*'.
                long_filename = replace( val  = <lt_split>+9
                                         pcre = `\"`
                                         with = ``
                                         occ  = 0 ).
                CALL METHOD zcl_dingtalk=>split_filename
                  EXPORTING
                    long_filename  = long_filename
                  IMPORTING
                    pure_filename  = pure_filename
                    pure_extension = pure_extension.

                CASE pure_extension.
                  WHEN 'rar'.
                    lv_content_type = 'application/x-rar-compressed'.
                  WHEN 'pdf'.
                    lv_content_type = 'application/pdf'.
                  WHEN 'zip'.
                    lv_content_type = 'application/zip'.
                  WHEN 'pptx'.
                    lv_content_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'.
                  WHEN 'ppt'.
                    lv_content_type = 'application/vnd.ms-powerpoint'.
                  WHEN 'xlsx'.
                    lv_content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
                  WHEN 'xls'.
                    lv_content_type = 'application/vnd.ms-excel'.
                  WHEN 'docx'.
                    lv_content_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'.
                  WHEN 'doc'.
                    lv_content_type = 'application/msword'.
                  WHEN 'mp4'.
                    lv_content_type = 'video/mp4'.
                  WHEN 'wav'.
                    lv_content_type = 'audio/wav'.
                  WHEN 'mp3'.
                    lv_content_type = 'audio/mpeg'.
                  WHEN 'amr'.
                    lv_content_type = 'audio/amr'.
                  WHEN 'bmp'.
                    lv_content_type = 'image/bmp'.
                  WHEN 'gif'.
                    lv_content_type = 'image/gif'.
                  WHEN 'jpg'.
                    lv_content_type = 'image/jpeg'.
                  WHEN 'png'.
                    lv_content_type = 'image/png'.
                  WHEN 'txt'.
                    lv_content_type = 'text/plain'.
                ENDCASE.
                http_entity->set_content_type( lv_content_type ).
                http_entity->set_header_field( name = name value = value ).
                length = xstrlen( xdata ).
                http_entity->set_data( data = xdata offset = 0 length = length ).
              ENDIF.
            ENDLOOP.
          WHEN OTHERS.
            http_object->request->set_header_field( name = name value = value ).
        ENDCASE.
      ENDIF.
      UNASSIGN:<fs_name>,<fs_value>,<fs_cdata>,<fs_xdata>.
    ENDLOOP.
    CLEAR:name,value,cdata,xdata.

*输入发送数据
    IF input IS NOT INITIAL.
      CALL METHOD http_object->request->set_cdata
        EXPORTING
          data   = input
          offset = 0
          length = length.
    ENDIF.


*发送HTTP请求
    CALL METHOD http_object->send
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        OTHERS                     = 3.
    IF sy-subrc NE 0.
      http_object->get_last_error( IMPORTING message = message ).
      rtmsg = message.
      http_object->close( ).
      RETURN.
    ENDIF.
*接收返回消息
    CALL METHOD http_object->receive
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc NE 0.
      http_object->get_last_error( IMPORTING message = message ).
      rtmsg = message.
      http_object->close( ).
      RETURN.
    ENDIF.
*获取结果
    CLEAR:length.
    CALL METHOD http_object->response->get_status
      IMPORTING
        code   = length
        reason = message.
    rtmsg = message.
    status = length.
*获取返回
    CALL METHOD http_object->response->get_header_fields
      CHANGING
        fields = fields.
    name = http_object->response->get_cdata( ).
    IF sy-subrc NE 0.
      http_object->get_last_error( IMPORTING message = message ).
      rtmsg = message.
      http_object->close( ).
      RETURN.
    ENDIF.
    value = http_object->response->get_data( ).
* 将返回参数的回车转换，否则回车会在SAP变成'#'
*  REPLACE ALL OCCURRENCES OF REGEX '\n' IN name WITH ''.
*关闭HTTP连接

    http_object->close( ).

    output = name.

  ENDMETHOD.


  METHOD gettoken.
    TYPES: BEGIN OF t_JSON1,
             errcode      TYPE i,
             access_token TYPE string,
             errmsg       TYPE string,
             expires_in   TYPE i,
           END OF t_JSON1.
    DATA:wa_token TYPE t_JSON1.

    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA: minutes TYPE i.
    CHECK appid IS NOT INITIAL.
    SELECT SINGLE * FROM ztddconfig WHERE appid = @appid INTO @DATA(wa_conf).
    IF sy-subrc NE 0.
      rtype = 'E'.
      rtmsg = |获取access_token,请配置ztddconfig表appid:{ appid }信息|.
      RETURN.
    ELSE.
      IF wa_conf-appkey IS INITIAL OR wa_conf-appsecret IS INITIAL.
        rtype = 'E'.
        rtmsg = |获取access_token,请配置ztddconfig表appid:{ appid }的appkey和appsecret信息|.
        RETURN.
      ENDIF.
      agentid = wa_conf-agentid.
      IF wa_conf-token_date IS NOT INITIAL AND wa_conf-token_time IS NOT INITIAL "检验access_token有效性，避免重复获取
        AND wa_conf-expires_in IS NOT INITIAL AND wa_conf-access_token IS NOT INITIAL.
        CALL FUNCTION 'DELTA_TIME_DAY_HOUR'
          EXPORTING
            t1      = wa_conf-token_time
            t2      = sy-uzeit
            d1      = wa_conf-token_date
            d2      = sy-datum
          IMPORTING
            minutes = minutes.
*        access_token临到期前10秒更新  26.04.2024 11:03:26 by kkw
        IF ( minutes * 60 ) LT ( wa_conf-expires_in - 10 ).
          access_token = wa_conf-access_token.
          rtype = 'S'.
          rtmsg = |成功获取{ appname }的access_token缓存|.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.
    url = |{ get_token_url }?appkey={ wa_conf-appkey }&appsecret={ wa_conf-appsecret }|.
    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
*       input     =
        url       = url
*       username  =
*       password  =
        reqmethod = 'GET'
        http1_1   = 'X'
*       proxy     =
*       bodytype  = 'JSON'
*       header    =
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.

    IF status EQ 200.
      /ui2/cl_json=>deserialize( EXPORTING json = out_put  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_token ).
      IF wa_token-errcode EQ 0.
        rtype = 'S'.
        access_token = wa_token-access_token.
        UPDATE ztddconfig SET
          access_token = @wa_token-access_token,
          expires_in = @wa_token-expires_in,
          token_date = @sy-datum,
          token_time = @sy-uzeit
          WHERE appid = @appid.
        COMMIT WORK AND WAIT.
      ELSE.
        rtype = 'E'.
      ENDIF.
      rtmsg = |获取{ appname }的access_token返回信息:{ wa_token-errmsg }，状态码:{ status }|.
    ELSE.
      rtype = 'E'.
      rtmsg = |调用{ appname }的access_token发生了问题:{ otmsg }，状态码:{ status }|.
    ENDIF.

  ENDMETHOD.


  METHOD get_dept.
    " 传入json结构  26.04.2024 11:06:12 by kkw
    TYPES: BEGIN OF t_JSON1_in,
             language TYPE string,
             dept_id  TYPE ztddlistsub-dept_id,
           END OF t_JSON1_in.
    DATA:wa_in   TYPE t_JSON1_in,
         json_in TYPE string.
    " 返回json结构  26.04.2024 11:05:52 by kkw
    TYPES: BEGIN OF t_RESULT2,
             auto_add_user     TYPE abap_bool,
             create_dept_group TYPE abap_bool,
             dept_id           TYPE ztddlistsub-dept_id,
             ext               TYPE string,
             name              TYPE string,
             parent_id         TYPE ztddlistsub-parent_id,
           END OF t_RESULT2.
    TYPES: tt_RESULT2 TYPE STANDARD TABLE OF t_RESULT2 WITH DEFAULT KEY.
    TYPES: BEGIN OF t_JSON1,
             errcode    TYPE i,
             errmsg     TYPE string,
             result     TYPE tt_RESULT2,
             request_id TYPE string,
           END OF t_JSON1.
    DATA:wa_dept TYPE t_JSON1.

    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:access_token TYPE ztddconfig-access_token.

    CLEAR:rtype,rtmsg,gt_ztddlistsub.
*    获取token  26.04.2024 11:11:45 by kkw
    CALL METHOD me->gettoken
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = access_token.
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    CLEAR:rtype,rtmsg,json_in,wa_in.
    url = |{ get_dept_url }?access_token={ access_token }|.
    wa_in-language = language.
    wa_in-dept_id = dept_id.
    json_in = /ui2/cl_json=>serialize( data = wa_in  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
*       header    =
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.

    IF status EQ 200.
      /ui2/cl_json=>deserialize( EXPORTING json = out_put  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_dept ).
      IF wa_dept-errcode EQ 0.
        LOOP AT wa_dept-result ASSIGNING FIELD-SYMBOL(<result>).
          IF NOT <result>-dept_id IS INITIAL.
            INSERT INITIAL LINE INTO TABLE gt_ztddlistsub ASSIGNING FIELD-SYMBOL(<gt_ztddlistsub>).
            <gt_ztddlistsub>-dept_id = <result>-dept_id.
            <gt_ztddlistsub>-name = <result>-name.
            <gt_ztddlistsub>-parent_id = <result>-parent_id.
          ENDIF.
        ENDLOOP.
        IF gt_ztddlistsub IS INITIAL.
          rtype = 'W'.
        ELSE.
          rtype = 'S'.
        ENDIF.
      ELSE.
        rtype = 'E'.
      ENDIF.
      rtmsg = |调用appname:{ appname }获取部门:{ dept_id }列表返回信息:{ wa_dept-errmsg },errcode:{ wa_dept-errcode },状态码:{ status }|.
    ELSE.
      rtype = 'E'.
      rtmsg = |调用appname:{ appname }获取部门:{ dept_id }列表发生了问题:{ otmsg },状态码:{ status }|.
    ENDIF.

  ENDMETHOD.


  METHOD get_userinfo.
    " 传入json结构
    TYPES: BEGIN OF t_JSON1_in,
             language TYPE string,
             userid   TYPE ztdduser-userid,
           END OF t_JSON1_in.
    DATA:wa_in   TYPE t_JSON1_in,
         json_in TYPE string.
    " 返回json结构
    TYPES: BEGIN OF t_UNION_EMP_MAP_LIST6,
             userid  TYPE string,
             corp_id TYPE string,
           END OF t_UNION_EMP_MAP_LIST6.
    TYPES: t_DEPT_ID_LIST4 TYPE ztdduser-dept_id.
    TYPES: BEGIN OF t_ROLE_LIST2,
             group_name TYPE string,
             name       TYPE string,
             id         TYPE string,
           END OF t_ROLE_LIST2.
    TYPES: BEGIN OF t_UNION_EMP_EXT7,
             union_emp_map_list TYPE t_UNION_EMP_MAP_LIST6,
             userid             TYPE string,
             corp_id            TYPE string,
           END OF t_UNION_EMP_EXT7.
    TYPES: BEGIN OF t_LEADER_IN_DEPT5,
             leader  TYPE string,
             dept_id TYPE string,
           END OF t_LEADER_IN_DEPT5.
    TYPES: BEGIN OF t_DEPT_ORDER_LIST3,
             dept_id TYPE string,
             order   TYPE string,
           END OF t_DEPT_ORDER_LIST3.
    TYPES: tt_DEPT_ID_LIST4 TYPE STANDARD TABLE OF t_DEPT_ID_LIST4 WITH DEFAULT KEY.
    TYPES: BEGIN OF t_RESULT8,
             extension         TYPE string,
             unionid           TYPE string,
             boss              TYPE string,
             role_list         TYPE t_ROLE_LIST2,
             exclusive_account TYPE abap_bool,
             manager_userid    TYPE string,
             admin             TYPE string,
             remark            TYPE string,
             title             TYPE string,
             hired_date        TYPE string,
             userid            TYPE string,
             work_place        TYPE string,
             dept_order_list   TYPE t_DEPT_ORDER_LIST3,
             real_authed       TYPE string,
             dept_id_list      TYPE tt_DEPT_ID_LIST4,
             job_number        TYPE string,
             email             TYPE string,
             leader_in_dept    TYPE t_LEADER_IN_DEPT5,
             mobile            TYPE string,
             active            TYPE string,
             org_email         TYPE string,
             telephone         TYPE string,
             avatar            TYPE string,
             hide_mobile       TYPE string,
             senior            TYPE string,
             name              TYPE string,
             union_emp_ext     TYPE t_UNION_EMP_EXT7,
             state_code        TYPE string,
           END OF t_RESULT8.
    TYPES: BEGIN OF t_JSON1,
             errcode TYPE string,
             result  TYPE t_RESULT8,
             errmsg  TYPE string,
           END OF t_JSON1.
    DATA:wa_userinfo TYPE t_JSON1.
    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:access_token TYPE ztddconfig-access_token.

    CLEAR:rtype,rtmsg.
*    获取token
    CALL METHOD me->gettoken
*      EXPORTING
*        appid        = appid
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = access_token.
    IF rtype NE 'S'.
      RETURN.
    ENDIF.

    url = |{ get_user_url }?access_token={ access_token }|.
    wa_in-language = language.
    wa_in-userid = userid.
    json_in = /ui2/cl_json=>serialize( data = wa_in  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
*       header    =
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.

    IF status EQ 200.
      /ui2/cl_json=>deserialize( EXPORTING json = out_put pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_userinfo ).
      IF wa_userinfo-errcode EQ 0.
        rtype = 'S'.
        CLEAR:gt_ztdduser.
        LOOP AT wa_userinfo-result-dept_id_list ASSIGNING FIELD-SYMBOL(<dept_id_list>).
          INSERT INITIAL LINE INTO TABLE gt_ztdduser ASSIGNING FIELD-SYMBOL(<gt_ztdduser>).
          <gt_ztdduser>-dept_id = <dept_id_list>.
          <gt_ztdduser>-userid = wa_userinfo-result-userid.
          <gt_ztdduser>-job_number = wa_userinfo-result-job_number.
          <gt_ztdduser>-name = wa_userinfo-result-name.
          <gt_ztdduser>-mobile = wa_userinfo-result-mobile.
        ENDLOOP.
      ELSE.
        rtype = 'E'.
      ENDIF.
      rtmsg = |获取appname:{ appname }的员工:{ userid }详情返回信息:{ wa_userinfo-errmsg },errcode:{ wa_userinfo-errcode },状态码:{ status }|.
    ELSE.
      rtype = 'E'.
      rtmsg = |获取appname:{ appname }的员工:{ userid }详情发生了问题:{ otmsg },状态码:{ status }|.
    ENDIF.

  ENDMETHOD.


  METHOD get_userlist.
    " 传入json结构
    TYPES: BEGIN OF t_JSON1_in,
             dept_id TYPE ztddlistsub-dept_id,
           END OF t_JSON1_in.
    DATA:wa_in   TYPE t_JSON1_in,
         json_in TYPE string.
    " 返回json结构
    TYPES: t_USERID_LIST2 TYPE ztdduser-userid.
    TYPES: tt_USERID_LIST2 TYPE STANDARD TABLE OF t_USERID_LIST2 WITH DEFAULT KEY.
    TYPES: BEGIN OF t_RESULT3,
             userid_list TYPE tt_USERID_LIST2,
           END OF t_RESULT3.
    TYPES: BEGIN OF t_JSON1,
             errcode    TYPE i,
             errmsg     TYPE string,
             result     TYPE t_RESULT3,
             request_id TYPE string,
           END OF t_JSON1.
    DATA:wa_userlist TYPE t_JSON1.
    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:access_token TYPE ztddconfig-access_token.

    CLEAR:rtype,rtmsg,gt_userlist.
*    获取token
    CALL METHOD me->gettoken
*      EXPORTING
*        appid        = appid
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = access_token.
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    CLEAR:rtype,rtmsg,json_in,wa_in.
    url = |{ get_userlist_url }?access_token={ access_token }|.
    wa_in-dept_id = dept_id.
    json_in = /ui2/cl_json=>serialize( data = wa_in  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
*       header    =
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.
    IF status EQ 200.
      /ui2/cl_json=>deserialize( EXPORTING json = out_put  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_userlist ).
      IF wa_userlist-errcode EQ 0.
        rtype = 'S'.
        APPEND LINES OF wa_userlist-result-userid_list TO gt_userlist.
      ELSE.
        rtype = 'E'.
      ENDIF.
      rtmsg = |调用appname:{ appname }的部门:{ dept_id }用户列表返回信息:{ wa_userlist-errmsg }，errcode:{ wa_userlist-errcode },状态码:{ status }|.
    ELSE.
      rtype = 'E'.
      rtmsg = |调用appname:{ appname }的部门:{ dept_id }用户列表发生了问题:{ otmsg },状态码:{ status }|.
    ENDIF.

  ENDMETHOD.


  METHOD post2corpconversation.
*    传入结构  27.04.2024 11:24:57 by kkw
    TYPES: BEGIN OF t_RICH7,
             unit TYPE string,
             num  TYPE string,
           END OF t_RICH7.
    TYPES: BEGIN OF t_FORM6,
             value TYPE string,
             key   TYPE string,
           END OF t_FORM6.
    TYPES: BEGIN OF t_STATUS_BAR5,
             status_value TYPE string,
             status_bg    TYPE string,
           END OF t_STATUS_BAR5.
    TYPES: BEGIN OF t_HEAD4,
             bgcolor TYPE string,
             text    TYPE string,
           END OF t_HEAD4.
    TYPES: BEGIN OF t_BODY8,
             file_count TYPE string,
             image      TYPE string,
             form       TYPE t_FORM6,
             author     TYPE string,
             rich       TYPE t_RICH7,
             title      TYPE string,
             content    TYPE string,
           END OF t_BODY8.
    TYPES: BEGIN OF t_BTN_JSON_LIST11,
             action_url TYPE string,
             title      TYPE string,
           END OF t_BTN_JSON_LIST11.
    TYPES: BEGIN OF t_ACTION_CARD12,
             btn_json_list   TYPE t_BTN_JSON_LIST11,
             single_url      TYPE string,
             btn_orientation TYPE string,
             single_title    TYPE string,
             markdown        TYPE string,
             title           TYPE string,
           END OF t_ACTION_CARD12.
    TYPES: BEGIN OF t_IMAGE3,
             media_id TYPE string,
           END OF t_IMAGE3.
    TYPES: BEGIN OF t_OA9,
             head           TYPE t_HEAD4,
             pc_message_url TYPE string,
             status_bar     TYPE t_STATUS_BAR5,
             body           TYPE t_BODY8,
             message_url    TYPE string,
           END OF t_OA9.
    TYPES: BEGIN OF t_VOICE2,
             duration TYPE string,
             media_id TYPE string,
           END OF t_VOICE2.
    TYPES: BEGIN OF t_LINK13,
             pic_url     TYPE string,
             message_url TYPE string,
             text        TYPE string,
             title       TYPE string,
           END OF t_LINK13.
    TYPES: BEGIN OF t_FILE10,
             media_id TYPE string,
           END OF t_FILE10.
    TYPES: BEGIN OF t_MARKDOWN14,
             text  TYPE string,
             title TYPE string,
           END OF t_MARKDOWN14.
    TYPES: BEGIN OF t_TEXT15,
             content TYPE string,
           END OF t_TEXT15.
    TYPES: t_DEPT_ID_LIST17 TYPE ztddlistsub-dept_id.
    TYPES: t_USERID_LIST18 TYPE ztdduser-userid.
    TYPES: BEGIN OF t_MSG16,
             voice       TYPE t_VOICE2,
             image       TYPE t_IMAGE3,
             oa          TYPE t_OA9,
             file        TYPE t_FILE10,
             action_card TYPE t_ACTION_CARD12,
             link        TYPE t_LINK13,
             markdown    TYPE t_MARKDOWN14,
             text        TYPE t_TEXT15,
             msgtype     TYPE string,
           END OF t_MSG16.
    TYPES: tt_DEPT_ID_LIST17 TYPE STANDARD TABLE OF t_DEPT_ID_LIST17 WITH DEFAULT KEY.
    TYPES: tt_USERID_LIST18 TYPE STANDARD TABLE OF t_USERID_LIST18 WITH DEFAULT KEY.
    TYPES: BEGIN OF t_JSON1_in,
             msg         TYPE t_MSG16,
             to_all_user TYPE abap_bool,
             agent_id    TYPE ztddconfig-agentid,
*             dept_id_list TYPE string, "tt_DEPT_ID_LIST17,
             userid_list TYPE string, "tt_USERID_LIST18,
           END OF t_JSON1_in.
    DATA:wa_in   TYPE t_JSON1_in,
         json_in TYPE string.
*    传出结构  27.04.2024 11:24:57 by kkw
    TYPES: BEGIN OF t_JSON1,
             errcode    TYPE i,
             errmsg     TYPE string,
             task_id    TYPE p LENGTH 16 DECIMALS 0,
             request_id TYPE string,
           END OF t_JSON1.
    DATA:wa_out TYPE t_JSON1.

    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:access_token TYPE ztddconfig-access_token.
    CLEAR:rtype,rtmsg.
    CASE msgtype.
      WHEN 'text'.
        IF text IS INITIAL.
          rtype = 'E'.
          rtmsg = |消息类型{ msgtype }的text不能为空|.
          me->my_logger->e( obj_to_log = rtmsg ) .
          RETURN.
        ENDIF.
        wa_in-msg-text-content = text.
      WHEN 'markdown'.
        IF text IS INITIAL OR title IS INITIAL.
          rtype = 'E'.
          rtmsg = |消息类型{ msgtype }的title和text均不能为空|.
          me->my_logger->e( obj_to_log = rtmsg ) .
          RETURN.
        ENDIF.
        wa_in-msg-markdown-title = title.
        wa_in-msg-markdown-text = text.
      WHEN 'file'.
        wa_in-msg-file-media_id = media_id.
      WHEN 'image'.
        wa_in-msg-image-media_id = media_id.
      WHEN 'voice'.
        wa_in-msg-voice-media_id = media_id.
        wa_in-msg-voice-duration = duration.
      WHEN OTHERS.
        rtype = 'E'.
        rtmsg = |当前版本尚未添加对消息类型{ msgtype }的支持|.
        me->my_logger->e( obj_to_log = rtmsg ) .
        RETURN.
    ENDCASE.
*    获取token  26.04.2024 11:11:45 by kkw
    CALL METHOD me->gettoken
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = access_token
        agentid      = wa_in-agent_id.
    me->my_logger->i( obj_to_log = rtmsg ) .
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    url = |{ corpconversation_url }?access_token={ access_token }|.
    wa_in-to_all_user = abap_false.
    wa_in-msg-msgtype = msgtype.
*    APPEND userid TO wa_in-userid_list.
    wa_in-userid_list = userid.

    json_in = /ui2/cl_json=>serialize( data = wa_in  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
*       header    =
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.
    IF status EQ 200.
      /ui2/cl_json=>deserialize( EXPORTING json = out_put pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_out ).
      rtmsg = |调用工作通知:{ appname }发送消息返回信息:errcode:{ wa_out-errcode },errmsg:{ wa_out-errmsg },task_id:{ wa_out-task_id },request_id:{ wa_out-request_id },状态码:{ status }|.
      IF wa_out-errcode EQ 0.
        rtype = 'S'.
        me->my_logger->s( obj_to_log = rtmsg ) .
      ELSE.
        rtype = 'E'.
        me->my_logger->e( obj_to_log = rtmsg ) .
      ENDIF.
    ELSE.
      rtype = 'E'.
      rtmsg = |调用工作通知:{ appname }发送消息发生了问题:{ otmsg },状态码:{ status }|.
      me->my_logger->e( obj_to_log = rtmsg ) .
    ENDIF.

  ENDMETHOD.


  METHOD post2ddrobot.
*    传入结构
    TYPES: t_AT_MOBILES2 TYPE string.
    TYPES: t_AT_USER_IDS3 TYPE string.
    TYPES: BEGIN OF t_LINKS10,
             title       TYPE string,
             message_url TYPE string,
             pic_url     TYPE string,
           END OF t_LINKS10.
    TYPES: BEGIN OF t_BTNS8,
             title      TYPE string,
             action_url TYPE string,
           END OF t_BTNS8.
    TYPES: tt_AT_USER_IDS3 TYPE STANDARD TABLE OF t_AT_USER_IDS3 WITH DEFAULT KEY.
    TYPES: tt_BTNS8 TYPE STANDARD TABLE OF t_BTNS8 WITH DEFAULT KEY.
    TYPES: tt_AT_MOBILES2 TYPE STANDARD TABLE OF t_AT_MOBILES2 WITH DEFAULT KEY.
    TYPES: tt_LINKS10 TYPE STANDARD TABLE OF t_LINKS10 WITH DEFAULT KEY.
    TYPES: BEGIN OF t_FEED_CARD11,
             links TYPE tt_LINKS10,
           END OF t_FEED_CARD11.
    TYPES: BEGIN OF t_ACTION_CARD9,
             title           TYPE string,
             text            TYPE string,
             btn_orientation TYPE string,
             single_title    TYPE string,
             single_url      TYPE string,
             btns            TYPE tt_BTNS8,
           END OF t_ACTION_CARD9.
    TYPES: BEGIN OF t_MARKDOWN7,
             title TYPE string,
             text  TYPE string,
           END OF t_MARKDOWN7.
    TYPES: BEGIN OF t_LINK6,
             text        TYPE string,
             title       TYPE string,
             pic_url     TYPE string,
             message_url TYPE string,
           END OF t_LINK6.
    TYPES: BEGIN OF t_TEXT5,
             content TYPE string,
           END OF t_TEXT5.
    TYPES: BEGIN OF t_AT4,
             at_mobiles  TYPE tt_AT_MOBILES2,
             at_user_ids TYPE tt_AT_USER_IDS3,
             is_at_all   TYPE abap_bool,
           END OF t_AT4.
    TYPES: BEGIN OF t_JSON1_in,
             at          TYPE t_AT4,
             text        TYPE t_TEXT5,
             link        TYPE t_LINK6,
             markdown    TYPE t_MARKDOWN7,
             action_card TYPE t_ACTION_CARD9,
             feed_card   TYPE t_FEED_CARD11,
             msgtype     TYPE string,
           END OF t_JSON1_in.
    DATA:wa_in   TYPE t_JSON1_in,
         json_in TYPE string.
*    传出结构
    TYPES: BEGIN OF t_JSON1,
             errcode TYPE i,
             errmsg  TYPE string,
           END OF t_JSON1.
    DATA:wa_out TYPE t_JSON1.

    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:sign      TYPE string,
         timestamp TYPE string.

    wa_in-msgtype = msgtype.
    CASE msgtype.
      WHEN 'text'.
        IF text IS INITIAL.
          rtype = 'E'.
          rtmsg = |消息类型{ msgtype }的text不能为空|.
          me->my_logger->e( obj_to_log = rtmsg ) .
          RETURN.
        ENDIF.
        wa_in-text-content = text.
      WHEN 'markdown'.
        IF text IS INITIAL OR title IS INITIAL.
          rtype = 'E'.
          rtmsg = |消息类型{ msgtype }的title和text均不能为空|.
          me->my_logger->e( obj_to_log = rtmsg ) .
          RETURN.
        ENDIF.
        wa_in-markdown-title = title.
        wa_in-markdown-text = text.
      WHEN OTHERS.
        rtype = 'E'.
        rtmsg = |当前版本尚未添加对消息类型{ msgtype }的支持|.
        me->my_logger->e( obj_to_log = rtmsg ) .
        RETURN.
    ENDCASE.
    SELECT SINGLE * FROM ztddconfig WHERE appid = @appid INTO @DATA(wa_conf).
    IF sy-subrc NE 0.
      rtype = 'E'.
      rtmsg = |发送钉钉群机器人消息,请配置ztddconfig表appid:{ appid }信息|.
      me->my_logger->e( obj_to_log = rtmsg ) .
      RETURN.
    ELSE.
      IF wa_conf-webhook IS INITIAL OR wa_conf-secret IS INITIAL.
        rtype = 'E'.
        rtmsg = |发送钉钉群机器人消息,请配置ztddconfig表appid:{ appid }的webhook和secret信息|.
        me->my_logger->e( obj_to_log = rtmsg ) .
        RETURN.
      ENDIF.
    ENDIF.
*    获取签名
    CALL METHOD me->getsign
      EXPORTING
        secret    = wa_conf-secret
      IMPORTING
        sign      = sign
        timestamp = timestamp.
    IF sign IS INITIAL.
      rtype = 'E'.
      rtmsg = '获取签名失败'.
      me->my_logger->e( obj_to_log = rtmsg ) .
      RETURN.
    ENDIF.
    url = |{ wa_conf-webhook }&timestamp={ timestamp }&sign={ sign }|.
    json_in = /ui2/cl_json=>serialize( data = wa_in  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
*       header    =
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.

    IF status EQ 200.
      /ui2/cl_json=>deserialize( EXPORTING json = out_put  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_out ).
      rtmsg = |调用钉钉群机器人:{ appname }发送消息返回信息:errcode:{ wa_out-errcode },errmsg:{ wa_out-errmsg },状态码:{ status }|.
      IF wa_out-errcode EQ 0.
        rtype = 'S'.
        me->my_logger->s( obj_to_log = rtmsg ) .
      ELSE.
        rtype = 'E'.
        me->my_logger->e( obj_to_log = rtmsg ) .
      ENDIF.
    ELSE.
      rtype = 'E'.
      rtmsg = |调用钉钉群机器人:{ appname }发送消息发生了问题:{ otmsg },状态码:{ status }|.
      me->my_logger->e( obj_to_log = rtmsg ) .
    ENDIF.

  ENDMETHOD.


  METHOD constructor.
    me->appid = appid.
    SELECT SINGLE name FROM ztddconfig WHERE appid = @appid INTO @me->appname.
    me->my_logger = zcl_logger_factory=>create_log(
                        object    = 'ZDINGTALK'
                        subobject = 'ZDT'
                        desc      = 'ZCL_DINGTALK'
                        settings = zcl_logger_factory=>create_settings( ) ) ##no_text.

  ENDMETHOD.


  METHOD getsign.
    DATA:if_data_s        TYPE string,
         if_data          TYPE xstring,
         if_secret        TYPE xstring,
         ef_hmacb64string TYPE string,
         stamp            TYPE timestampl,
         stamp_char       TYPE char22.
    CHECK secret IS NOT INITIAL.
    CLEAR:sign,timestamp.
    TRY.
        if_secret = cl_abap_hmac=>string_to_xstring( secret ).
      CATCH cx_abap_message_digest.
        EXIT.
    ENDTRY.
    DATA(newline) = cl_abap_char_utilities=>newline.
    GET TIME STAMP FIELD stamp.
    stamp_char = stamp.
    CALL METHOD cl_pco_utility=>convert_abap_timestamp_to_java
      EXPORTING
        iv_date      = CONV #( stamp_char(8) )
        iv_time      = CONV #( stamp_char+8(6) )
        iv_msec      = CONV #( stamp_char+15(3) )
      IMPORTING
        ev_timestamp = timestamp.
    if_data_s = |{ timestamp }{ newline }{ secret }|.
    TRY.
        if_data = cl_abap_hmac=>string_to_xstring( if_data_s ).
      CATCH cx_abap_message_digest.
        EXIT.
    ENDTRY.
    TRY.
        CALL METHOD cl_abap_hmac=>calculate_hmac_for_raw
          EXPORTING
            if_algorithm     = 'SHA256'
            if_key           = if_secret
            if_data          = if_data
*           if_length        = 0
          IMPORTING
*           ef_hmacstring    = ef_hmacstring
*           ef_hmacxstring   = ef_hmacxstring
            ef_hmacb64string = ef_hmacb64string.
        .
      CATCH cx_abap_message_digest.
        EXIT.
    ENDTRY.
    sign = cl_http_utility=>escape_url( ef_hmacb64string ).
  ENDMETHOD.


  METHOD get_deptsuball.
    DATA:lt_tab TYPE TABLE OF ztddlistsub.
    DATA:lt_tab_sub TYPE TABLE OF ztddlistsub.
    CHECK ztddlistsub_in IS NOT INITIAL.
    CASE action.
      WHEN 'GET'.
        SELECT
          *
          FROM ztddlistsub
          FOR ALL ENTRIES IN @ztddlistsub_in
          WHERE parent_id = @ztddlistsub_in-dept_id
          AND dept_id IS NOT INITIAL
          APPENDING TABLE @lt_tab
          .
        CHECK lt_tab IS NOT INITIAL.
        APPEND LINES OF lt_tab TO ztddlistsub_out.
        CALL METHOD me->get_deptsuball
          EXPORTING
            ztddlistsub_in  = lt_tab
          IMPORTING
            ztddlistsub_out = ztddlistsub_out.
      WHEN 'UPD'.
        LOOP AT ztddlistsub_in ASSIGNING FIELD-SYMBOL(<ztddlistsub_in>).
          CLEAR:lt_tab.
          CALL METHOD me->get_dept
            EXPORTING
              dept_id        = <ztddlistsub_in>-dept_id
*             language       = 'zh_CN'
            IMPORTING
*             rtype          =
*             rtmsg          =
              gt_ztddlistsub = lt_tab.
          IF lt_tab IS NOT INITIAL.
            APPEND LINES OF lt_tab TO ztddlistsub_out.
            CLEAR:lt_tab_sub.
            CALL METHOD me->get_deptsuball
              EXPORTING
                ztddlistsub_in  = lt_tab
                action          = 'UPD'
              IMPORTING
                ztddlistsub_out = lt_tab_sub.
            IF lt_tab_sub IS NOT INITIAL.
              APPEND LINES OF lt_tab_sub TO ztddlistsub_out.
            ENDIF.
          ENDIF.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.


  METHOD init_dept.
    DATA:gt_ztddlistsub_sub TYPE TABLE OF ztddlistsub,
         gt_ztddlistsub     TYPE TABLE OF ztddlistsub.

    CLEAR:rtype,rtmsg,gt_ztddlistsub_total.
    CALL METHOD me->get_dept
      EXPORTING
        dept_id        = dept_id
*       language       = 'zh_CN'
      IMPORTING
        rtype          = rtype
        rtmsg          = rtmsg
        gt_ztddlistsub = gt_ztddlistsub.
    me->my_logger->i( obj_to_log = rtmsg ) .
    CHECK rtype = 'S'.

    APPEND LINES OF gt_ztddlistsub TO gt_ztddlistsub_total.
*    循环获取所有下级部门列表  26.04.2024 10:40:31 by kkw
    CALL METHOD me->get_deptsuball
      EXPORTING
        ztddlistsub_in  = gt_ztddlistsub
        action          = 'UPD'
      IMPORTING
        ztddlistsub_out = gt_ztddlistsub_sub.
    " 子部门也可能会有子部门，这部分也得获取到  03.06.2024 16:22:37 by kkw

    IF gt_ztddlistsub_sub IS NOT INITIAL.
      APPEND LINES OF gt_ztddlistsub_sub TO gt_ztddlistsub_total.
    ENDIF.
    IF init_all = 'X'.
      DELETE FROM ztddlistsub.
      COMMIT WORK AND WAIT.
      me->my_logger->s( obj_to_log = |清空ztddlistsub底表数据成功| ) .
    ENDIF.
    MODIFY ztddlistsub FROM TABLE gt_ztddlistsub_total.
    IF sy-subrc EQ 0.
      COMMIT WORK AND WAIT.
      rtype = 'S'.
      rtmsg = |初始化appname:{ appname }的部门:{ dept_id }列表成功，数据已存储在ZTDDLISTSUB表中|.
      me->my_logger->s( obj_to_log = rtmsg ) .
    ELSE.
      ROLLBACK WORK.
      rtype = 'E'.
      rtmsg = |初始化appname:{ appname }的部门:{ dept_id }列表失败|.
      me->my_logger->e( obj_to_log = rtmsg ) .
    ENDIF.

  ENDMETHOD.


  METHOD init_user.
    DATA:lt_ztddlistsub  TYPE TABLE OF ztddlistsub,
         lt_xmd          TYPE TABLE OF ztddlistsub,
         gt_userlist     TYPE TABLE OF ztdduser-userid,
         gt_userlist_all LIKE gt_userlist,
         gt_ztdduser     TYPE TABLE OF ztdduser,
         gt_ztdduser_all TYPE TABLE OF ztdduser.

    SELECT
      *
      FROM ztddlistsub
      WHERE dept_id = @dept_id
      INTO TABLE @lt_xmd
      .
    IF lt_xmd IS INITIAL.
      rtype = 'E'.
      rtmsg = |表ZTDDLISTSUB未获取到DEPT_ID为{ dept_id }的数据，获取部门列表后再试|.
      me->my_logger->e( obj_to_log = rtmsg ) .
      RETURN.
    ENDIF.

*    获取子部门列表信息
    SELECT
      *
      FROM ztddlistsub
      WHERE parent_id = @dept_id
      INTO TABLE @lt_ztddlistsub
      .
    APPEND LINES OF lt_ztddlistsub TO lt_xmd.
    CALL METHOD me->get_deptsuball
      EXPORTING
        ztddlistsub_in  = lt_ztddlistsub
      IMPORTING
        ztddlistsub_out = lt_xmd.
*    循环部门列表信息获取用户列表信息
    CLEAR:gt_userlist_all.
    LOOP AT lt_xmd ASSIGNING FIELD-SYMBOL(<lt_xmd>).
      CLEAR:gt_userlist.
      CALL METHOD me->get_userlist
        EXPORTING
          dept_id     = <lt_xmd>-dept_id
        IMPORTING
*         rtype       =
*         rtmsg       =
          gt_userlist = gt_userlist.
      APPEND LINES OF gt_userlist TO gt_userlist_all.
    ENDLOOP.
*    获取用户详情
    SORT gt_userlist_all.
    DELETE ADJACENT DUPLICATES FROM gt_userlist_all COMPARING ALL FIELDS.
    LOOP AT gt_userlist_all ASSIGNING FIELD-SYMBOL(<gt_userlist_all>).
      IF <gt_userlist_all> IS NOT INITIAL.
        CALL METHOD me->get_userinfo
          EXPORTING
*           language    = 'zh_CN'
            userid      = <gt_userlist_all>
          IMPORTING
*           rtype       =
*           rtmsg       =
            gt_ztdduser = gt_ztdduser.

        APPEND LINES OF gt_ztdduser TO gt_ztdduser_all.
      ENDIF.
    ENDLOOP.
    DELETE gt_ztdduser_all WHERE userid IS INITIAL.
    IF gt_ztdduser_all IS INITIAL.
      rtype = 'W'.
      rtmsg = '无数据'.
      me->my_logger->w( obj_to_log = rtmsg ) .
      RETURN.
    ENDIF.
    IF init_all = 'X'.
      DELETE FROM ztdduser.
      COMMIT WORK AND WAIT.
      me->my_logger->s( obj_to_log = |清空ztdduser底表数据成功| ) .
    ENDIF.
    MODIFY ztdduser FROM TABLE gt_ztdduser_all.
    IF sy-subrc EQ 0.
      COMMIT WORK AND WAIT.
      rtype = 'S'.
      rtmsg = |初始化appname:{ appname }的部门:{ dept_id }员工列表成功，数据已存储在ZTDDUSER表中|.
      me->my_logger->s( obj_to_log = rtmsg ) .
    ELSE.
      ROLLBACK WORK.
      rtype = 'E'.
      rtmsg = |初始化appname:{ appname }的部门:{ dept_id }员工列表失败|.
      me->my_logger->e( obj_to_log = rtmsg ) .
    ENDIF.

  ENDMETHOD.


  METHOD upload_media.
    " 返回json结构
    TYPES: BEGIN OF t_JSON1,
             errcode    TYPE i,
             errmsg     TYPE string,
             media_id   TYPE string,
             created_at TYPE p LENGTH 16 DECIMALS 0,
             type       TYPE string,
           END OF t_JSON1.
    DATA:wa_out TYPE t_JSON1.
    TYPES: BEGIN OF t_RESPONSE_TEXT2,
             errcode    TYPE i,
             errmsg     TYPE string,
             media_id   TYPE string,
             created_at TYPE p LENGTH 16 DECIMALS 0,
             type       TYPE string,
           END OF t_RESPONSE_TEXT2.
    TYPES: BEGIN OF t_JSON1_fastapi,
             status_code   TYPE i,
             response_text TYPE t_RESPONSE_TEXT2,
           END OF t_JSON1_fastapi.
    DATA:wa_out_fastapi TYPE t_JSON1_fastapi.
    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:access_token TYPE ztddconfig-access_token.
    LOOP AT header ASSIGNING FIELD-SYMBOL(<header>).
      ASSIGN COMPONENT 'XDATA' OF STRUCTURE <header> TO FIELD-SYMBOL(<xdata>).
      IF <xdata> IS NOT ASSIGNED.
        rtype = 'E'.
        rtmsg = |header内表缺失'XDATA'字段|.
        me->my_logger->e( obj_to_log = rtmsg ) .
        RETURN.
      ENDIF.
      IF xstrlen( <xdata> ) GT maxlength.
        rtype = 'E'.
        rtmsg = |钉钉要求媒体文件最大不能超过{ maxlength / 1048576 }MB，当前大小为{ xstrlen( <xdata> ) / 1048576 }MB|.
        me->my_logger->e( obj_to_log = rtmsg ) .
        RETURN.
      ENDIF.
    ENDLOOP.

    CLEAR:rtype,rtmsg.
*    获取token  26.04.2024 11:11:45 by kkw
    CALL METHOD me->gettoken
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = access_token.
    me->my_logger->i( obj_to_log = rtmsg ) .
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    CASE via.
      WHEN 'INS'.
        url = |{ upload_media_url }?access_token={ access_token }&type={ type }|.
      WHEN 'FASTAPI'.
*        url = |{ upload_media_viafastapi_url }|.
        SELECT SINGLE jz
          INTO @DATA(uurl)
          FROM ztsap_pubdata
          WHERE zj = 'UPLOAD_MEDIA_VIAFASTAPI_URL'
          AND   sxbs NE 'X'.
        url = uurl.
        IF url IS INITIAL.
          rtype = 'E'.
          rtmsg = |调用appname:{ appname }上传媒体文件发生了问题:FastAPI转发方式需要配置zmm000-SAP程序默认值配置-主键'UPLOAD_MEDIA_VIAFASTAPI_URL'的键值|.
          me->my_logger->e( obj_to_log = rtmsg ) .
          RETURN.
        ENDIF.
        INSERT INITIAL LINE INTO TABLE header ASSIGNING <header>.
        ASSIGN COMPONENT 'NAME' OF STRUCTURE <header> TO FIELD-SYMBOL(<name>).
        IF sy-subrc EQ 0.
          <name> = 'Content-Disposition'.
        ENDIF.
        ASSIGN COMPONENT 'VALUE' OF STRUCTURE <header> TO FIELD-SYMBOL(<value>).
        IF sy-subrc EQ 0.
          <value> = |form-data; name="access_token"|.
        ENDIF.
        ASSIGN COMPONENT 'CDATA' OF STRUCTURE <header> TO FIELD-SYMBOL(<cdata>).
        IF sy-subrc EQ 0.
          <cdata> = access_token.
        ENDIF.
    ENDCASE.
    CALL METHOD zcl_dingtalk=>create_http_client
*    CALL METHOD zcl_dingtalk=>create_http_client_rest
      EXPORTING
*       input     =
        url       = url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
        bodytype  = 'FORM-DATA'
        header    = header
      IMPORTING
        output    = out_put
        rtmsg     = otmsg
        status    = status.
    CASE via.
      WHEN 'INS'.
        IF status EQ 200.
          /ui2/cl_json=>deserialize( EXPORTING json = out_put pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_out ).
          rtmsg = |调用appname:{ appname }上传媒体文件返回信息:{ wa_out-errmsg },errcode:{ wa_out-errcode },media_id:{ wa_out-media_id },状态码:{ status }|.
          IF wa_out-errcode EQ 0.
            rtype = 'S'.
            media_id = wa_out-media_id.
            me->my_logger->s( obj_to_log = rtmsg ) .
          ELSE.
            rtype = 'E'.
            me->my_logger->e( obj_to_log = rtmsg ) .
          ENDIF.
        ELSE.
          rtype = 'E'.
          rtmsg = |调用appname:{ appname }上传媒体文件发生了问题:{ otmsg },状态码:{ status }|.
          me->my_logger->e( obj_to_log = rtmsg ) .
        ENDIF.
      WHEN 'FASTAPI'.
        IF status EQ 200.
          /ui2/cl_json=>deserialize( EXPORTING json = out_put pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_out_fastapi ).
          rtmsg = |调用appname:{ appname }上传媒体文件(FastAPI)返回信息:{ wa_out_fastapi-response_text-errmsg },errcode:{ wa_out_fastapi-response_text-errcode },|
                   && |media_id:{ wa_out_fastapi-response_text-media_id },状态码:{ wa_out_fastapi-status_code }|.
          IF wa_out_fastapi-response_text-errcode EQ 0.
            rtype = 'S'.
            media_id = wa_out_fastapi-response_text-media_id.
            me->my_logger->s( obj_to_log = rtmsg ) .
          ELSE.
            rtype = 'E'.
            me->my_logger->e( obj_to_log = rtmsg ) .
          ENDIF.
        ELSE.
          rtype = 'E'.
          rtmsg = |调用appname:{ appname }上传媒体文件(FastAPI)发生了问题:{ otmsg },状态码:{ status }|.
          me->my_logger->e( obj_to_log = rtmsg ) .
        ENDIF.
    ENDCASE.
  ENDMETHOD.


  METHOD CREATE_EXCEL.
    DATA: cl_writer TYPE REF TO zif_excel_writer,
          cl_error  TYPE REF TO zcx_excel.
    DATA: lo_excel     TYPE REF TO zcl_excel,
          lo_worksheet TYPE REF TO zcl_excel_worksheet.
    DATA:ls_table_settings TYPE zexcel_s_table_settings.
    DATA:lv_count TYPE i,
         l_col    TYPE zexcel_cell_column_alpha.
    IF gt_exceltab IS INITIAL.
      RETURN.
    ENDIF.
    " 生成excel的xstring  29.04.2024 16:10:41 by kkw
    TRY.
        CREATE OBJECT cl_writer TYPE zcl_excel_writer_2007.
        " Creates active sheet
        CREATE OBJECT lo_excel.

        LOOP AT gt_exceltab ASSIGNING FIELD-SYMBOL(<gt_exceltab>).
          CLEAR:lo_worksheet,ls_table_settings.
          ASSIGN <gt_exceltab>-excel_tabdref->* TO FIELD-SYMBOL(<tab>).
          IF <tab> IS NOT ASSIGNED.
            CONTINUE.
          ENDIF.
          IF sy-tabix = 1.
            " Get active sheet
            lo_worksheet = lo_excel->get_active_worksheet( ).
          ELSE.
            " Add another table
            lo_worksheet = lo_excel->add_new_worksheet( ).
          ENDIF.
          lo_worksheet->set_title( <gt_exceltab>-excel_sheetname ).
          IF <gt_exceltab>-excel_fieldcat IS INITIAL.
            <gt_exceltab>-excel_fieldcat = zcl_excel_common=>get_fieldcatalog( ip_table = <tab> ).
          ENDIF.
          ls_table_settings-table_style  = zcl_excel_table=>builtinstyle_medium5.

          lo_worksheet->bind_table( ip_table          = <tab>
                                    is_table_settings = ls_table_settings
                                    it_field_catalog  = <gt_exceltab>-excel_fieldcat ).
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
        ENDLOOP.
        xstring_data = cl_writer->write_file( lo_excel ).
        FREE lo_excel.
      CATCH zcx_excel INTO cl_error.
        EXIT.
    ENDTRY.
  ENDMETHOD.


  METHOD SPLIT_FILENAME.
    DATA: len             TYPE i,
          len_f           TYPE i,
          pos             TYPE i,
          char            TYPE c,
          long_filename_f TYPE dbmsgora-filename.
    " 找扩展名  29.04.2024 19:56:14 by kkw
    len = strlen( long_filename ).
    CHECK len GT 0.
    pos = len.
    DO len TIMES.
      pos = pos - 1.
      char = long_filename+pos(1).
      IF char ='.'.
        len = len - pos.
        pos = pos + 1.
        pure_extension = long_filename+pos(len).
        TRANSLATE pure_extension TO LOWER CASE.
        EXIT.
      ENDIF.
    ENDDO.
    " 找文件名  29.04.2024 19:56:56 by kkw
    IF pure_extension IS INITIAL.
      len_f = len.
    ELSE.
      len_f = strlen( long_filename ) - strlen( pure_extension ) - 1.
    ENDIF.

    long_filename_f = long_filename(len_f).
    pos = len_f.
    DO len_f TIMES.
      pos = pos - 1.
      char = long_filename_f+pos(1).
      IF char = '\' OR char = '/'.
        len_f = len_f - pos.
        pos = pos + 1.
        pure_filename = long_filename_f+pos(len_f).
        EXIT.
      ENDIF.
    ENDDO.
    IF pure_filename IS INITIAL.
      IF pure_extension IS INITIAL.
        pure_filename = long_filename.
      ELSE.
        pure_filename = long_filename(len_f).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD robot_groupmessages_send.
    TYPES: BEGIN OF t_JSON1,
             msg_param            TYPE string,
             msg_key              TYPE string,
             open_conversation_id TYPE string,
             robot_code           TYPE string,
             cool_app_code        TYPE string,
           END OF t_JSON1.
    TYPES: BEGIN OF t_JSON1_out,
             code              TYPE string,
             requestid         TYPE string,
             message           TYPE string,
             process_query_key TYPE string,
           END OF t_JSON1_out.
    DATA:wa_in  TYPE t_JSON1,
         wa_out TYPE t_JSON1_out.
    TYPES:BEGIN OF ty_header,
            name  TYPE string,
            value TYPE string,
            cdata TYPE string,
            xdata TYPE xstring,
          END OF ty_header.
    DATA:header TYPE TABLE OF ty_header.

*    获取token
    CALL METHOD me->gettoken
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = DATA(access_token).
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    wa_in-msg_param            = msgparam.
    wa_in-msg_key              = msgkey.
    wa_in-open_conversation_id = openconversationid.
    wa_in-robot_code           = robotcode.
*    wa_in-cool_app_code        = coolappcode.
    DATA(json_in) = /ui2/cl_json=>serialize( data = wa_in  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
    INSERT INITIAL LINE INTO TABLE header ASSIGNING FIELD-SYMBOL(<header>).
    <header>-name   = 'x-acs-dingtalk-access-token'.
    <header>-value  = access_token.
    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = robot_groupmessages_send_url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
        header    = header
      IMPORTING
        output    = DATA(out_put)
        rtmsg     = DATA(otmsg)
        status    = DATA(status).
    /ui2/cl_json=>deserialize( EXPORTING json = out_put pretty_name = /ui2/cl_json=>pretty_mode-camel_case CHANGING data = wa_out ).
    IF status EQ 200.
      IF wa_out-process_query_key IS NOT INITIAL.
        rtype = 'S'.
        rtmsg = |发送群会话:{ openconversationid }消息返回信息:processQueryKey:{ wa_out-process_Query_Key },状态码:{ status }|.
      ELSE.
        rtype = 'E'.
        rtmsg = |发送群会话:{ openconversationid }消息返回信息:message:{ wa_out-message },状态码:{ status }|.
      ENDIF.
    ELSE.
      rtype = 'E'.
      rtmsg = |发送群会话:{ openconversationid }消息发生了问题:{ otmsg },状态码:{ status }|.
    ENDIF.
  ENDMETHOD.


  METHOD robot_interactivecards_send.
    TYPES: BEGIN OF t_CARD_PARAM_MAP2,
             title        TYPE string,
             lable        TYPE string,
             markdown     TYPE string,
             hover        TYPE string,
             but01_text   TYPE string,
             but02_text   TYPE string,
             but03_text   TYPE string,
             but_status   TYPE string,
             callback_key TYPE string,
             rtype        TYPE string,
             rtmsg        TYPE string,
             pop_msg      TYPE string,
           END OF t_CARD_PARAM_MAP2.
    TYPES: BEGIN OF t_CARD_DATA3,
             card_param_map TYPE t_CARD_PARAM_MAP2,
           END OF t_CARD_DATA3.
    TYPES: BEGIN OF t_CARD_OPTIONS4,
             support_forward TYPE abap_bool,
           END OF t_CARD_OPTIONS4.
    TYPES: BEGIN OF t_JSON1,
             card_template_id     TYPE string,
             open_conversation_id TYPE string,
             out_track_id         TYPE string,
             robot_code           TYPE string,
             conversation_type    TYPE i,
             callback_route_key   TYPE string,
*             card_data            TYPE t_CARD_DATA3," 通过键值对来绑定  28.06.2024 08:05:11 by kkw
             user_id_type         TYPE i,
             card_options         TYPE t_CARD_OPTIONS4,
             pull_strategy        TYPE abap_bool,
           END OF t_JSON1.
    TYPES: BEGIN OF t_RESULT2,
             process_query_key TYPE string,
           END OF t_RESULT2.
    TYPES: BEGIN OF t_JSON1_out,
             result    TYPE t_RESULT2,
             success   TYPE abap_bool,
             code      TYPE string,
             requestid TYPE string,
             message   TYPE string,
           END OF t_JSON1_out.
    DATA:wa_in  TYPE t_JSON1,
         wa_out TYPE t_JSON1_out.
    TYPES:BEGIN OF ty_header,
            name  TYPE string,
            value TYPE string,
            cdata TYPE string,
            xdata TYPE xstring,
          END OF ty_header.
    DATA:header TYPE TABLE OF ty_header.
    DATA: dref        TYPE REF TO data,
          struct_type TYPE REF TO cl_abap_structdescr,
          comp_tab    TYPE cl_abap_structdescr=>component_table.
    FIELD-SYMBOLS:<stc> TYPE any.
    CHECK carddata IS NOT INITIAL.
    SORT carddata BY key.
    DELETE ADJACENT DUPLICATES FROM carddata COMPARING key.

*    获取token
    CALL METHOD me->gettoken
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = DATA(access_token).
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    struct_type ?= cl_abap_structdescr=>describe_by_data( p_data = wa_in ).
    DATA(comp) = struct_type->get_components( ).
    wa_in-card_template_id             = cardtemplateid.
    wa_in-open_conversation_id         = openconversationid.
    wa_in-out_track_id                 = outtrackid.
    wa_in-robot_code                   = robotcode.
    wa_in-conversation_type            = conversationtype.
    wa_in-callback_route_key           = callbackroutekey.
    wa_in-user_id_type                 = useridtype.
    wa_in-card_options-support_forward = abap_false.
    wa_in-pull_strategy                = abap_false.

    " 构造请求体的card_data  27.06.2024 16:35:17 by kkw
*    CLEAR:struct_type.
*    DATA(comp_carddata) = CAST cl_abap_structdescr(
*                               CAST cl_abap_tabledescr(
*                               cl_abap_tabledescr=>describe_by_data( p_data = carddata )
*                               )->get_table_line_type( )
*                               )->get_components( ).
    CLEAR comp_tab.
    LOOP AT carddata ASSIGNING FIELD-SYMBOL(<carddata>).
      INSERT INITIAL LINE INTO TABLE comp_tab ASSIGNING FIELD-SYMBOL(<comp_tab>).
      <comp_tab>-name = <carddata>-key.
      <comp_tab>-type ?= cl_abap_elemdescr=>get_string( ).
    ENDLOOP.
    " 构建出card_data的key、value结构  27.06.2024 17:20:29 by kkw
    struct_type = cl_abap_structdescr=>create( comp_tab ).
    " 进一步构建请求体的CARD_PARAM_MAP  27.06.2024 17:22:10 by kkw
    CLEAR:comp_tab.
    INSERT INITIAL LINE INTO TABLE comp_tab ASSIGNING <comp_tab>.
    <comp_tab>-name = 'CARD_PARAM_MAP'.
    <comp_tab>-type = struct_type.
    struct_type = cl_abap_structdescr=>create( comp_tab ).
    " 进一步构建请求体的CARD_DATA,插入请求体结构中
    INSERT INITIAL LINE INTO TABLE comp ASSIGNING FIELD-SYMBOL(<comp>).
    <comp>-name = 'CARD_DATA'.
    <comp>-type = struct_type.
    struct_type = cl_abap_structdescr=>create( comp ).
    CREATE DATA dref TYPE HANDLE struct_type.
    CHECK dref IS BOUND.
    ASSIGN dref->* TO <stc>.
    MOVE-CORRESPONDING wa_in TO <stc>.
    " 将carddata的value放入请求体
    LOOP AT carddata ASSIGNING <carddata>.
      DATA(key) = to_upper( |CARD_DATA-CARD_PARAM_MAP-{ <carddata>-key }| ).
      ASSIGN COMPONENT key OF STRUCTURE <stc> TO FIELD-SYMBOL(<value>).
      IF <value> IS ASSIGNED.
        <value> = <carddata>-value.
        UNASSIGN <value>.
      ENDIF.
    ENDLOOP.

    DATA(json_in) = /ui2/cl_json=>serialize( data = <stc>  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
    INSERT INITIAL LINE INTO TABLE header ASSIGNING FIELD-SYMBOL(<header>).
    <header>-name   = 'x-acs-dingtalk-access-token'.
    <header>-value  = access_token.
    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = json_in
        url       = robot_interactivecards_url
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
        header    = header
      IMPORTING
        output    = DATA(out_put)
        rtmsg     = DATA(otmsg)
        status    = DATA(status).
    /ui2/cl_json=>deserialize( EXPORTING json = out_put pretty_name = /ui2/cl_json=>pretty_mode-camel_case CHANGING data = wa_out ).
    IF status EQ 200.
      IF wa_out-result-process_query_key IS NOT INITIAL.
        rtype = 'S'.
        rtmsg = |发送群会话:{ openconversationid }互动卡片消息返回信息:processQueryKey:{ wa_out-result-process_Query_Key },状态码:{ status }|.
      ELSE.
        rtype = 'E'.
        rtmsg = |发送群会话:{ openconversationid }互动卡片消息返回信息:message:{ wa_out-message },状态码:{ status }|.
      ENDIF.
    ELSE.
      rtype = 'E'.
      rtmsg = |发送群会话:{ openconversationid }互动卡片消息发生了问题:{ otmsg },状态码:{ status }|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
