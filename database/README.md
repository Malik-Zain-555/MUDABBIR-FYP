# Mudabbir - Database Setup Guide

This folder builds the **Mudabbir database** on **Oracle AI Database 26ai Free** and loads the Quran text and translations into it.
Follow the steps in order. Every step says **what** you do, **why**, and **what you should see**.

When you finish, you will have **36 tables** (the same as the ERD) and the Quran data loaded (114 surahs, 6,236 ayat, 5 translations).

---

## 1. What you need

| Tool | Why | Notes |
|---|---|---|
| Oracle AI Database 26ai Free | The database itself | Download "Oracle AI Database Free" from Oracle's website (Windows installer, or Docker on Linux/Mac). During the install you choose a password for the admin user `SYS` - **write it down**. |
| Oracle SQL Developer (latest) | The program where you run the `.sql` files | An old version may not understand the newest database. Update it if something looks wrong. |
| Python 3.9 or newer | Runs `load_quran.py` | Check with `python --version`. |
| Git | Get and share the project files | |

Every team member installs their own copy and builds their own database. The scripts in this folder make all copies identical.

---

## 2. What is in this folder

```
database/
├── 00_setup.sql             creates the database user "mudabbir"
├── 01_quran_core.sql        creates 4 tables: surah, ayat, translator, translation
├── 02_mudabbir_schema.sql   creates the other 32 tables (everything in the ERD)
├── load_quran.py            fills the Quran tables with data
├── 99_drop_new_tables.sql   OPTIONAL: deletes the 32 tables from 02 so you can redo it
├── README.md                this guide
└── data/
    ├── surah.csv            114 surahs
    ├── ayat.csv             6,236 ayat (Arabic text)
    └── translation.csv      31,180 translations (5 translators x 6,236 ayat)
```

**Run order: 00, 01, then load_quran.py, then 02.** File 99 is only for emergencies (see Section 8).

---

## 3. Step-by-step setup

### Step 1 - Make the admin connection

In SQL Developer click the green **+** and fill in:

| Field | Value |
|---|---|
| Name | `free_admin` |
| Username | `sys` |
| Password | the password you chose when installing Oracle |
| Role | `SYSDBA` |
| Hostname | `localhost` |
| Port | `1521` |
| **Service name** | `FREEPDB1` (select the *Service name* button, **not** SID) |

Click **Test**. The status must say **Success**. Then click **Connect**.

*Why FREEPDB1?* Oracle Free has a main database (`FREE`) and a pluggable database inside it (`FREEPDB1`). All project work happens in `FREEPDB1`.

### Step 2 - Create the project user (`00_setup.sql`)

1. File > Open > `00_setup.sql`.
2. Replace `CHANGE_ME` with **your own password**. Keep the double quotes. Do not save this change into Git.
3. Make sure the top-right connection selector says `free_admin`.
4. Press **F5** (Run Script).

*What you should see:* "User MUDABBIR created.", "Grant succeeded.", and `CON_NAME` showing **FREEPDB1**.

*Why:* we never build the project inside `SYS`. A separate user keeps the project tidy and safe.

### Step 3 - Make the project connection

Create a second connection:

| Field | Value |
|---|---|
| Name | `mudabbir_dev` |
| Username | `mudabbir` |
| Password | the password you chose in step 2 |
| Role | `default` |
| Hostname / Port | `localhost` / `1521` |
| Service name | `FREEPDB1` |

Test it, then connect. **From now on, all SQL files are run on `mudabbir_dev`**, not on `free_admin`.

### Step 4 - Check the database is ready (optional but recommended)

Run these three lines in `mudabbir_dev`:

```sql
SELECT banner_full FROM v$version;
SELECT value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET';
SELECT VECTOR_DISTANCE(TO_VECTOR('[1,2]'), TO_VECTOR('[2,3]'), EUCLIDEAN) FROM dual;
```

You should see the 26ai release, `AL32UTF8`, and the number `1.4142135623730951`.
`AL32UTF8` means Arabic and Urdu text is stored correctly. The last line proves vector search works (we use it later for AI search).

### Step 5 - Create the Quran tables (`01_quran_core.sql`)

Connected as `mudabbir_dev`: File > Open > `01_quran_core.sql`, press **F5**.

*What you should see:* four "Table ... created." lines, five "1 row inserted.", and at the end a list with 4 tables (`AYAT`, `SURAH`, `TRANSLATION`, `TRANSLATOR`) and 5 translators.

### Step 6 - Load the Quran data (`load_quran.py`)

