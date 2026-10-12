# AFTER - three small pieces, each with one reason to change.


class DuesCalculator:  # changes when the committee changes the dues rule
    def __init__(self, payments):
        self._payments = payments

    def outstanding(self, flat, monthly_dues):
        return max(monthly_dues - self._payments.get(flat, 0), 0)


def reminder_text(flat, outstanding):  # changes when the wording changes
    return f"Dear resident of {flat}, Rs {outstanding:.0f} is pending. Please pay."


class SmsNotifier:  # changes when the gateway changes
    def __init__(self):
        self.sent = []

    def send(self, flat, message):
        self.sent.append(("sms", flat, message))


class ReminderService:  # only puts the three together
    def __init__(self, calculator, notifier):
        self._calculator, self._notifier = calculator, notifier

    def remind(self, flat, monthly_dues):
        outstanding = self._calculator.outstanding(flat, monthly_dues)
        if outstanding == 0:
            return None
        message = reminder_text(flat, outstanding)
        self._notifier.send(flat, message)
        return message
