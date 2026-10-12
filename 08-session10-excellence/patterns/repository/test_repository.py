import pytest

from repository_example import InMemoryPaymentRepository, Payment, SqlitePaymentRepository


# One contract, run against every repository. A cloud repository later must pass it too.
@pytest.fixture(params=[InMemoryPaymentRepository, SqlitePaymentRepository])
def repo(request):
    return request.param()


def test_add_then_read_back(repo):
    repo.add(Payment("B-304", 2500.0, "UTR1"))
    repo.add(Payment("A-101", 1000.0, "R9"))
    assert repo.for_flat("B-304") == [Payment("B-304", 2500.0, "UTR1")]


def test_exists_by_reference(repo):
    repo.add(Payment("B-304", 2500.0, "UTR1"))
    assert repo.exists("UTR1") and not repo.exists("UTR2")


def test_unknown_flat_is_empty_not_an_error(repo):
    assert repo.for_flat("Z-999") == []
