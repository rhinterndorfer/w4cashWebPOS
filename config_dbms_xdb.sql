--SELECT DBMS_XDB.cfg_get() FROM DUAL;

DECLARE
  configxml    SYS.XMLType;
  configxml2   SYS.XMLType;
BEGIN
  -- Get the current configuration
  configxml := DBMS_XDB.cfg_get();
 
  -- Modify the configuration
  SELECT updateXML(
           configxml,
           '/xdbconfig/sysconfig/protocolconfig/httpconfig/max-header-size/text()',
           '131072',
           'xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd"')
    INTO configxml2 FROM DUAL;
  SELECT updateXML(
           configxml2,
           '/xdbconfig/sysconfig/protocolconfig/httpconfig/log-level/text()',
           '1',
           'xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd"')
    INTO configxml2 FROM DUAL;
 
  -- Update the configuration to use the modified version
  DBMS_XDB.cfg_update(configxml2);
END;
/