SET SERVEROUTPUT ON;
DECLARE

--+--------------------------------------------------------------+--
--| Name: holdUp                                            
--| PURPOSE: pause until file permissions updated              
--+--------------------------------------------------------------+--
PROCEDURE holdUp(
  l_dir IN VARCHAR2
  ,l_file IN VARCHAR2)
  IS
    ts timestamp;
    it interval day to second(3);
    ms integer;
    l_exists        BOOLEAN;
    l_size          INTEGER;
    l_block_size    INTEGER;
    l_res           NUMBER:=0;
      BEGIN
        ts := systimestamp;
        LOOP
        dbms_output.put_line('Check for exists: ' || SYSTIMESTAMP);
          utl_file.fgetattr(l_dir
                            ,l_file
                            ,l_exists
                            ,l_size
                            ,l_block_size
                            );
          IF(l_exists)
            THEN
                dbms_output.put_line( 'The file exists and has a size of ' || l_size );
                l_res:=1;
            ELSE
                it := systimestamp - ts;
                ms := to_number(translate(substr(it,4),'0:.','0') / 1000);

                IF ms < 600 
                THEN
                    DBMS_LOCK.sleep(5);
                ELSE
                    dbms_output.put_line( 'The maximum time of 6 minutes has been exceeded.  Check the filename, path, mount point, and source file existance.');
                    exit;
                END IF;
          END IF;
        EXIT WHEN l_res = 1;
        END LOOP;
END holdUp;
BEGIN

holdUp('MY_SOA_INBOUND','myFile.dat');

END;
