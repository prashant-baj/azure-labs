# Every test runs with a treasurer key in the environment - as the app does in Azure (a Container App secret).
# The value is a test fixture, not a secret: it exists only inside the test process.
import pytest

TEST_KEY = "test-only-key"


@pytest.fixture(autouse=True)
def treasurer_key(monkeypatch):
    monkeypatch.setenv("TREASURER_KEY", TEST_KEY)
    return TEST_KEY
