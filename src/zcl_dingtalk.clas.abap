class ZCL_DINGTALK definition
  public
  final
  create public .

public section.

  constants GETTOKEN_URL type STRING value `https://oapi.dingtalk.com/gettoken` ##NO_TEXT.
  constants CORPCONVERSATION_URL type STRING value `https://oapi.dingtalk.com/topapi/message/corpconversation/asyncsend_v2` ##NO_TEXT.
  constants GETDEPT_URL type STRING value `https://oapi.dingtalk.com/topapi/v2/department/listsub` ##NO_TEXT.
  constants GETUSER_URL type STRING value `https://oapi.dingtalk.com/topapi/v2/user/get` ##NO_TEXT.
  data:
    lt_ztddlistsub TYPE TABLE OF ztddlistsub .

  class-methods CREATE_HTTP_CLIENT
    importing
      !INPUT type STRING optional
      !URL type STRING
      !USERNAME type STRING optional
      !PASSWORD type STRING optional
      !REQMETHOD type CHAR4
      !HTTP1_1 type ABAP_BOOL default ABAP_TRUE
      !PROXY type STRING optional
      !BODYTYPE type STRING default 'JSON'
      !HEADER type STANDARD TABLE optional
    exporting
      value(OUTPUT) type STRING
      value(RTMSG) type STRING
      value(STATUS) type I .
  PROTECTED SECTION.
private section.

  constants GETUSERLIST_URL type STRING value `https://oapi.dingtalk.com/topapi/user/listid` ##NO_TEXT.

  methods POST2DDROBOT .
  methods POST2CORPCONVERSATION .
  methods GET_USERINFO
    importing
      !APPID type ZE_APPID .
  methods GET_DEPT
    importing
      !APPID type ZE_APPID
      !DEPT_ID type ZE_DEPT_ID default 1
      !LANGUAGE type CHAR5 default 'zh_CN'
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG
      value(GT_ZTDDLISTSUB) like LT_ZTDDLISTSUB .
  methods GET_USERLIST
    importing
      !APPID type ZE_APPID
      !DEPT_ID type ZE_DEPT_ID
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG .
  methods GETTOKEN
    importing
      !APPID type ZE_APPID
    exporting
      !RTYPE type BAPI_MTYPE
      !RTMSG type BAPI_MSG
      value(ACCESS_TOKEN) type ZE_ACCESS_TOKEN .
ENDCLASS.



CLASS ZCL_DINGTALK IMPLEMENTATION.


  METHOD create_http_client.
    DATA:result        TYPE string,
         message       TYPE string,
         proxy_host    TYPE string,
         proxy_service TYPE string,
         proxy_user    TYPE string,
         proxy_passwd  TYPE string,
         http_object   TYPE REF TO if_http_client,
         length        TYPE i,
         fields        TYPE tihttpnvp,
         it_ihttpnvp   TYPE TABLE OF ihttpnvp.
    FIELD-SYMBOLS:<wa>       TYPE any,
                  <fs_name>  TYPE any,
                  <fs_value> TYPE any.

    CLEAR:output,length,rtmsg,result,message,status,
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

*  CALL METHOD CL_HTTP_CLIENT=>CREATE "/CREATE(直接通过IP端口)
*    EXPORTING
*      HOST               = 'xmdceshi.wiskind.cn'
*      SERVICE            = '443'
*      SCHEME             = '2'
*    IMPORTING
*      CLIENT             = HTTP_OBJECT
*    EXCEPTIONS
*      ARGUMENT_NOT_FOUND = 1
*      PLUGIN_NOT_ACTIVE  = 2
*      INTERNAL_ERROR     = 3
*      OTHERS             = 4.
*  IF SY-SUBRC NE 0.
*    HTTP_OBJECT->GET_LAST_ERROR( IMPORTING MESSAGE = MESSAGE ).
*    RTMSG = MESSAGE.
*    RETURN.
*  ENDIF.

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

    CASE  bodytype.
      WHEN 'JSON'.
        http_object->request->set_header_field( name = 'Content-Type' value = 'application/json;charset=utf-8' ).
    ENDCASE.

*设置头部数据
    LOOP AT header ASSIGNING <wa>.
      CLEAR:result,message.
      ASSIGN COMPONENT 1 OF STRUCTURE <wa> TO <fs_name>.
      IF sy-subrc NE 0.
        EXIT.
      ENDIF.
      ASSIGN COMPONENT 2 OF STRUCTURE <wa> TO <fs_value>.
      IF sy-subrc NE 0.
        EXIT.
      ENDIF.
      CHECK <fs_name> IS NOT INITIAL
      AND   <fs_value> IS NOT INITIAL.
      result = <fs_name>.
      message = <fs_value>.
      http_object->request->set_header_field( name = result value = message ).
    ENDLOOP.
    CLEAR:result,message.

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
    result = http_object->response->get_cdata( ).
    IF sy-subrc NE 0.
      http_object->get_last_error( IMPORTING message = message ).
      rtmsg = message.
      http_object->close( ).
      RETURN.
    ENDIF.
    message = http_object->response->get_data( ).
