/*---------------------------------------------
    Code Version
    Allows for browsing of current code on
    Package Bodies
    *This require your DBA to grant read access
     to 'Package Body' on ALL_SOURCE
----------------------------------------------*/
SET serveroutput ON
ACCEPT p char   PROMPT  'Partial Package Name:'
ACCEPT n number PROMPT  'Number of Lines (0 for all):'
DECLARE 
    p_package_name      VARCHAR2(100)   := '&p';
    p_package_lines     NUMBER          := &n + 1;
    v_package_content   VARCHAR2(1000);
    v_package_line      NUMBER;

CURSOR package_cursor
    IS
        select 
            line,text
        from 
            SYS.all_source 
        where
            1=1
            and type = 'PACKAGE BODY'
            and name like upper('%'||p_package_name||'%')   
            and rownum <    (CASE
                                WHEN p_package_lines = 1 THEN 100000
                                ELSE p_package_lines
                                END
                            );         
BEGIN
    OPEN package_cursor;
        LOOP
            v_package_content   := null;
            v_package_line      := null;
            FETCH package_cursor INTO v_package_line,v_package_content;
            dbms_output.put_line(v_package_line || '  |  ' || v_package_content);
        EXIT WHEN package_cursor%NOTFOUND;
        END LOOP;
    CLOSE package_cursor;
END;
/