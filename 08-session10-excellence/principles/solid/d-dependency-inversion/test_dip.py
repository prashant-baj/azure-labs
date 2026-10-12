import datetime

import dip_after

DUE = datetime.date(2026, 10, 1)


class FixedClock:
    def __init__(self, day):
        self.day = day

    def today(self):
        return self.day


class ListDues:
    def open_dues(self):
        return [dip_after.Due("A-101", DUE, 0), dip_after.Due("B-304", DUE, 1500)]


class RecordingNotifier:
    def __init__(self):
        self.sent = []

    def send(self, flat, message):
        self.sent.append(flat)
        return True


def run_on(day):
    notifier = RecordingNotifier()
    reminded = dip_after.ReminderJob(ListDues(), FixedClock(day), notifier).run()
    return reminded, notifier.sent


def test_day_15_no_reminder():  # no database, no real date, no SMS account
    assert run_on(datetime.date(2026, 10, 16)) == ([], [])


def test_day_16_reminds_only_who_owes():
    assert run_on(datetime.date(2026, 10, 17)) == (["B-304"], ["B-304"])
