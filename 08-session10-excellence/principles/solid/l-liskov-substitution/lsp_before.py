# BEFORE - EmailNotifier "is a" Notifier, but it breaks the promise: it raises when a flat has no
# email. Every caller now needs an isinstance() check, and one missing email stops ALL reminders.

class Notifier:
    def send(self, flat, message):
        """Promise: try to deliver; return True if delivered, False if not. Never raise."""
        raise NotImplementedError


class SmsNotifier(Notifier):
    def __init__(self, phones):
        self.phones, self.sent = phones, []

    def send(self, flat, message):
        if flat not in self.phones:
            return False
        self.sent.append((flat, message))
        return True


class EmailNotifier(Notifier):
    def __init__(self, emails):
        self.emails, self.sent = emails, []

    def send(self, flat, message):
        self.sent.append((self.emails[flat], message))   # KeyError when there is no email
        return True


def remind_all(notifier, flats, message):
    return [flat for flat in flats if not notifier.send(flat, message)]   # flats not reached
