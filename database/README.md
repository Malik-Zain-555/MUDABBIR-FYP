# Mudabbir: Database Setup

This folder builds the Mudabbir database on **Oracle AI Database 26ai Free** and loads the Quran data (114 surahs, 6,236 ayat, 5 translations).

## What's in this folder

| File | Purpose |
|---|---|
| `00_setup.sql` | Creates the `mudabbir` database user (run once, as admin) |
| `01_quran_core.sql` | Creates the tables: `surah`, `ayat`, `translator`, `translation` |
| `load_quran.py` | Loads the data from the CSV files into the tables |
| `data/surah.csv`, `data/ayat.csv`, `data/translation.csv` | The cleaned Quran data (keep the `data` folder **next to** `load_quran.py`) |

```
database/
├── 00_setup.sql
├── 01_quran_core.sql
├── load_quran.py
├── README.md
└── data/
    ├── surah.csv
    ├── ayat.csv
    └── translation.csv
```

## Data notes

- Translations: Saheeh International, Abdullah Yusuf Ali, Pickthall (English); Jalandhry, Maududi (Urdu). Source: Tanzil.net.
- `ayat_id = surah_number * 1000 + ayah_number` (e.g. 2:255 is `2255`).
- The Arabic text of ayah 1 has **no bismillah** in front of it (it was removed during cleaning). Only 1:1 is the bismillah itself.

## What you need

- Oracle AI Database 26ai Free
- The latest Oracle SQL Developer
- Python 3.9 or newer

## Setup steps

### 1. Connect as admin

In SQL Developer, create a new connection:

| Field | Value |
|---|---|
| Name | `free_admin` |
| Username | `sys` |
| Password | the password you chose when installing Oracle |
| Role | `SYSDBA` |
| Hostname | `localhost` |
| Port | `1521` |
| **Service name** | `FREEPDB1` (select *Service name*, not SID) |

Click **Test**, then **Connect**.

### 2. Create the project user

Open `00_setup.sql`, replace `CHANGE_ME` with your own password, and run it with **F5** (Run Script) while connected as `free_admin`.

### 3. Connect as the project user

Create a second connection:

| Field | Value |
|---|---|
| Name | `mudabbir_dev` |
| Username | `mudabbir` |
| Password | the password you chose in step 2 |
| Role | `default` |
| Hostname / Port | `localhost` / `1521` |
| Service name | `FREEPDB1` |

### 4. Create the tables

Connected as `mudabbir_dev`, open `01_quran_core.sql` and press **F5**.
Every statement should say "created" or "inserted", and the last two queries should list 4 tables and 5 translators.

### 5. Load the data

Open a terminal inside the `database` folder (**not** inside `data`) and run:

```
pip install oracledb
python load_quran.py
```

Type the `mudabbir` password when asked. If the user or service name in your setup is different, edit `DB_USER` and `DB_DSN` at the top of `load_quran.py`.

You should see:

```
surah          114  OK
ayat          6236  OK
translation  31180  OK
```

To check the CSV files without touching the database, run `python load_quran.py --check`.

### 6. Test it

```sql
SELECT arabic_text FROM ayat WHERE ayat_id = 2001;
```

This should return `الم` (no bismillah in front).

## Troubleshooting

| Error | Meaning / fix |
|---|---|
| `ORA-12514` or `ORA-12541` when connecting | The database or listener isn't running. Open Windows Services and start the Oracle database and listener services. Also check you used service name `FREEPDB1`. |
| `ORA-01920: user name conflicts` | The user already exists. Skip the `CREATE USER` part of `00_setup.sql`. |
| `ORA-00955: name is already used` | The tables already exist. To rebuild, run the `DROP` commands below, then re-run `01_quran_core.sql`. |
| `ORA-01017: invalid credentials` | Wrong password. Passwords with special characters must be in **double quotes** in SQL (`"MyPass#1"`). |
| `load_quran.py` can't connect | Check the password and the `DB_DSN` line (`localhost:1521/FREEPDB1`). |

To start over (this deletes the tables and all data in them), run as `mudabbir_dev`:

```sql
DROP TABLE translation;
DROP TABLE ayat;
DROP TABLE translator;
DROP TABLE surah;
```

## Security

- **Never commit passwords.** `00_setup.sql` uses the placeholder `CHANGE_ME`; keep it that way in Git.
- When the backend is added, store the database password in a `.env` file, which is listed in `.gitignore`.
