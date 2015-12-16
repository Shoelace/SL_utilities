Prompt Applying pk_smtp.sql ...

CREATE OR REPLACE PACKAGE smtp
AUTHID DEFINER
AS
/*GITSTART$Format:
Git ID   : %H
Author   : %an < %ae >
Date     : %ai
Reference: %d
$GITEND*/

  boundary    CONSTANT VARCHAR2(50) := 'boundry.=*#abc1234321cba#*=';

PROCEDURE send_mail (p_to          IN VARCHAR2,
                     p_cc          IN VARCHAR2 DEFAULT NULL,
                     p_bcc         IN VARCHAR2 DEFAULT NULL,
                     p_from        IN VARCHAR2,
                     p_subject     IN VARCHAR2,
                     p_clob_msg    IN CLOB,
                     p_sender      IN VARCHAR2 DEFAULT NULL,
                     p_smtp_host   IN VARCHAR2,
                     p_smtp_port   IN NUMBER DEFAULT 25);

END smtp;
/
show errors

CREATE OR REPLACE PACKAGE BODY smtp
AS
/*GITSTART$Format:
Git ID   : %H
Author   : %an < %ae >
Date     : %ai
Reference: %d
$GITEND*/

  l_step        PLS_INTEGER  := 24000; -- make sure you set a multiple of 3 not higher than 24573

  k_log         Logger := LogManager.GetLogger();

/*
network permissions are visible in:
select * FROM dba_network_acls ;
select * FROM DBA_NETWORK_ACL_PRIVILEGES;

the 'connect' privilage is require on the mail host/port for the emailing to work

*/

PROCEDURE write_data (c IN OUT  NOCOPY UTL_SMTP.connection, d varchar2)
IS
BEGIN
k_log.trace('C:'||rtrim(d,UTL_TCP.crlf) );
UTL_SMTP.write_data(c, d);
END write_data;

PROCEDURE send_header(c IN OUT  NOCOPY UTL_SMTP.connection, p_name IN VARCHAR2, p_header IN VARCHAR2) AS
BEGIN
  write_data(c, p_NAME || ': ' || p_HEADER || utl_tcp.CRLF);
END send_header;


PROCEDURE send_mail (p_to          IN VARCHAR2,
                     p_cc          IN VARCHAR2 DEFAULT NULL,
                     p_bcc          IN VARCHAR2 DEFAULT NULL,
                                       p_from        IN VARCHAR2,
                                       p_subject     IN VARCHAR2,
                                       p_clob_msg    IN CLOB,
                                       p_sender      IN VARCHAR2 DEFAULT NULL,
                                       p_smtp_host   IN VARCHAR2,
                                       p_smtp_port   IN NUMBER DEFAULT 25)
IS
l_mail_conn   UTL_SMTP.connection;
  l_replies     UTL_SMTP.replies;
  l_reply     UTL_SMTP.reply;

  l_idx BINARY_INTEGER;

  l_TABLEN BINARY_INTEGER;
  l_email_TAB DBMS_UTILITY.UNCL_ARRAY;
  l_emails varchar2(2000);

