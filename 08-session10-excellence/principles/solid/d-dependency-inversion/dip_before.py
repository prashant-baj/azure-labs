# BEFORE - the rule reaches out and builds its own database, clock and gateway.
# To test "remind on day 16" you need a real database file, today's real date, and an SMS account.
import datetime
import sqlite3


class ReminderJob:
    def run(self):
        db = sqlite3.connect("society.db")                       # hard-wired storage
        today = datetime.date.today()                            # hard-wired clock
        rows = db.execute("SELECT flat, due_date, outstanding FROM dues").fetchall()
        for flat, due_date, outstanding in rows:
            if outstanding > 0 and (today - datetime.date.fromisoformat(due_date)).days > 15:
                print(f"SMS to {flat}: Rs {outstanding} pending")  # hard-wired gateway