The tables are empty. A **loader** is a small Python script that reads the CSV files and puts the rows into the tables. (It is a one-time helper and is **not** part of the app or the backend.)

Open a terminal **inside the `database` folder** (not inside `data`) and run:

```
pip install oracledb
python load_quran.py
```

Type the `mudabbir` password when asked.

*What you should see:*

```
surah          114  OK
ayat          6236  OK
translation  31180  OK
```

To test the CSV files without touching the database, run `python load_quran.py --check`.
If your user name or service name is different, edit `DB_USER` and `DB_DSN` at the top of `load_quran.py`.
The script is safe to run again: it empties the three Quran tables first, then reloads them.

Quick test in SQL Developer:

```sql
SELECT arabic_text FROM ayat WHERE ayat_id = 2001;
```

This must return `الم` with **no bismillah** in front.

### Step 7 - Create the remaining tables (`02_mudabbir_schema.sql`)

Connected as `mudabbir_dev`: File > Open > `02_mudabbir_schema.sql`, press **F5**.

The last lines of the script run three checks. You should see:

1. `TOTAL_TABLES` = **36**
2. The "not ENABLED" query returns **no rows**
3. A list of all 36 tables

If any statement shows an error, read Section 8, or send the full error text to the team.

### Step 8 - Optional: test that the rules work

This proves the database protects itself. Run in `mudabbir_dev`:

```sql
-- 1) A normal Learner (should work)
INSERT INTO app_user (full_name, email, password_hash, role, account_status)
VALUES ('Test Learner', 'test.learner@example.com', 'not-a-real-hash', 'LEARNER', 'APPROVED');
INSERT INTO learner (learner_id) SELECT user_id FROM app_user WHERE email = 'test.learner@example.com';

-- 2) A Scholar row for the same user (should FAIL - the user's role is LEARNER)
INSERT INTO scholar (scholar_id) SELECT user_id FROM app_user WHERE email = 'test.learner@example.com';
```

The second insert must fail with `ORA-02291` (parent key not found). That is the correct, expected result.
Clean up:

```sql
DELETE FROM learner WHERE learner_id IN (SELECT user_id FROM app_user WHERE email = 'test.learner@example.com');
DELETE FROM app_user WHERE email = 'test.learner@example.com';
COMMIT;
```

---

## 4. The 36 tables (same as the ERD)

| Module | Tables |
|---|---|
| Quranic Data (9) | `surah`, `ayat`, `translator`, `translation`, `tafseer`, `subject`, `subject_ayat`, `subject_surah`, `ayat_question` |
| MCC Management (4) | `mcc`, `subject_mcc`, `mcc_content`, `mcc_certificate` |
| AI Content Curation (5) | `summary`, `khutba`, `subject_summary`, `subject_khutba`, `ai_generated_content` |
| User Records (5) | `app_user`, `admin`, `scholar`, `learner`, `scholar_approval` |
| Course Offering and Registration (4) | `mcc_offering`, `registration`, `registration_status`, `payment` |
| Course Progress (4) | `mcc_progress`, `module_progress`, `mcc_feedback`, `completion_record` |
| Assessment (5) | `assessment`, `assessment_question`, `assessment_attempt`, `learner_answer`, `assessment_result` |

MCC = Micro-Credential Course.

---

## 5. Rules and conventions every team member must know

- **Subject, not Topic.** The ERD and use cases say "Subject", so the tables are `subject`, `subject_ayat`, and so on. Use the word *subject* in the backend and frontend code too.
- **Table `APP_USER`.** The entity "User" is created as `app_user`, because `USER` is a reserved word in Oracle.
- **Names:** tables and columns use `snake_case` (for example `surah_id`).
- **Ayat id:** `ayat_id = surah number x 1000 + ayah number`. So 2:255 is `2255` and 114:6 is `114006`.
- **Arabic text:** stored with diacritics and **without** the bismillah, except for 1:1 (where the bismillah is the verse itself).
- **Auto numbers:** most tables number their rows automatically (`GENERATED BY DEFAULT ON NULL AS IDENTITY`). You may also supply your own id (needed when importing data).
- **Users and roles:** create the `app_user` row first (with role `LEARNER`, `SCHOLAR` or `ADMIN`), then the matching row in `learner`, `scholar` or `admin`. The database refuses a mismatch.
- **Scholar approval:** a Scholar signs up (account status `PENDING`) and a row is added to `scholar_approval`. An Admin approves or rejects it there. The backend must also set `app_user.account_status`. Learner accounts are approved automatically.
- **Allowed values** are enforced by the database (`CHECK` constraints), for example:
  - `app_user.role`: LEARNER, SCHOLAR, ADMIN
  - `app_user.account_status`: PENDING, APPROVED, REJECTED, SUSPENDED
  - `mcc.mcc_status`: DRAFT, PUBLISHED, RETIRED
  - `mcc_offering.offering_status`: SCHEDULED, OPEN, CLOSED, COMPLETED, CANCELLED
  - approval status columns: PENDING, APPROVED, REJECTED
