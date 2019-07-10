# PL-SQL

This is a collection of PL/SQL scripts that I have created to address challenges specific to this work environment.

<ol>
  <li><b>holdUp.sql</b></li>
  My work place environment makes use of Oracle Service-Oriented Architecture (SOA) but incoming files have incorrect permissions.  Our Operations group runs a script on a 6 minute Cron to update the permissions.  Previously developers were using a simple DBMS_LOCK.sleep(360); command, waiting a full 6 minutes, before continuing.  The problem is the script may have already corrected permissions long before that duration.  This is particularly an issue when testing dozens of scenarios multiple times each.  This change will watch for an exists status on a specified file.  Once the file exists (permissions allow it to be seen) the program continues.  Additonally, a timer makes certain the 6 minutes has not been exceeded.  This protects against situations where the specified file name or path are incorrect, or the source file does not exist.
  <li><b>writeOutput.sql</b></li>
  A common issue that I see in code is inconsistent use of Output and Log writes.  By combining those output into a single procedure I see not only more consistent use but also reduced code lines needed.
  <li><b>exceptionTraceback.sql</b></li>
  This shows off two useful bits of code.  The first is that you can create custom exceptions to handle any situation you like when a canned exception doesn't convey enough information.  The second is the useage of Error Stack and BackTrace.  These will output specific line information to debug your code.
  <li><b>Current_Package_Version.sql</b></li>
  This script allows you to see the body of a package on instances, such as final test and production, where you don't have Package Browse rights.  You will be prompted twice, once for a partial package name and once for the number of lines you wish to display.
  <li><b>masking-string.sql</b></li>
  Often times I will need to send data to someone that contains any of a number of sensitive numbers.  This is a simplified version of the script for masking out enough characters to be compliant but not so many it is useless.  Not a terribly complex utility, but I use it often enough to keep handy.
  <li><b>smtp.sql</b></li>
  This became necessary because a product we purchased (hosted) required that the user accounts on their end (created from feed information we send daily) needed the email address to match the users email address as presented by the Outlook client.  The problem was that our Oracle person records often do not match the outgoing smtp address.  The solution was a custom table that talked to both our main and (independent) extension campuses LDAP servers to record the primary SMTP address in Oracle.  Also the 389 is not optimal, however Oracle Cloud Services was unable to get the secure connection to work correctly.  As we were vpn from Cloud to Server it was deemed acceptable.
</ol>
