"""
load_quran.py - fills the Mudabbir Quran tables from the CSV files in this folder.

Before running:
    1. Run 01_quran_core.sql first (creates the empty tables).
    2. pip install oracledb
Run (from inside this folder):
    python load_quran.py            -> loads into Oracle
    python load_quran.py --check    -> only reads the CSV files (no database)

Safe to run again: it empties the three tables first, then reloads them.
"""
import csv
import getpass
import sys
from pathlib import Path

HERE = Path(__file__).parent

# ---- connection settings (change the user/password if yours differ) ----
DB_USER = "mudabbir"
DB_DSN = "localhost:1521/FREEPDB1"   # host:port/service name

EXPECTED = {"surah": 114, "ayat": 6236, "translation": 6236 * 5}


def read_csv(name):
    with open(HERE / "data" / name, encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        next(reader)  # skip header row
        return list(reader)


def load_files():
    surah = [(int(r[0]), r[1], r[2], r[3], r[4], int(r[5])) for r in read_csv("surah.csv")]
    ayat = [(int(r[0]), int(r[1]), int(r[2]), r[3]) for r in read_csv("ayat.csv")]
    translation = [(int(r[0]), int(r[1]), r[2]) for r in read_csv("translation.csv")]
    return {"surah": surah, "ayat": ayat, "translation": translation}


def check_files(data):
    for table, rows in data.items():
        status = "OK" if len(rows) == EXPECTED[table] else "WRONG"
        print(f"  {table:12} {len(rows):>6} rows (expected {EXPECTED[table]})  {status}")
        if len(rows) != EXPECTED[table]:
            sys.exit("Row count is wrong - stopping.")


def main():
    data = load_files()
    print("Checking CSV files...")
    check_files(data)
    if "--check" in sys.argv:
        print("Files look good. (No database was touched.)")
        return

    import oracledb

    password = getpass.getpass(f"Password for {DB_USER}: ")
    conn = oracledb.connect(user=DB_USER, password=password, dsn=DB_DSN)
    cur = conn.cursor()
    print("Connected to Oracle.")

    # Empty the tables (children first) so the script can be re-run
    for table in ("translation", "ayat", "surah"):
        cur.execute(f"DELETE FROM {table}")

    num = oracledb.DB_TYPE_NUMBER

    cur.setinputsizes(num, 60, 60, 100, 10, num)
    cur.executemany(
        "INSERT INTO surah (surah_id, name_english, name_arabic, name_meaning, "
        "revelation_place, total_ayat) VALUES (:1, :2, :3, :4, :5, :6)",
        data["surah"],
    )

    cur.setinputsizes(num, num, num, 4000)
    cur.executemany(
        "INSERT INTO ayat (ayat_id, surah_id, ayat_number, arabic_text) "
        "VALUES (:1, :2, :3, :4)",
        data["ayat"],
    )

    cur.setinputsizes(num, num, 4000)
    cur.executemany(
        "INSERT INTO translation (ayat_id, translator_id, translation_text) "
        "VALUES (:1, :2, :3)",
        data["translation"],
    )

    conn.commit()

    print("Loaded. Counts in the database:")
    for table in ("surah", "ayat", "translation"):
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        n = cur.fetchone()[0]
        print(f"  {table:12} {n:>6}  {'OK' if n == EXPECTED[table] else 'WRONG'}")
    conn.close()


if __name__ == "__main__":
    main()
