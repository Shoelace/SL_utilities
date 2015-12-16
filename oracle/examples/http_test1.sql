  SET serveroutput ON SIZE 40000

  DECLARE
    req   utl_http.req;
    resp  utl_http.resp;
    value VARCHAR2(1024);
    
    NAME  VARCHAR2(255);
  BEGIN

get_page('http://www.google.com','','');
/*
  --  utl_http.set_proxy('proxy.it.my-company.com', 'my-company.com');

    req := utl_http.begin_request('http://URL');
    
    utl_http.set_header(req, 'User-Agent', 'Mozilla/4.0');

    utl_http.set_authentication(req,
                               username => 'user',
                               PASSWORD => 'passwd');

    resp := utl_http.get_response(req);
     dbms_output.put_line('header count:'||utl_http.get_header_count(resp));
     
     FOR i IN 1 .. utl_http.get_header_count(resp) LOOP
     utl_http.get_header(resp,i,NAME  ,
                       VALUE );
                       dbms_output.put_line(name||':'||value);
     END LOOP;
    LOOP
      utl_http.read_line(resp, value, TRUE);
      dbms_output.put_line(VALUE);
    END LOOP;
    utl_http.end_response(resp);
  EXCEPTION
    WHEN utl_http.end_of_body THEN
      utl_http.end_response(resp);
      */
  END;
  /
  