BEGIN
k_log.entry;
  l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);

  l_replies := UTL_SMTP.ehlo(l_mail_conn, p_smtp_host);

  IF k_log.istraceenabled THEN
    l_idx := l_replies.FIRST;

    WHILE(l_idx IS NOT NULL) LOOP
       k_log.TRACE('S:'|| l_replies(l_idx).code || ' - '|| l_replies(l_idx).text);
       l_idx := l_replies.next(l_idx);
    END LOOP;

    k_log.DEBUG('message size:'||DBMS_LOB.getlength(p_clob_msg));
    IF p_clob_msg IS NOT NULL AND DBMS_LOB.getlength(p_clob_msg) > 0 THEN
      l_reply := UTL_SMTP.mail(l_mail_conn, p_from, 'SIZE='||DBMS_LOB.getlength(p_clob_msg));
    ELSE
      l_reply := UTL_SMTP.mail(l_mail_conn, p_from);
    END IF;
    k_log.trace('S:'|| l_reply.code || ' - '|| l_reply.text);

    --loop over CSV
    l_emails := p_to;
    IF p_cc IS NOT NULL THEN
    l_emails := ltrim(l_emails||', '||p_cc,',');
    END IF;
    IF p_bcc IS NOT NULL THEN
    l_emails := ltrim(l_emails||','||p_bcc,',');
    END IF;

    k_log.trace(l_emails);

    DBMS_UTILITY.COMMA_TO_TABLE(l_emails,l_TABLEN,    l_email_TAB);
    IF l_TABLEN = 0 THEN
      k_log.ERROR('no valid email addressess specified.#'||p_to);
      RAISE NO_DATA_FOUND;-- k_log.exit;
    END IF;

    FOR i IN 1 .. l_TABLEN LOOP
      l_reply := UTL_SMTP.rcpt(l_mail_conn, trim(l_email_TAB(i)));
      k_log.trace('S:'|| l_reply.code || ' - '|| l_reply.text);
    end loop;

    l_reply := UTL_SMTP.open_data(l_mail_conn);
    k_log.trace('S:'|| l_reply.code || ' - '|| l_reply.text);
  ELSE
    k_log.debug('message size:'||DBMS_LOB.getlength(p_clob_msg));
    UTL_SMTP.mail(l_mail_conn, p_from, 'SIZE='||DBMS_LOB.getlength(p_clob_msg));
    --loop over CSV
    DBMS_UTILITY.COMMA_TO_TABLE(p_to,l_TABLEN,    l_email_TAB);
    IF l_TABLEN = 0 THEN
      k_log.ERROR('no valid email addressess specified.#'||p_to);
      RAISE NO_DATA_FOUND;-- k_log.exit;
    END IF;

    FOR i IN 1 .. l_TABLEN LOOP
      UTL_SMTP.rcpt(l_mail_conn, trim(l_email_TAB(i)));
    end loop;
    UTL_SMTP.open_data(l_mail_conn);
  END IF;


  send_header(l_mail_conn, 'Date' , TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') );
  send_header(l_mail_conn, 'To' , p_to );
  send_header(l_mail_conn, 'Cc' , p_cc );
  --send_header(l_mail_conn, 'Bcc' , p_bcc ); --dont output bcc stuff here. as it becomes visible
  send_header(l_mail_conn, 'From' , p_from );
  send_header(l_mail_conn, 'Sender' , p_sender );
  send_header(l_mail_conn, 'Subject' , p_subject );
  send_header(l_mail_conn, 'Reply-To' , p_from );
  send_header(l_mail_conn, 'MIME-Version','1.0' );
  send_header(l_mail_conn, 'Content-Type', 'multipart/mixed; boundary="' || boundary || '"' || UTL_TCP.crlf );

  IF p_clob_msg NOT LIKE '--' || boundary||'%' THEN
    write_data(l_mail_conn, '--' || boundary || UTL_TCP.crlf);
    write_data(l_mail_conn, 'Content-Type: text/plain; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);
  end if;

IF p_clob_msg IS NOT NULL AND DBMS_LOB.getlength(p_clob_msg) > 0 THEN
  --direct write via utl_smtp to bypass logging.
  FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_clob_msg) - 1 )/l_step) LOOP
    UTL_SMTP.write_data(l_mail_conn, DBMS_LOB.substr(p_clob_msg, l_step, i * l_step + 1));
    --write(l_mail_conn, DBMS_LOB.substr(p_clob_msg, l_step, i * l_step + 1));
  END LOOP;
END IF;

  UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf||'--' || boundary || '--' || UTL_TCP.crlf);


  IF k_log.istraceenabled THEN
    l_reply := UTL_SMTP.close_data(l_mail_conn);
    k_log.trace('S:'|| l_reply.code || ' - '|| l_reply.text);
    l_reply := UTL_SMTP.quit(l_mail_conn);
    k_log.trace('S:'|| l_reply.code || ' - '|| l_reply.text);
  ELSE
    UTL_SMTP.close_data(l_mail_conn);
    UTL_SMTP.quit(l_mail_conn);
  END IF;

EXCEPTION
       WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
       k_log.catching();
         BEGIN
           utl_smtp.quit(l_mail_conn);
         EXCEPTION
           WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
             NULL; -- When the SMTP server is down or unavailable, we don't
                   -- have a connection to the server. The quit call will
                   -- raise an exception that we can ignore.
         END;
         RAISE;
END send_mail;


END smtp;
/
show errors
