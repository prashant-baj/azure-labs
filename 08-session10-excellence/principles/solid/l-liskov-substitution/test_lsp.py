import pytest

import lsp_after
import lsp_before

FLATS = ["A-101", "B-304"]


def test_before_one_missing_email_stops_everything():
    notifier = lsp_before.EmailNotifier({"A-101": "a101@example.org"})
    with pytest.raises(KeyError):
        lsp_before.remind_all(notifier, FLATS, "Dues pending")


# One contract test, run against EVERY notifier. A new notifier must pass it too.
@pytest.mark.parametrize(
    "notifier",
    [
        lsp_after.SmsNotifier({"A-101": "98xxxxxx01"}),
        lsp_after.EmailNotifier({"A-101": "a101@example.org"}),
    ],
)
def test_every_notifier_keeps_the_promise(notifier):
    assert lsp_after.remind_all(notifier, FLATS, "Dues pending") == ["B-304"]
