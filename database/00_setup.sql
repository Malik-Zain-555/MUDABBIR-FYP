-- =====================================================================
-- 00_setup.sql
-- Creates the database user "mudabbir" that owns all project tables.
--
-- RUN ONCE, as the admin:
--   * Connection: free_admin  (user SYS, role SYSDBA, service FREEPDB1)
--   * Replace CHANGE_ME with YOUR OWN password (keep the double quotes)
--   * File > Open, then F5 (Run Script)
--
-- NEVER commit your real password to Git. Keep CHANGE_ME in this file.
-- =====================================================================

CREATE USER mudabbir IDENTIFIED BY "CHANGE_ME"
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE, CREATE SYNONYM
    TO mudabbir;

-- Check: must show FREEPDB1 (not FREE). If it shows FREE, your
-- free_admin connection is using the wrong service name.
SHOW CON_NAME;

-- Only if you later get "ORA-28000: the account is locked":
-- ALTER USER mudabbir ACCOUNT UNLOCK;