- **AI content:** each row of `ai_generated_content` has exactly one of `summary_id` or `khutba_id`. The project currently uses Khutba.
- **Learner answers** can only answer questions that belong to the assessment of their attempt (the database enforces this).

---

## 6. Data source and license note

The Quran text and translations come from **Tanzil.net** (Saheeh International, Abdullah Yusuf Ali, Pickthall, Jalandhry, Maududi), provided by our supervisor. As far as we know, Tanzil asks for attribution and for the text not to be changed. Check Tanzil's current terms and keep the credit in the final report.

---

## 7. Daily workflow for the team

1. Pull the latest changes from Git.
2. If a `.sql` file in this folder changed, read the commit message to see what to re-run.
3. Never edit the database by hand and forget it. **Every table change must be written into the `.sql` files** and committed, so everyone gets it.
4. Never commit passwords. `00_setup.sql` keeps `CHANGE_ME`.

---

## 8. If something goes wrong

| Error or problem | What it means / what to do |
|---|---|
| `ORA-12514` or `ORA-12541` when connecting | The database or listener is not running. Open Windows Services and start the Oracle database and listener services. Also check the service name is `FREEPDB1`. |
| `ORA-01017: invalid credentials` | Wrong password. In SQL, a password with special characters must be inside **double quotes**. |
| `ORA-28000: the account is locked` | Run on `free_admin`: `ALTER USER mudabbir ACCOUNT UNLOCK;` |
| `ORA-01920: user name conflicts` | The user already exists. Skip that part of `00_setup.sql`. |
| `ORA-00955: name is already used` | The table already exists. For the Quran tables see below; for the 32 tables run `99_drop_new_tables.sql`, then `02` again. |
| `ORA-02291` / `ORA-02292` | A foreign key rule stopped you (a row points to something that does not exist, or you tried to delete something still in use). Normal behaviour: fix the data or the order of your inserts. |
| `load_quran.py` cannot connect | Check the password and the `DB_DSN` line (`localhost:1521/FREEPDB1`). |
| `load_quran.py` cannot find the CSV files | You are in the wrong folder. Run it from inside `database` (the folder that contains `data`). |
| Arabic shows as boxes in SQL Developer | Only a font problem in the results grid. The data is fine; check with `SELECT arabic_text FROM ayat WHERE ayat_id = 2001;` |

### The drop file (`99_drop_new_tables.sql`) - when and why

It is an **optional safety tool**. `02` cannot create a table that already exists, so if the design changes (or you ran a wrong version), you delete the 32 tables first and run `02` again.
- It does **not** touch the 4 Quran tables or their data.
- It deletes everything inside the 32 tables. Never run it once real data (users, courses) is stored.
- "table or view does not exist" errors while it runs are normal.

To rebuild only the Quran tables, drop them in this order and run `01` + `load_quran.py` again (this deletes the Quran data, which the loader restores):

```sql
DROP TABLE translation CASCADE CONSTRAINTS PURGE;
DROP TABLE ayat        CASCADE CONSTRAINTS PURGE;
DROP TABLE translator  CASCADE CONSTRAINTS PURGE;
DROP TABLE surah       CASCADE CONSTRAINTS PURGE;
```

(Drop the 32 tables with `99` first, because they point to `surah` and `ayat`.)

---

## 9. Security

- Never put a real password in a file that goes to GitHub. Once pushed, it stays in the history even if you delete it.
- When the backend is added, keep the database password in a `.env` file. `.env` is listed in `.gitignore`.

---

## 10. What comes next

1. **Load the Subjects** from the concepts files (sir's `Concepts` and `QuranicConcepts` spreadsheets) into `subject` and `subject_ayat`. This is another one-time loader, like `load_quran.py`.
2. **Backend (FastAPI)** that reads and writes this database for the web and mobile apps.
3. **Frontend**: React (web) and React Native (mobile).
4. **AI features**: search by meaning and khutba generation on top of the stored data.
