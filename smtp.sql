CREATE OR REPLACE PACKAGE  BODY FIN_SMTP_PKG IS
--
--                NAME:     FIN_CHRIV_LDAP_PKG
--                TYPE:     Package Body
--     ORIGINAL AUTHOR:     David Schon
--                DATE:     2018-APR-20
-- CONCURRENT PROGRAMS:      
--
--         DESCRIPTION:     Collects SMTP email address
--                          
--       
--
-- CHANGE HISTORY:
--
--      VERSION     DATE            AUTHOR          JIRA      DESCRIPTION
--      -------     --------        ------------    ------    ---------------
--      1.0         2018-APR-25     DRSchon         LDAP-1    Initial Version
------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--    ____            _                 _   _                                   
--   |  _ \  ___  ___| | __ _ _ __ __ _| |_(_) ___  _ __  ___                    
--   | | | |/ _ \/ __| |/ _` | '__/ _` | __| |/ _ \| '_ \/ __|                    
--   | |_| |  __/ (__| | (_| | | | (_| | |_| | (_) | | | \__ \                     
--   |____/ \___|\___|_|\__,_|_|  \__,_|\__|_|\___/|_| |_|___/                    
--                                                                               
--                                                                              
--------------------------------------------------------------------------------
P                       UTL_FILE.FILE_TYPE;
errbuf                  VARCHAR2(32767);
retcode                 NUMBER;
UniqueID                NUMBER;
l_retvalh               PLS_INTEGER;
l_sessionh              DBMS_LDAP.session;      
l_retval                PLS_INTEGER;
l_session               DBMS_LDAP.session;
v_connection            VARCHAR2(250);
v_connectionh           VARCHAR2(250);
v_tag                   VARCHAR2(10);
v_source                VARCHAR2(10);
v_ldap_host_w           VARCHAR2(100);
v_ldap_host_h           VARCHAR2(100);

procedure               userQuery(p_in_domain IN VARCHAR2,p_in_individual IN NUMBER);
--------------------------------------------------------------------------------
--    _   _ _   _ _ _ _   _           
--   | | | | |_(_) (_) |_(_) ___  ___ 
--   | | | | __| | | | __| |/ _ \/ __|
--   | |_| | |_| | | | |_| |  __/\__ \
--    \___/ \__|_|_|_|\__|_|\___||___/
-- 
--------------------------------------------------------------------------------
--+------------------------------------------------------------+--
--| PROCEDURE: write_log                                       |
--| PURPOSE:   Populates log content for the Entity File       |
--+------------------------------------------------------------+--       
PROCEDURE write_log
  (
  p_in_msg in VARCHAR2
  )
    IS
      BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG, p_in_msg);
      END;
--------------------------------------------------------------------------------
--    _   _                  ___                        
--   | | | |___  ___ _ __   / _ \ _   _  ___ _ __ _   _ 
--   | | | / __|/ _ \ '__| | | | | | | |/ _ \ '__| | | |
--   | |_| \__ \  __/ |    | |_| | |_| |  __/ |  | |_| |
--    \___/|___/\___|_|     \__\_\\__,_|\___|_|   \__, |
--                                                |___/ 
--------------------------------------------------------------------------------


PROCEDURE userQuery
            (
            p_in_domain         IN VARCHAR2
            ,p_in_individual    IN NUMBER
            )
IS    
      CURSOR userQuery_cursor  
        IS
        SELECT 
          p1.attribute2 as UniqueID
          ,null as email
        FROM 
          hr.per_all_people_f p1
          ,apps.fnd_user u1
          ,per_all_assignments_f a1
          ,hr.hr_all_organization_units o1
          ,(select 
              v.employee_id
              ,v.segment1
              ,pa1.address_line1
              ,pa1.town_or_city
              ,pa1.region_2
              ,pa1.postal_code
            from 
              ap.ap_suppliers v
              ,ap.ap_supplier_sites_all s
              ,hr.per_addresses pa1
            where 
              v.vendor_id = s.vendor_id
              and pa1.person_id = v.employee_id
              and pa1.address_type = s.vendor_site_code
              and nvl(trunc(v.end_date_active), trunc(sysdate)) >= trunc(sysdate)
              and nvl(trunc(s.inactive_date),   trunc(sysdate)) >= trunc(sysdate)
              and v.enabled_flag = 'Y'
              and v.vendor_type_lookup_code = 'EMPLOYEE'
              and s.vendor_site_code = (select 
                                          s2.vendor_site_code
                                        from 
                                          ap.ap_supplier_sites_all s2
                                        where 
                                          s2.vendor_id = s.vendor_id
                                          and nvl(trunc(s2.inactive_date), trunc(sysdate)) >= trunc(sysdate)
                                          and s2.vendor_site_code in ('HOME')
                                          and s2.vendor_id = (select 
                                                                s3.vendor_id
                                                              from 
                                                                ap.ap_supplier_sites_all s3
                                                              where 
                                                                s3.vendor_id = s2.vendor_id
                                                                and nvl(trunc(s3.inactive_date), trunc(sysdate)) >= trunc(sysdate)
                                                                and s3.vendor_site_code in ('HOME')
                                                                group by s3.vendor_id
                                                                having count(*) = 1
                                                                ))
              and pa1.address_id =     (select 
                                          max(pa2.address_id)
                                        from 
                                          hr.per_addresses pa2
                                        where 
                                          pa2.person_id = pa1.person_id
                                          and pa2.primary_flag = 'Y'
                                          and trunc(nvl(pa2.date_from, sysdate)) <= trunc(sysdate)
                                          and trunc(nvl(pa2.date_to, sysdate))   >= trunc(sysdate))) vend
      ,hr.per_all_people_f p2
      ,apps.fnd_user u2
      ,per_all_assignments_f a2
    WHERE
      1=1
      AND ((p_in_individual < 1) OR (p_in_individual = p1.attribute2))       
      AND p1.person_id = u1.employee_id
      AND p1.person_id = a1.person_id
      AND p2.person_id = a1.supervisor_id
      AND a1.organization_id = o1.organization_id
      AND p1.person_id = vend.employee_id (+)
      AND p2.person_id = u2.employee_id
      AND p2.person_id = a2.person_id
      AND trunc(sysdate) between trunc(p1.effective_start_date) and trunc(p1.effective_end_date)
      AND a1.primary_flag = 'Y'
      AND trunc(sysdate) between trunc(a1.effective_start_date) and trunc(a1.effective_end_date)
      AND a1.payroll_id in (select payroll_id from hr.pay_all_payrolls_f where payroll_name in ('Arrears', 'Bi-Weekly'))
      AND p1.attribute_category = 'Yes'
      AND p1.first_name is not null
      AND p1.last_name is not null
      AND u1.user_name is not null
      AND p1.attribute2 is not null
      AND p1.email_address is not null
      AND trunc(sysdate) between trunc(p2.effective_start_date) and trunc(p2.effective_end_date)
      AND a2.primary_flag = 'Y'
      AND trunc(sysdate) between trunc(a2.effective_start_date) and trunc(a2.effective_end_date)
      AND ((a2.payroll_id in (select payroll_id from hr.pay_all_payrolls_f where payroll_name in ('Arrears', 'Bi-Weekly'))
            AND p2.attribute_category = 'Yes')
          OR
           a2.payroll_id in (select payroll_id from hr.pay_all_payrolls_f where payroll_name in ('RC Payroll', 'RC Bi-Weekly','Courtesy Assignment')))            
      AND p2.first_name is not null
      AND p2.last_name is not null
      AND u2.user_name is not null
      AND p2.attribute2 is not null
      AND p2.email_address is not null
  UNION ALL
  SELECT
      p1.attribute2 as UniqueID
      ,null as email
  FROM 
    hr.per_all_people_f p1
    ,apps.fnd_user u1
    ,per_all_assignments_f a1
    ,hr.hr_all_organization_units o1
    ,(select 
        replace(v.num_1099, '-', null) num_1099
        ,v.segment1
        ,s.address_line1
        ,s.city
        ,s.state
        ,s.zip
      from 
        ap.ap_suppliers v
        ,ap.ap_supplier_sites_all s
       where 
        1=1
        and v.vendor_id = s.vendor_id
        and nvl(trunc(v.end_date_active), trunc(sysdate)) >= trunc(sysdate)
        and nvl(trunc(s.inactive_date),   trunc(sysdate)) >= trunc(sysdate)
        and v.enabled_flag = 'Y'
        and v.vendor_type_lookup_code = 'IN'
        and s.vendor_site_code = (select 
                                    s2.vendor_site_code
                                  from 
                                    ap.ap_supplier_sites_all s2
                                  where 
                                    s2.vendor_id = s.vendor_id
                                    and nvl(trunc(s2.inactive_date), trunc(sysdate)) >= trunc(sysdate)
                                    and s2.vendor_id = (select 
                                                          s3.vendor_id
                                                        from 
                                                          ap.ap_supplier_sites_all s3
                                                        where 
                                                          s3.vendor_id = s2.vendor_id
                                                          and nvl(trunc(s3.inactive_date), trunc(sysdate)) >= trunc(sysdate)
                                                        group by s3.vendor_id
                                                        having count(*) = 1
                                                        ))) vend

    ,hr.per_all_people_f p2
    ,apps.fnd_user u2
    ,per_all_assignments_f a2
  WHERE 
    1=1
    AND ((p_in_individual < 1) OR (p_in_individual = p1.attribute2))      
    AND p1.person_id = u1.employee_id
    AND p1.person_id = a1.person_id
    AND p2.person_id = a1.supervisor_id
    AND a1.organization_id = o1.organization_id
    AND REPLACE(p1.national_identifier, '-', NULL) = vend.num_1099 (+)
    AND p2.person_id = u2.employee_id
    AND p2.person_id = a2.person_id
    AND trunc(SYSDATE) BETWEEN trunc(p1.effective_start_date) AND trunc(p1.effective_end_date)
    AND a1.primary_flag = 'Y'
    AND trunc(SYSDATE) BETWEEN trunc(a1.effective_start_date) AND trunc(a1.effective_end_date)
    AND a1.payroll_id in (select payroll_id from hr.pay_all_payrolls_f where payroll_name in ('RC Payroll', 'RC Bi-Weekly','Courtesy Assignment'))
    AND p1.first_name IS NOT NULL
    AND p1.last_name IS NOT NULL
    AND u1.user_name IS NOT NULL
    AND p1.attribute2 IS NOT NULL
    AND p1.email_address IS NOT NULL
    AND trunc(SYSDATE) BETWEEN trunc(p2.effective_start_date) AND trunc(p2.effective_end_date)
    AND a2.primary_flag = 'Y'
    AND trunc(SYSDATE) BETWEEN trunc(a2.effective_start_date) AND trunc(a2.effective_end_date)
    AND ((a2.payroll_id in (select payroll_id from hr.pay_all_payrolls_f where payroll_name in ('Arrears', 'Bi-Weekly'))
        and p2.attribute_category = 'Yes')
      or
       a2.payroll_id in (select payroll_id from hr.pay_all_payrolls_f where payroll_name in ('RC Payroll', 'RC Bi-Weekly','Courtesy Assignment'))
        )
    AND p2.first_name IS NOT NULL
    AND p2.last_name IS NOT NULL
    AND u2.user_name IS NOT NULL
    AND p2.attribute2 IS NOT NULL
    AND p2.email_address IS NOT NULL
    ;        
   

p   userQuery_cursor%rowtype;

BEGIN
  retcode := SUCCESS;
  errbuf := '';
  write_log('Begin Loop of Persons');

    OPEN userQuery_cursor;                         
      LOOP

        FETCH userQuery_cursor into p;  
        EXIT WHEN userQuery_cursor%notfound;
          BEGIN
          --+------------------------------------------------------------+--
          --| PURPOSE:   Locate Employment LDAP to Search                |
          --+------------------------------------------------------------+--  
            SELECT  flv.tag into v_tag
            FROM    apps.fnd_lookup_values flv  
                    ,apps.fnd_responsibility_vl   frv
                    ,HR.hr_all_organization_units haou
                    ,per_all_assignments_f paaf
                    ,per_all_people_f papf
            WHERE 
                flv.lookup_type = 'EBO_HR_UNIT_EMAIL' 
                AND flv.lookup_code = upper(substr(frv.description, 12))  
                AND flv.enabled_flag = 'Y'  
                AND TRUNC(SYSDATE) between NVL(flv.start_date_active, TRUNC(SYSDATE)) AND NVL(flv.end_date_active, TRUNC(SYSDATE))
                AND TRUNC(SYSDATE) between NVL(paaf.effective_start_date, TRUNC(SYSDATE)) AND NVL(paaf.EFFECTIVE_END_DATE, TRUNC(SYSDATE))
                AND TRUNC(SYSDATE) between NVL(papf.effective_start_date, TRUNC(SYSDATE)) AND NVL(papf.EFFECTIVE_END_DATE, TRUNC(SYSDATE))
                AND papf.person_id = paaf.person_id                                         
                AND paaf.primary_flag = 'Y'  
                AND haou.organization_id = Paaf.organization_id
                AND haou.attribute2 = frv.responsibility_id(+)
                AND paaf.payroll_id is not null
                AND papf.attribute2 = p.UniqueID  
                AND rownum = 1;
            Exception
            when no_data_found 
                then
                    v_tag := null;                  
          END;

          BEGIN
          --+------------------------------------------------------------+--
          --| PURPOSE:   Search LDAP to for Primary SMTP                 |
          --+------------------------------------------------------------+--
            IF v_tag is null
            THEN
              write_log('No fnd_lookup_value.tag found for: ' || p.UniqueID);
              p.email := 'No@email.found';
              v_source := 'W MAP';
            ELSIF v_tag = 'H' AND p_in_domain IN ('H','B')                  
            THEN
              p.email := get_ldap_emailh(p.UniqueID,3);
              v_source := 'H LDAP';
              IF p.email = 'place@h.net'
                THEN
                  SELECT    p1.EMAIL_ADDRESS into p.email 
                  FROM      hr.per_all_people_f p1
                            ,per_all_assignments_f a1 
                  WHERE     p1.ATTRIBUTE2 = p.UniqueID             
                            AND trunc(sysdate) between trunc(p1.effective_start_date) and trunc(p1.effective_end_date)
                            AND p1.person_id = a1.person_id
                            AND trunc(sysdate) between trunc(a1.effective_start_date) and trunc(a1.effective_end_date)
                            AND a1.primary_flag = 'Y';
                  IF p.email is null
                    THEN
                      write_log('No email found for H User: ' || p.UniqueID);
                      p.email := 'No@email.found';
                  END IF;
              END IF;
            ELSIF v_tag != 'H' AND p_in_domain IN ('W','B')                    
            THEN
              p.email := get_ldap_email(p.UniqueID,3);
              v_source := 'W LDAP';
              IF p.email = 'place@w.net'
                THEN
                  SELECT    p1.EMAIL_ADDRESS into p.email 
                  FROM      hr.per_all_people_f p1
                            ,per_all_assignments_f a1 
                  WHERE     p1.ATTRIBUTE2 = p.UniqueID             
                            AND trunc(sysdate) between trunc(p1.effective_start_date) and trunc(p1.effective_end_date)
                            AND p1.person_id = a1.person_id
                            AND trunc(sysdate) between trunc(a1.effective_start_date) and trunc(a1.effective_end_date)
                            AND a1.primary_flag = 'Y';
                  IF p.email is null
                    THEN
                      write_log('No email found for W User: ' || p.UniqueID);
                      p.email := 'No@email.found';
                  END IF;
              END IF;
            END IF;
          END;
          write_log(p.UniqueID || ' is employed at ' || v_tag || ' and has an email address of ' || p.email || ' retrieved from ' || v_source);

            BEGIN
              UPDATE FIN.W_SMTP_LDAP
                SET SMTP_ADDR = p.email, LAST_UPDATE = trunc(SYSDATE)
                WHERE UNIQUE_ID = p.UniqueID;
              IF sql%rowcount = 0 THEN  
                INSERT INTO FIN.W_SMTP_LDAP (UNIQUE_ID,SMTP_ADDR,LAST_UPDATE)
                VALUES (p.UniqueID,p.email,trunc(SYSDATE));
              END IF;
            END;
                
      END LOOP;     

      EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line ('Error User Query: ' || sqlerrm);
        DBMS_OUTPUT.put_line('ERROR_STACK: ' || DBMS_UTILITY.FORMAT_ERROR_STACK);
        DBMS_OUTPUT.put_line('ERROR_BACKTRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);        
        write_log('======================================================');
        write_log('==          Beginning Error User Query:             ==');
        write_log('======================================================');
        write_log(' ');
        write_log('Error User Query: ');
        write_log(SQLERRM);
        write_log(SQLCODE);   
        write_log('ERROR_STACK: ' || DBMS_UTILITY.FORMAT_ERROR_STACK);
        write_log('ERROR_BACKTRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END userQuery;
 
--+--------------------------------------------------------------+--
--| FUNCTION: ldapConnect                                        |
--| PURPOSE: LDAP Connection Management                          |
--| ldap_action:  (1) Bind  (2) UnBind                           |
--+--------------------------------------------------------------+--
procedure ldapConnect(ldap_action IN NUMBER)
   IS
      BEGIN
        select get_ldap_email('connection', ldap_action) into v_connection from dual;
      END;
--+--------------------------------------------------------------+--
--| FUNCTION: ldapConnecth                                       |
--| PURPOSE: LDAP Connection Management H                        |
--| ldap_action:  (1) Bind  (2) UnBind                           |
--+--------------------------------------------------------------+--
procedure ldapConnecth(ldap_actionh IN NUMBER)
   IS
      BEGIN
        select get_ldap_emailh('connection', ldap_actionh) into v_connectionh from dual;
      END;

--+--------------------------------------------------------------+--
--| FUNCTION: get_ldap_email                                     |
--| PURPOSE: Retrieve official email from w-AD LDAP              |
--| ldap_action:  (1) Bind  (2) UnBind  (3) Search               |
--+--------------------------------------------------------------+--
FUNCTION get_ldap_email  (wid IN VARCHAR2, ldap_action IN NUMBER) Return varchar2 as


l_ldap_base     VARCHAR2(256) := 'DC=ad,DC=edu';
l_ldap_host     VARCHAR2(256):= v_ldap_host_w;
l_ldap_port     VARCHAR2(256) := '389';
l_ldap_user     VARCHAR2(256) := 'CN=name,OU=Service,OU=Users,OU=OIT,DC=ad,DC=edu';
l_ldap_passwd   VARCHAR2(256) := 'p@s$w0rD'; 
l_attrs         DBMS_LDAP.string_collection;
l_message       DBMS_LDAP.message;
l_entry         DBMS_LDAP.message;
l_vals          DBMS_LDAP.string_collection;
email           VARCHAR2(250);

BEGIN
/*---------------------------------
|   Create LDAP Session and Bind  |
---------------------------------*/
IF ldap_action = 1
  THEN
    -- Choose to raise exceptions.
    DBMS_LDAP.USE_EXCEPTION := TRUE;
    --Connections are now in the caller
    -- Connect to the LDAP server.
    l_session := DBMS_LDAP.init(hostname => l_ldap_host,
                                portnum  => l_ldap_port);
    -- Authenticates as the service account so it can search
    l_retval := DBMS_LDAP.simple_bind_s(ld     => l_session,
                                        dn     => l_ldap_user,
                                        passwd => l_ldap_passwd);
return(email);                                        
/*---------------------------------
|   End LDAP Session and Bind     |
---------------------------------*/                                        
ELSIF ldap_action = 2
  THEN
    -- Disconnect from the LDAP server.
    l_retval := DBMS_LDAP.unbind_s(ld => l_session);
    return(email);
/*---------------------------------
|   Query LDAP ELSE MAP for Email |
---------------------------------*/    
ELSIF ldap_action = 3
  THEN
  email := null;
  
  -- List what attributes to return
  l_attrs(1) := 'proxyAddresses';
  l_retval := DBMS_LDAP.search_s(ld       => l_session,
                                 base     => l_ldap_base,
                                 scope    => DBMS_LDAP.SCOPE_SUBTREE,
                                 filter   => 'uniqueIdentifier=' ||  wid,
                                 attrs    => l_attrs,
                                 attronly => 0,
                                 res      => l_message);
  -- There should only ever be one returned
  IF DBMS_LDAP.count_entries(ld => l_session, msg => l_message) != 1 
  THEN 
    dbms_output.put_line('W Entries Count for ' || wid || ' were not 1: ' ||  DBMS_LDAP.count_entries(ld => l_session, msg => l_message));   
  ELSE
  
    l_entry := DBMS_LDAP.first_entry(ld  => l_session,
                                     msg => l_message);
                                     
                                     
                                     
    l_vals := DBMS_LDAP.get_values (ld        => l_session,
                                    ldapentry => l_entry,
                                    attr      => l_attrs(1));
                                    
                                    
    IF l_vals.count > 0
      THEN
        FOR l_row in 0 .. l_vals.COUNT    -1
          LOOP
            IF l_vals(l_row) like 'SMTP%'   --Primary email address
              THEN
              
                email := l_vals(l_row);
                email := substr(email,6);
            END IF;
          END LOOP;
    END IF;
  END IF; 
  
IF email is null 
  then 
    email:='place@w.net';              
End IF;

return(email); 

END IF;
END get_ldap_email;

--+--------------------------------------------------------------+--
--| FUNCTION: get_ldap_emailH                                    |
--| PURPOSE: Retrieve official email from H LDAP                 |
--| ldap_action:  (1) Bind  (2) UnBind  (3) Search               |
--+--------------------------------------------------------------+--
FUNCTION get_ldap_emailH  (wid IN VARCHAR2, ldap_actionh IN NUMBER) Return varchar2 as


l_ldap_base     VARCHAR2(256) := 'OU=H,DC=HS,DC=ad,DC=edu';
l_ldap_host     VARCHAR2(256) := v_ldap_host_h;
l_ldap_port     VARCHAR2(256) := '389';
l_ldap_user     VARCHAR2(256) := 'CN=MainCampus LDAP,OU=Resource Accounts,OU=Network Srvcs,OU=ITS,OU=ADMIN,DC=AD,DC=EDU';
l_ldap_passwd   VARCHAR2(256) := 'p@SsW0rD'; 


  l_attrs        DBMS_LDAP.string_collection;
  l_message      DBMS_LDAP.message;
  l_entry        DBMS_LDAP.message;
  l_vals         DBMS_LDAP.string_collection;
  emailh         VARCHAR2(250);

BEGIN
/*---------------------------------
|   Create LDAP Session and Bind  |
---------------------------------*/
IF ldap_actionh = 1
  THEN
    -- Choose to raise exceptions.
    DBMS_LDAP.USE_EXCEPTION := TRUE;
    -- Connections are now in the caller
    -- Connect to the LDAP server.
    l_sessionh := DBMS_LDAP.init(   hostname => l_ldap_host,
                                    portnum  => l_ldap_port);
    -- Authenticates as the service account so it can search
    l_retvalh := DBMS_LDAP.simple_bind_s(   ld     => l_sessionh,
                                            dn     => l_ldap_user,
                                            passwd => l_ldap_passwd);
return(emailh);                                        
/*---------------------------------
|   End LDAP Session and Bind     |
---------------------------------*/                                        
ELSIF ldap_actionh = 2
  THEN
    -- Disconnect from the LDAP server.
    l_retvalh := DBMS_LDAP.unbind_s(ld => l_sessionh);
    return(emailh);
/*---------------------------------
|   Query LDAP ELSE MAP for Email |
---------------------------------*/    
ELSIF ldap_actionh = 3
  THEN
  emailh := null;
  -- List what attributes to return
  l_attrs(1) := 'proxyAddresses';
  l_retvalh := DBMS_LDAP.search_s(  ld       => l_sessionh,
                                    base     => l_ldap_base,
                                    scope    => DBMS_LDAP.SCOPE_SUBTREE,
                                    filter   => '(&(proxyAddresses=*@*)(extensionAttribute11='|| wid ||'))',
                                    attrs    => l_attrs,
                                    attronly => 0,
                                    res      => l_message);
  -- There should only ever be one returned
  IF DBMS_LDAP.count_entries(ld => l_sessionh, msg => l_message) != 1 
  THEN
    dbms_output.put_line('H Entries Count for ' || wid || ' were not 1: ' ||  DBMS_LDAP.count_entries(ld => l_session, msg => l_message));   
  ELSE
    l_entry := DBMS_LDAP.first_entry(ld  => l_sessionh,
                                     msg => l_message);
                                     
    l_vals := DBMS_LDAP.get_values (ld        => l_sessionh,
                                    ldapentry => l_entry,
                                    attr      => l_attrs(1));
    IF l_vals.count > 0
      THEN
        FOR l_row in 0 .. l_vals.COUNT -1    
          LOOP
            IF l_vals(l_row) like 'SMTP%'--Primary email address 
              THEN
                emailh := l_vals(l_row);
                emailh := substr(emailh,6);
            END IF;
          END LOOP;
    END IF; 
  END IF; 
IF emailh is null 
  then 
    emailh:='place@h.net';
End IF;
return(emailh);  
END IF; 
END get_ldap_emailh;

--------------------------------------------------------------------------------
--    ____            __                      _     ____    _    ____  
--   |  _ \ ___ _ __ / _| ___  _ __ _ __ ___ | |   |  _ \  / \  |  _ \ 
--   | |_) / _ \ '__| |_ / _ \| '__| '_ ` _ \| |   | | | |/ _ \ | |_) |
--   |  __/  __/ |  |  _| (_) | |  | | | | | | |___| |_| / ___ \|  __/ 
--   |_|   \___|_|  |_|  \___/|_|  |_| |_| |_|_____|____/_/   \_\_|    
-- 
--------------------------------------------------------------------------------

PROCEDURE performLDAP
    (
      errbuf                    OUT     VARCHAR2
      ,retcode                  OUT     NUMBER
      ,p_in_domain              IN      VARCHAR2
      ,p_in_individual          IN      NUMBER
      ,p_in_host_w              IN      VARCHAR2
      ,p_in_host_h              IN      VARCHAR2
    )
  is
    BEGIN
        --+------------------------------------------------------------+--      
        --| PURPOSE:   Set LDAP Host Global                            |
        --+------------------------------------------------------------+-
        v_ldap_host_w := p_in_host_w;
        v_ldap_host_h := p_in_host_h;
        
        --+------------------------------------------------------------+--
        --| PURPOSE:   Open LDAP Connection                            |
        --+------------------------------------------------------------+-- 
        IF p_in_domain IN ('B','W')                                             
            THEN
                write_log('Opening Connection to W LDAP');
                ldapConnect(1); 
        END IF;    
        IF p_in_domain IN ('B','H')
            THEN
                write_log('Opening Connection to H LDAP');
                ldapConnecth(1);
        END IF;
        --+------------------------------------------------------------+--
        --| PURPOSE:   Perform LDAP Queries                            |
        --+------------------------------------------------------------+-- 
        userQuery(p_in_domain,p_in_individual);
        --+------------------------------------------------------------+--
        --| PURPOSE:   Close LDAP Connection                           |
        --+------------------------------------------------------------+--     
        IF p_in_domain IN ('B','W')                                             
            THEN
                write_log('Opening Connection to W LDAP');
                ldapConnect(2); 
        END IF;    
        IF p_in_domain IN ('B','H')
            THEN
                write_log('Opening Connection to H LDAP');
                ldapConnecth(2);
        END IF;
    END performLDAP;
END FIN_SMTP_PKG;
/