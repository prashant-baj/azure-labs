# DEF-001 regression - the performance smoke found it; this test keeps it found.
# Many request threads share one SQLite connection. Without the lock in Store, some of these raise
# sqlite3.InterfaceError ("bad parameter or other API misuse") - see ../defect-analysis.md.
import sqlite3
from concurrent.futures import ThreadPoolExecutor

from dues.api import DEMO_FLATS, Store
from dues.model import Payment
from dues.sqlite_store import open_store


def test_def_001_concurrent_payments_and_reads_do_not_corrupt_the_connection():
    db = open_store(sqlite3.connect(":memory:", check_same_thread=False))
    db.executemany("insert into flats values (?, ?)", DEMO_FLATS)
    store = Store(db)

    def work(i: int) -> None:
        store.record(Payment(f"T-{i}", "C-101", "Ravi", 10.0, "upi"))
        store.reminders()

    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(work, range(400)))  # re-raises any exception from a thread

    assert db.execute("select count(*) from payments").fetchone() == (400,)
