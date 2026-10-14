"""Try the feature on your laptop without Azure:

    python -m triage.cli "There is a leak in the lift lobby"

Uses the real model if MODEL_BASE_URL, MODEL_NAME and MODEL_API_KEY are set; otherwise the fake.
"""

import json
import os
import sys

from triage.service import TriageService


def main() -> int:
    message = " ".join(sys.argv[1:]) or sys.stdin.read()
    if all(os.environ.get(k) for k in ("MODEL_BASE_URL", "MODEL_NAME", "MODEL_API_KEY")):
        from triage.adapters.openai_compatible import OpenAICompatibleSuggester

        suggester, source = OpenAICompatibleSuggester(), "model"
    else:
        from triage.adapters.fake import FakeSuggester

        suggester, source = FakeSuggester(), "fake"
    print(json.dumps({**TriageService(suggester).triage(message).to_dict(), "suggested_by": source}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
