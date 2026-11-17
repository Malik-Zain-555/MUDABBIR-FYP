-- =====================================================================
-- 99_drop_new_tables.sql   (OPTIONAL safety tool)
--
-- WHAT : deletes the 32 tables made by 02_mudabbir_schema.sql, in the
--        right order, so you can run 02 again from a clean state.
-- WHEN : only if you ran an older/wrong version of 02 and want to
--        start that part over, or if the design changes while the
--        tables are still empty.
-- SAFE : it does NOT touch SURAH, AYAT, TRANSLATOR, TRANSLATION
--        (the Quran data you already loaded).
-- WARNING: it deletes every row in the 32 tables. Never run it once
--          real data (users, courses) is in them.
--
-- If an OLD version of 02 was run before (with TOPIC_* table names),
-- the DROP lines for those old names are at the bottom of this file.
-- "table or view does not exist" errors are normal and harmless here.
-- =====================================================================
DROP TABLE assessment_result      CASCADE CONSTRAINTS PURGE;
DROP TABLE learner_answer         CASCADE CONSTRAINTS PURGE;
DROP TABLE assessment_attempt     CASCADE CONSTRAINTS PURGE;
DROP TABLE assessment_question    CASCADE CONSTRAINTS PURGE;
DROP TABLE assessment             CASCADE CONSTRAINTS PURGE;
DROP TABLE mcc_certificate        CASCADE CONSTRAINTS PURGE;
DROP TABLE completion_record      CASCADE CONSTRAINTS PURGE;
DROP TABLE mcc_feedback           CASCADE CONSTRAINTS PURGE;
DROP TABLE module_progress        CASCADE CONSTRAINTS PURGE;
DROP TABLE mcc_progress           CASCADE CONSTRAINTS PURGE;
DROP TABLE payment                CASCADE CONSTRAINTS PURGE;
DROP TABLE registration_status    CASCADE CONSTRAINTS PURGE;
DROP TABLE registration           CASCADE CONSTRAINTS PURGE;
DROP TABLE mcc_offering           CASCADE CONSTRAINTS PURGE;
DROP TABLE ai_generated_content   CASCADE CONSTRAINTS PURGE;
DROP TABLE subject_khutba         CASCADE CONSTRAINTS PURGE;
DROP TABLE subject_summary        CASCADE CONSTRAINTS PURGE;
DROP TABLE khutba                 CASCADE CONSTRAINTS PURGE;
DROP TABLE summary                CASCADE CONSTRAINTS PURGE;
DROP TABLE mcc_content            CASCADE CONSTRAINTS PURGE;
DROP TABLE subject_mcc            CASCADE CONSTRAINTS PURGE;
DROP TABLE mcc                    CASCADE CONSTRAINTS PURGE;
DROP TABLE ayat_question          CASCADE CONSTRAINTS PURGE;
DROP TABLE subject_surah          CASCADE CONSTRAINTS PURGE;
DROP TABLE subject_ayat           CASCADE CONSTRAINTS PURGE;
DROP TABLE tafseer                CASCADE CONSTRAINTS PURGE;
DROP TABLE subject                CASCADE CONSTRAINTS PURGE;
DROP TABLE scholar_approval       CASCADE CONSTRAINTS PURGE;
DROP TABLE learner                CASCADE CONSTRAINTS PURGE;
DROP TABLE scholar                CASCADE CONSTRAINTS PURGE;
DROP TABLE admin                  CASCADE CONSTRAINTS PURGE;
DROP TABLE app_user               CASCADE CONSTRAINTS PURGE;

-- ---------------------------------------------------------------------
-- Only needed if the FIRST version of 02 (with TOPIC names) was run.
-- (Run the lines above first, then these.)
-- ---------------------------------------------------------------------
DROP VIEW  v_approved_ai_content;
DROP VIEW  v_offering_seats;
DROP TABLE topic_khutba           CASCADE CONSTRAINTS PURGE;
DROP TABLE topic_summary          CASCADE CONSTRAINTS PURGE;
DROP TABLE topic_mcc              CASCADE CONSTRAINTS PURGE;
DROP TABLE topic_surah            CASCADE CONSTRAINTS PURGE;
DROP TABLE topic_ayat             CASCADE CONSTRAINTS PURGE;
DROP TABLE topic                  CASCADE CONSTRAINTS PURGE;
