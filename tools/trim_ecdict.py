"""
Trim the full ECDICT stardict.db (~851MB) into a compact ecdict.db (~6MB)
suitable for bundling in a mobile app.

Usage:
    python3 trim_ecdict.py ~/Downloads/stardict.db assets/ecdict.db

Strategy:
  - Keep ~59k core words that have frequency data (BNC/COCA), exam tags
    (CET4/6, TOEFL, GRE …), Collins rating, or Oxford 3000 flag.
  - Also keep word-form variants referenced by those core words' `exchange`
    field, so lemma lookup (running → run) works.
  - Only store the 6 columns needed for lookup.
  - Result: ~6 MB, covers everyday English reading/learning.
"""

import sqlite3
import sys
import os


def main():
    if len(sys.argv) != 3:
        print(f"Usage: python3 {sys.argv[0]} <input_stardict.db> <output_ecdict.db>")
        sys.exit(1)

    src_path = sys.argv[1]
    dst_path = sys.argv[2]

    if not os.path.exists(src_path):
        print(f"Error: {src_path} not found")
        sys.exit(1)

    os.makedirs(os.path.dirname(dst_path) or ".", exist_ok=True)
    if os.path.exists(dst_path):
        os.remove(dst_path)

    print(f"Reading from: {src_path}")
    print(f"Writing to:   {dst_path}")

    src = sqlite3.connect(src_path)
    dst = sqlite3.connect(dst_path)

    dst.execute("""
        CREATE TABLE stardict (
            word       TEXT NOT NULL,
            sw         TEXT NOT NULL,
            phonetic   TEXT DEFAULT '',
            translation TEXT DEFAULT '',
            collins    INTEGER DEFAULT 0,
            exchange   TEXT DEFAULT ''
        )
    """)

    # ── Step 1: collect core words (have frequency / tag / rating) ──
    print("Step 1: selecting core words with frequency/tag data...")
    core_rows = src.execute("""
        SELECT word, sw, phonetic, translation, collins, exchange
        FROM stardict
        WHERE translation != ''
          AND (bnc > 0 OR frq > 0 OR tag != '' OR collins > 0 OR oxford > 0)
    """).fetchall()
    print(f"  core words: {len(core_rows):,}")

    # Build a set of sw values we already have, and collect word forms
    # referenced in exchange fields.
    core_sw = set()
    needed_forms = set()
    for row in core_rows:
        core_sw.add(row[1])  # sw
        exchange = row[5]
        if exchange:
            for part in exchange.split("/"):
                idx = part.find(":")
                if idx >= 0:
                    form = part[idx + 1 :]
                    if form:
                        needed_forms.add(form.lower())

    # Remove forms we already have.
    needed_forms -= core_sw

    # ── Step 2: fetch word-form variants ──
    print(f"Step 2: fetching {len(needed_forms):,} word-form variants...")
    form_rows = []
    # Query in batches (SQLite variable limit).
    needed_list = list(needed_forms)
    batch_size = 500
    for i in range(0, len(needed_list), batch_size):
        batch = needed_list[i : i + batch_size]
        placeholders = ",".join("?" * len(batch))
        rows = src.execute(
            f"""SELECT word, sw, phonetic, translation, collins, exchange
                FROM stardict WHERE sw IN ({placeholders})""",
            batch,
        ).fetchall()
        form_rows.extend(rows)

    print(f"  form variants found: {len(form_rows):,}")

    # ── Step 3: write to destination ──
    all_rows = core_rows + form_rows
    print(f"Step 3: writing {len(all_rows):,} rows...")
    dst.executemany("INSERT INTO stardict VALUES (?,?,?,?,?,?)", all_rows)
    dst.commit()

    print("Creating index on sw...")
    dst.execute("CREATE INDEX idx_sw ON stardict(sw)")
    dst.commit()

    print("VACUUMing...")
    dst.execute("VACUUM")

    src.close()
    dst.close()

    size_mb = os.path.getsize(dst_path) / (1024 * 1024)
    print(f"Done! {dst_path} = {size_mb:.1f} MB, {len(all_rows):,} entries")


if __name__ == "__main__":
    main()
