from adapter_example import BankCsvAdapter, Payment, UpiJsonAdapter, total_received

UPI = '{"txn": [{"vpa_note": " b-304 ", "amt_paise": 250000, "utr": "UTR1"}]}'
BANK = 'Narration,Credit,Ref No\nNEFT/SOCIETY/a-101,"2,500.00",R9\n'


def test_both_partners_become_the_same_payment_shape():
    assert UpiJsonAdapter(UPI).payments() == [Payment("B-304", 2500.0, "UTR1")]
    assert BankCsvAdapter(BANK).payments() == [Payment("A-101", 2500.0, "R9")]


def test_the_rule_does_not_care_which_partner():
    assert total_received(UpiJsonAdapter(UPI)) == total_received(BankCsvAdapter(BANK)) == 2500.0
