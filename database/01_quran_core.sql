-- =====================================================================
-- 01_quran_core.sql
-- Mudabbir: core Quran tables (Surah, Ayat, Translator, Translation)
--
-- HOW TO RUN
--   1. In SQL Developer, connect as  mudabbir_dev
--   2. File > Open this script, then press F5 (Run Script)
--   3. Check the "Script Output" panel: every statement should succeed
--
-- NOTES
--   * Tables are created EMPTY. The Quran data is loaded in a later step.
--   * ayat_id = surah_number * 1000 + ayah_number
--       e.g. 1:1 -> 1001, 2:255 -> 2255, 114:6 -> 114006
--   * Names use snake_case (Oracle turns unquoted names into UPPERCASE).
-- =====================================================================


-- ---------------------------------------------------------------------
-- SURAH : one row per surah (114 rows)
-- ---------------------------------------------------------------------
CREATE TABLE surah (
    surah_id          NUMBER(3)            NOT NULL,
    name_english      VARCHAR2(60 CHAR)    NOT NULL,
    name_arabic       VARCHAR2(60 CHAR)    NOT NULL,
    name_meaning      VARCHAR2(100 CHAR),
    revelation_place  VARCHAR2(10 CHAR)    NOT NULL,
    total_ayat        NUMBER(3)            NOT NULL,
    CONSTRAINT pk_surah           PRIMARY KEY (surah_id),
    CONSTRAINT ck_surah_id        CHECK (surah_id BETWEEN 1 AND 114),
    CONSTRAINT ck_surah_place     CHECK (revelation_place IN ('Makkah', 'Madinah')),
    CONSTRAINT ck_surah_total     CHECK (total_ayat BETWEEN 3 AND 286)
);


-- ---------------------------------------------------------------------
-- AYAT : one row per verse (6,236 rows), Arabic text only
-- ---------------------------------------------------------------------
CREATE TABLE ayat (
    ayat_id        NUMBER(6)               NOT NULL,
    surah_id       NUMBER(3)               NOT NULL,
    ayat_number    NUMBER(3)               NOT NULL,
    arabic_text    VARCHAR2(4000 CHAR)     NOT NULL,
    CONSTRAINT pk_ayat            PRIMARY KEY (ayat_id),
    CONSTRAINT uq_ayat_surah_no   UNIQUE (surah_id, ayat_number),
    CONSTRAINT fk_ayat_surah      FOREIGN KEY (surah_id) REFERENCES surah (surah_id),
    CONSTRAINT ck_ayat_id         CHECK (ayat_id = surah_id * 1000 + ayat_number)
);


-- ---------------------------------------------------------------------
-- TRANSLATOR : one row per translation source (5 rows)
-- ---------------------------------------------------------------------
CREATE TABLE translator (
    translator_id    NUMBER(2)             NOT NULL,
    translator_name  VARCHAR2(100 CHAR)    NOT NULL,
    language_code    VARCHAR2(2 CHAR)      NOT NULL,
    source           VARCHAR2(100 CHAR),
    CONSTRAINT pk_translator       PRIMARY KEY (translator_id),
    CONSTRAINT uq_translator_name  UNIQUE (translator_name),
    CONSTRAINT ck_translator_lang  CHECK (language_code IN ('en', 'ur'))
);


-- ---------------------------------------------------------------------
-- TRANSLATION : one row per ayah per translator (6,236 x 5 rows)
-- ---------------------------------------------------------------------
CREATE TABLE translation (
    ayat_id           NUMBER(6)              NOT NULL,
    translator_id     NUMBER(2)              NOT NULL,
    translation_text  VARCHAR2(4000 CHAR)    NOT NULL,
    CONSTRAINT pk_translation       PRIMARY KEY (ayat_id, translator_id),
    CONSTRAINT fk_translation_ayat  FOREIGN KEY (ayat_id)       REFERENCES ayat (ayat_id),
    CONSTRAINT fk_translation_trans FOREIGN KEY (translator_id) REFERENCES translator (translator_id)
);

-- Speeds up "all translations by one translator" lookups
CREATE INDEX ix_translation_translator ON translation (translator_id);


-- ---------------------------------------------------------------------
-- Reference data: the 5 translators sir provided
-- ---------------------------------------------------------------------
INSERT INTO translator (translator_id, translator_name, language_code, source)
VALUES (1, 'Saheeh International', 'en', 'Tanzil.net');

INSERT INTO translator (translator_id, translator_name, language_code, source)
VALUES (2, 'Abdullah Yusuf Ali', 'en', 'Tanzil.net');

INSERT INTO translator (translator_id, translator_name, language_code, source)
VALUES (3, 'Mohammed Marmaduke Pickthall', 'en', 'Tanzil.net');

INSERT INTO translator (translator_id, translator_name, language_code, source)
VALUES (4, 'Fateh Muhammad Jalandhry', 'ur', 'Tanzil.net');

INSERT INTO translator (translator_id, translator_name, language_code, source)
VALUES (5, 'Abul A''ala Maududi', 'ur', 'Tanzil.net');

COMMIT;


-- ---------------------------------------------------------------------
-- Check: you should see 4 tables and 5 translators
-- ---------------------------------------------------------------------
SELECT table_name FROM user_tables ORDER BY table_name;
SELECT * FROM translator ORDER BY translator_id;
