SET SERVEROUTPUT ON;
DECLARE

--+------------------------------------------------------------+--
--| PROCEDURE:  writeOutput                                       
--| PURPOSE:    Populates log, output, or both content       
--| OPTIONS:    O   Output
--|             L   Log
--|             B   Both
--+------------------------------------------------------------+--
PROCEDURE writeOutput
  (
  p_in_location in VARCHAR2
  ,p_in_msg     in VARCHAR2
  )
    IS
      BEGIN
        IF p_in_location in ('O','B')
        THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, p_in_msg);
        ELSIF p_in_location in ('L','B')
        THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, p_in_msg);
        ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  'ATTENTION - You did not specify an output method (OLB) for message: ' || p_in_msg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,     'ATTENTION - You did not specify an output method (OLB) for message: ' || p_in_msg);
            DBMS_OUTPUT.PUT_LINE(               'ATTENTION - You did not specify an output method (OLB) for message: ' || p_in_msg);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  p_in_msg);
        END IF;
      END;
      
BEGIN

writeOutput('B','Important Information to record to both Log and Output');

END;