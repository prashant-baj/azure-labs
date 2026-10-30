# The rule on its own - no database at all. Possible only because the rule depends on a port (E-004).
from dues.matcher import match
from dues.model import Payment, UnmatchedReason


class TwoFlats:
    def exists(self, flat):
        return flat in {"C-101", "C-102"}

    def flats_paid_by(self, payer):
        return ["C-101", "C-102"] if payer == "Ravi" else []


def test_rule_001e_payer_with_two_flats_is_not_guessed():
    result = match(Payment("UTR2", "Oct maint", "Ravi", 2500.0, "upi"), TwoFlats())
    assert not result.matched
    assert result.reason is UnmatchedReason.PAYER_HAS_MANY_FLATS
