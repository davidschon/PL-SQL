set serverout on
declare
myNumber    varchar2(100):=1234567;
begin
   myNumber := LPAD(SUBSTR(myNumber,-5),LENGTH(myNumber),'*');
   dbms_output.put_line(myNumber);
end;