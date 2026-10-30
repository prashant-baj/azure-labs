---
description: Defect analysis for a failing pipeline job or test - evidence first, flaky or real, the lowest layer that should have caught it, then the smallest fix. Never retries a test until it passes.
argument-hint: "[job name, test name, or paste the log]"
---
Arguments: $ARGUMENTS — the failing job or test. Ask for the job log, the junit report or `confidence.md` if
they are not in the conversation.

1. **Evidence.** Quote the failing assertion or error, the input, and what was expected. For a scorecard
   miss, the signal, measured value and threshold.
2. **Classify** — with the evidence for each:
   - **real defect** in the code;
   - **test defect** — the test is wrong about what the spec says;
   - **environment** — the deployed service, network, data, a cold start;
   - **flaky** — passes and fails on the same commit. Say how you know (re-run history, timing, shared
     state). Flaky is a finding, not a verdict: name the cause you suspect.
3. **Reproduce locally**, at the lowest layer possible. Propose the **regression test** that fails now — named
   `def_0nn_…` with a `DEF-0nn` ID — before any fix.
4. Propose the **smallest fix**. Wait for a yes. Then run the regression test green and the whole suite.
5. Write `specs/design/defects/DEF-0nn.md` (from `templates/defect-analysis.md`): evidence, cause, why the
   earlier layers missed it, the test that pins it, the fix.

Never re-run a failing test until it passes and call it fixed. Never loosen a threshold in the strategy to
make a scorecard pass — that is a spec change, decided by the group, in its own merge request.