* 将返回参数的回车转换，否则回车会在SAP变成'#'
*  REPLACE ALL OCCURRENCES OF REGEX '\n' IN RESULT WITH ''.
*关闭HTTP连接

    http_object->close( ).

    output = result.

    IF result CS '失败'.
      status = '500'.
    ENDIF.
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
          rtmsg = '成功'.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.
    url = |{ gettoken_url }?appkey={ wa_conf-appkey }&appsecret={ wa_conf-appsecret }|.
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
    IF status NE 200.
      rtype = 'E'.
      rtmsg = |调用{ appid }获取access_token发生了问题:{ otmsg }，状态码:{ status }|.
      RETURN.
    ENDIF.
    /ui2/cl_json=>deserialize( EXPORTING json = out_put  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_token ).
    IF wa_token-errcode NE 0.
      rtype = 'E'.
      rtmsg = |调用{ appid }获取access_token返回错误信息:{ wa_token-errmsg }，状态码:{ status }|.
      RETURN.
    ENDIF.
    rtype = 'S'.
    rtmsg = wa_token-errmsg.
    UPDATE ztddconfig SET
    access_token = @wa_token-access_token,
    expires_in = @wa_token-expires_in,
    token_date = @sy-datum,
    token_time = @sy-uzeit
    WHERE appid = @appid.
    COMMIT WORK AND WAIT.
    access_token = wa_token-access_token.
  ENDMETHOD.


  METHOD get_dept.
    " 传入json结构  26.04.2024 11:06:12 by kkw
    TYPES: BEGIN OF t_JSON1_in,
             language TYPE string,
             dept_id  TYPE i,
           END OF t_JSON1_in.
    DATA:wa_in   TYPE t_JSON1_in,
         json_in TYPE string.
    " 返回json结构  26.04.2024 11:05:52 by kkw
    TYPES: BEGIN OF t_RESULT2,
             auto_add_user     TYPE abap_bool,
             create_dept_group TYPE abap_bool,
             dept_id           TYPE i,
             ext               TYPE string,
             name              TYPE string,
             parent_id         TYPE i,
           END OF t_RESULT2.
    TYPES: tt_RESULT2 TYPE STANDARD TABLE OF t_RESULT2 WITH DEFAULT KEY.
    TYPES: BEGIN OF t_JSON1,
             errcode      TYPE i,
             errcode_desc TYPE string,
             errmsg       TYPE string,
             result       TYPE tt_RESULT2,
             request_id   TYPE string,
           END OF t_JSON1.
    DATA:wa_dept TYPE t_JSON1.

    DATA:url     TYPE string,
         out_put TYPE string,
         otmsg   TYPE string,
         status  TYPE i.
    DATA:access_token TYPE ztddconfig-access_token.
    DATA:gt_ztddlistsub_sub   TYPE TABLE OF ztddlistsub,
         gt_ztddlistsub_total TYPE TABLE OF ztddlistsub.

    CLEAR:rtype,rtmsg,gt_ztddlistsub,gt_ztddlistsub_total.
*    获取token  26.04.2024 11:11:45 by kkw
    CALL METHOD me->gettoken
      EXPORTING
        appid        = appid
      IMPORTING
        rtype        = rtype
        rtmsg        = rtmsg
        access_token = access_token.
    IF rtype NE 'S'.
      RETURN.
    ENDIF.
    CLEAR:rtype,rtmsg,json_in,wa_in.
    url = |{ getdept_url }?access_token={ access_token }|.
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
    IF status NE 200.
      rtype = 'E'.
      rtmsg = |调用{ appid }获取listsub发生了问题:{ otmsg }，状态码:{ status }|.
      RETURN.
    ENDIF.
    /ui2/cl_json=>deserialize( EXPORTING json = out_put  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_dept ).
    CASE wa_dept-errcode.
      WHEN 60003.
        wa_dept-errcode_desc = |未找到对应部门,请确认dept_id是否正确|.
      WHEN 400002.
        wa_dept-errcode_desc = |无效的参数,请确认参数是否按要求输入|.
      WHEN -1.
        wa_dept-errcode_desc = |系统繁忙,请稍后再试|.
      WHEN OTHERS.
        wa_dept-errcode_desc = wa_dept-errcode.
    ENDCASE.
    IF wa_dept-errcode NE 0.
      rtype = 'E'.
      rtmsg = |调用{ appid }获取listsub返回错误信息:{ wa_dept-errmsg }，errcode:{ wa_dept-errcode_desc },状态码:{ status }|.
      RETURN.
    ENDIF.
    MOVE-CORRESPONDING wa_dept-result TO gt_ztddlistsub.
    DELETE gt_ztddlistsub WHERE dept_id IS INITIAL.
    APPEND LINES OF gt_ztddlistsub TO gt_ztddlistsub_total.
*    循环获取所有下级部门列表  26.04.2024 10:40:31 by kkw
    LOOP AT gt_ztddlistsub ASSIGNING FIELD-SYMBOL(<gt_ztddlistsub>).
      CLEAR:rtype,rtmsg,gt_ztddlistsub_sub.
      CALL METHOD me->get_dept
        EXPORTING
          appid          = appid
          dept_id        = <gt_ztddlistsub>-dept_id
*         language       = 'zh_CN'
        IMPORTING
*         rtype          = rtype
*         rtmsg          = rtmsg
          gt_ztddlistsub = gt_ztddlistsub_sub.
      DELETE gt_ztddlistsub_sub WHERE dept_id IS INITIAL.
      IF gt_ztddlistsub_sub IS NOT INITIAL.
        APPEND LINES OF gt_ztddlistsub_sub TO gt_ztddlistsub_total.
      ENDIF.
    ENDLOOP.
    rtype = 'S'.
    rtmsg = wa_dept-errmsg.
    MODIFY ztddlistsub FROM TABLE gt_ztddlistsub_total.
    COMMIT WORK AND WAIT.

  ENDMETHOD.


  method GET_USERINFO.
  endmethod.


  method GET_USERLIST.
  endmethod.


  method POST2CORPCONVERSATION.
  endmethod.


  method POST2DDROBOT.
  endmethod.
ENDCLASS.
