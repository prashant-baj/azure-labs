# Lint configuration starters — what `qa:lint` reads

Copy the files for your stack into your **app folder** (the one with your build file). Instructions:
[`../CI-SETUP.md`](../CI-SETUP.md), section 1. Each was run against the stack starters in `../stacks/`.

| Stack | Files | Tools (pinned) |
|---|---|---|
| Python | `python/ruff.toml` | ruff 0.17.2 — the pipeline's version |
| Node | `node/eslint.config.mjs` (or `eslint.config.typescript.mjs`), `.prettierrc.json`, `.prettierignore` | eslint 9.39.5, @eslint/js 9.39.5, globals 16.5.0, prettier 3.6.2 (TypeScript: typescript 5.9.3, typescript-eslint 8.72.1) |
| Java | `java/pom-plugins.xml` (paste into your pom), `java/checkstyle.xml` | spotless-maven-plugin 2.46.1 with google-java-format 1.25.2, maven-checkstyle-plugin 3.6.0 with Checkstyle 10.21.4 |

Every config sets complexity to **10**. Change it to the limit in **your** rule E-003 — and set the same number
in `QA_COMPLEXITY_LIMIT` in `ci/quality.yml`.
