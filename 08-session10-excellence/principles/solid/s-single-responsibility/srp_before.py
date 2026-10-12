# BEFORE - one class, three reasons to change: how dues are worked out, how the message reads,
# and how it is sent. Three people editing one file. (Invented housing-society example.)

class ReminderService:
    def __init__(self, payments):
        self.payments = payments          # {flat: amount paid this month}
        self.sent = []

    def remind(self, flat, monthly_dues):
        paid = self.payments.get(flat, 0)
        outstanding = monthly_dues - paid
        if outstanding <= 0:
            return None
        message = f"Dear resident of {flat}, Rs {outstanding:.0f} is pending. Please pay."
        self.sent.append(("sms", flat, message))   # pretend SMS gateway call
        return message
