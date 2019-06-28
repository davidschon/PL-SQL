# PL-SQL

This is a collection of PL/SQL scripts that I have created to fulfill needs for the bizarre environment I work in.

<ol>
  <li><b>holdUp.sql</b></li>
  My work place environment makes use of Oracle Service-Oriented Architecture (SOA) but incoming files have incorrect permissions.  Our Operations group runs a script on a 6 minute Cron to update the permissions.  Previously developers were using a simple DBMS_LOCK.sleep(360); command, waiting a full 6 minutes, before continuing.  The problem is the script may have already corrected permissions long before that duration.  This is particularly an issue when testing dozens of scenarios multiple times each.  This change will watch for an exists status on a specified file.  Once the file exists (permissions allow it to be seen) the program continues.  Additonally, a timer makes certain the 6 minutes has not been exceeded.  This protects against situations where the specified file name or path are incorrect, or the source file does not exist.
  <li><b>Second</b></li>
</ol>
