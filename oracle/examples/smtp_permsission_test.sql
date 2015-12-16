/*
begin
--create acl
DBMS_NETWORK_ACL_ADMIN.create_acl(
    acl => 'acl_smtp.xml', --acl name
    principal => '<username>', --user to grant to
    is_grant => TRUE, 
    privilege => 'connect'); --connect or resolve
    
    --assign privilage to acl
    DBMS_NETWORK_ACL_ADMIN.assign_acl(
    acl => 'acl_smtp.xml', --acl name
    ,host       => 'mailhost'
    ,lower_port => 25
    ,upper_port => 25
    );

--assign acl to additonal users
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
    acl => 'acl_smtp.xml', --acl name
    principal => '<username>', --additional user to grant to
    is_grant => TRUE, 
    privilege => 'connect'); --connect or resolve
END;
/
*/
set serveroutput on
DECLARE
  P_TO VARCHAR2(200);
  P_FROM VARCHAR2(200);
  P_SUBJECT VARCHAR2(200);
  P_MESSAGE VARCHAR2(200);
  P_SMTP_HOST VARCHAR2(200);
  P_SMTP_PORT NUMBER;
  l_mail_conn   UTL_SMTP.connection;
    l_replies     UTL_SMTP.replies;
BEGIN
  P_TO := 'me@example.com';
  P_FROM := 'me@example.com';
  P_SUBJECT := 'email test 2';
  P_MESSAGE := 'this is a test message';
  P_SMTP_HOST := 'mailhost';
  P_SMTP_PORT := 25;

  l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
  l_replies := UTL_SMTP.ehlo(l_mail_conn, p_smtp_host);
  
  UTL_SMTP.mail(l_mail_conn, p_from);
  UTL_SMTP.rcpt(l_mail_conn, p_to);

  UTL_SMTP.open_data(l_mail_conn);
  
  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(systimestamp, 'Dy "," DD Mon YYYY HH24:MI:SS TZHTZM','NLS_DATE_LANGUAGE=ENGLISH') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf || UTL_TCP.crlf);
  
  UTL_SMTP.write_data(l_mail_conn, p_message || UTL_TCP.crlf || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);
  
  FOR i IN l_replies.FIRST .. l_replies.LAST LOOP
  dbms_output.put_line( l_replies(i).code || ' - '|| l_replies(i).text);
  END LOOP;
END;
/
