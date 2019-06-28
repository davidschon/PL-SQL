SET SERVEROUTPUT ON;
DECLARE

Procedure exceptionProc
(
    p_in_var in VARCHAR2
)
is
update_count_of_zero    exception;

begin
if  (p_in_var is not null)
    then
        dbms_output.put_line(p_in_var);
else
    RAISE update_count_of_zero;
end if;

EXCEPTION
WHEN update_count_of_zero 
    then
        DBMS_OUTPUT.put_line ('Error:   '||sqlerrm);
        /*see writeOutput.sql*/
        writeOutput('B','Error: ');                                                 
        writeOutput('B',SQLERRM);
        writeOutput('B',SQLCODE);
        writeOutput('L','ERROR_STACK: '     || DBMS_UTILITY.FORMAT_ERROR_STACK);
        writeOutput('L','ERROR_BACKTRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;     

BEGIN

exceptionProc('stuff');

END;