"""RULE-001, first half: find a flat number in a free-text remark.

BUG DRILL - this copy has a defect. Copy it over code/dues/flat_in_remark.py, run the tests,
and debug with evidence: /debug-evidence. Then put the original back.
"""
import re

# A block letter, an optional hyphen, three digits: "B-304", "b304". See RULE-001a and RULE-001b.
_FLAT_PATTERN = re.compile(r"\b([A-Z])-?(\d{3})\b")


def flat_in_remark(remark: str) -> str | None:
    found = _FLAT_PATTERN.search(remark)
    return f"{found.group(1)}-{found.group(2)}" if found else None
