---
description: Write or extend the Postman collection in tests/api/ from the spec and the contracts - every test named after the ID it proves. Runs it with Newman against the local app.
argument-hint: "[slice folder] [base URL - default http://localhost:8000]"
---
Arguments: $ARGUMENTS — the slice folder and where the app runs locally. Read the spec (FR rows, *If* rows,
C- constraints), `specs/design/contracts/` if there are any, the routes in the code, and
`tests/api/*.postman_collection.json` if one exists.

1. List the endpoints and, for each, which requirement IDs it serves. Ask about any endpoint that serves none.
2. Propose requests and tests: the happy path **and** at least one failure path per requirement — wrong input
   (4xx), not allowed (403), duplicate, missing. Every `pm.test` name **starts with the ID** it proves
   (`"FR-004 counted once"`). Health first, as `SMOKE`, checking the version when `expectedVersion` is set.
3. **Data:** no hard-coded IDs that collide on a second run — generate unique references in a pre-request
   script. No secrets, tokens or personal data in the collection or environments; anything secret is a
   pipeline variable, passed with `--env-var`.
4. Show the collection diff; apply on a yes. Keep `{{baseUrl}}` everywhere — the same collection runs against
   the app in the pipeline and against the test environment.
5. Run it: `npx newman@6.2.3 run tests/api/<name>.postman_collection.json -e tests/api/local.postman_environment.json`
   and show the result. A test that passes against a broken endpoint is not a test — break one and check.
