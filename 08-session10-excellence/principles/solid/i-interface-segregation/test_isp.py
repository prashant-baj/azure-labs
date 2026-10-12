import isp_after
import isp_before


class TinyReader:  # the whole fake: three methods, nothing else
    def flats(self):
        return ["A-101", "B-304"]

    def dues_for(self, flat):
        return 2500

    def payments_for(self, flat):
        return [2500] if flat == "A-101" else [1000]


def test_after_needs_a_three_method_fake():
    assert isp_after.flats_with_dues(TinyReader()) == ["B-304"]


def test_before_needs_all_eight_methods():
    abstract = isp_before.SocietyRepository.__abstractmethods__
    assert len(abstract) == 8  # what every test fake had to implement


def test_one_class_can_still_play_every_role():
    society = isp_after.InMemorySociety({"A-101": 2500, "B-304": 2500}, {"A-101": [2500]})
    society.record_payment("B-304", 2500)
    assert isp_after.flats_with_dues(society) == []
