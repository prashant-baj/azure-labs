from publisher_example import EventPublisher, Matcher, PaymentMatched


def test_every_listener_hears_the_event():
    heard = []
    publisher = EventPublisher()
    publisher.subscribe(lambda e: heard.append(("receipt", e.flat)))
    publisher.subscribe(lambda e: heard.append(("ledger", e.amount)))
    Matcher(publisher).match("B-304", 2500.0, "UTR1")
    assert heard == [("receipt", "B-304"), ("ledger", 2500.0)]


def test_a_new_listener_needs_no_change_to_the_matcher():
    seen = []
    publisher = EventPublisher()
    publisher.subscribe(seen.append)  # the dashboard, added later
    Matcher(publisher).match("A-101", 1000.0, "R9")
    assert seen == [PaymentMatched("A-101", 1000.0, "R9")]


def test_one_failing_listener_is_logged_and_does_not_stop_the_rest():
    logged, heard = [], []

    def broken_mailer(event):
        raise RuntimeError("mail server down")

    publisher = EventPublisher(log=logged.append)
    publisher.subscribe(broken_mailer)
    publisher.subscribe(heard.append)
    Matcher(publisher).match("B-304", 2500.0, "UTR1")
    assert len(heard) == 1 and "mail server down" in logged[0]
