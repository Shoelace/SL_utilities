SET SERVEROUTPUT ON
DECLARE
l_in_blob            BLOB;
l_compressed_blob    BLOB;
l_uncompressed_blob  BLOB;
BEGIN
-- Set some values
l_in_blob     := TO_BLOB(UTL_RAW.CAST_TO_RAW
('This is a long string of words used for this example This is a long string of words used for this exampleThis is a long string of words used for this exampleThis is a long string of words used for this exampleThis is a long string of words used for this exampleThis is a long string of words used for this exampleThis is a long string of words used for this exampleThis is a long string of words used for this example'));
l_compressed_blob   := TO_BLOB('0');
l_uncompressed_blob := TO_BLOB('0');
 
-- Compress the string
UTL_COMPRESS.lz_compress
(src => l_in_blob, dst => l_compressed_blob, quality => 9);
 
-- Uncompress the string
UTL_COMPRESS.lz_uncompress
(src => l_compressed_blob, dst => l_uncompressed_blob);
 
-- Compare the results with the input
DBMS_OUTPUT.put_line('Input length is    : ' || LENGTH(l_in_blob));
DBMS_OUTPUT.put_line('Compressed length  : ' || LENGTH(l_compressed_blob));
DBMS_OUTPUT.put_line('Uncompressed length: ' || LENGTH(l_uncompressed_blob));
 
-- Caller responsibility to free up temporary LOBs
-- See Operational Notes in the documentation
DBMS_LOB.FREETEMPORARY(l_in_blob);
DBMS_LOB.FREETEMPORARY(l_compressed_blob);
DBMS_LOB.FREETEMPORARY(l_uncompressed_blob);
END;
/