# Your stack — four things the confidence pipeline needs from your code

The pipeline is the same for every group. It needs four things your code provides — once.

## 1. A health endpoint that says which version it is

`GET /health` → `200 {"status": "ok", "version": "<APP_VERSION>"}`. The pipeline sets `APP_VERSION` to the
commit; `verify:smoke` waits until the deployed service answers with **this** commit — not the last one.

| Stack | Minimal |
|---|---|
| Python (FastAPI) | `@app.get("/health")` → `{"status": "ok", "version": os.getenv("APP_VERSION", "local")}` |
| Node (Express) | `app.get('/health', (_, res) => res.json({ status: 'ok', version: process.env.APP_VERSION ?? 'local' }))` |
| Java (Spring Boot) | a `@GetMapping("/health")` returning the same map, with `@Value("${APP_VERSION:local}")`. (Actuator's `/actuator/health` has no version — keep it for Session 16) |

Different path? Set `HEALTH_PATH` in `ci/confidence.yml`.

## 2. Test reports the scorecard can read — your `test` job, complete

Your own `test` job (from Session 10) must write a **junit** report and a **coverage** report **at the root of the
repository**, and keep both as artifact *paths* — the scorecard job reads them from there. Replace your `test:` job
in `.gitlab-ci.yml` with the one for your stack. Each was run against a starter project; only `APP_DIR` (and, for
Python, `COV_SOURCE`) should need changing.

**Python — pytest, pytest-cov**

```yaml
test:
  stage: test
  image: python:3.12-slim
  tags: [junior-SWAT-engineers-program]
  variables:
    APP_DIR: "."                    # the folder with requirements.txt / pyproject.toml - as in ci/confidence.yml
    COV_SOURCE: "."                 # your package, e.g. "app" or "src" - "." measures everything under APP_DIR
  script:
    - cd "$APP_DIR"
    - if [ -f requirements.txt ]; then pip install --quiet -r requirements.txt; else pip install --quiet -e .; fi
    - pip install --quiet pytest pytest-cov
    - python -m pytest -q --junitxml="$CI_PROJECT_DIR/report.xml" --cov="$COV_SOURCE" --cov-report=xml:"$CI_PROJECT_DIR/coverage.xml" --cov-report=term
  coverage: '/TOTAL.*\s(\d+(?:\.\d+)?)%/'
  artifacts:
    when: always
    paths: [report.xml, coverage.xml]
    reports:
      junit: report.xml
      coverage_report: { coverage_format: cobertura, path: coverage.xml }
```

**Node — pick the line for your test runner**

```yaml
test:
  stage: test
  image: node:22
  tags: [junior-SWAT-engineers-program]
  variables:
    APP_DIR: "."                    # the folder with package.json
  script:
    - cd "$APP_DIR"
    - npm ci
    # Jest   (npm i -D -E jest-junit@17.0.0):
    - JEST_JUNIT_OUTPUT_DIR="$CI_PROJECT_DIR" npx jest --ci --reporters=default --reporters=jest-junit --coverage --coverageReporters=cobertura --coverageReporters=text-summary --coverageDirectory="$CI_PROJECT_DIR/coverage"
    # Vitest (npm i -D -E @vitest/coverage-v8@<your vitest version>) - instead of the Jest line:
    # - npx vitest run --reporter=default --reporter=junit --outputFile.junit="$CI_PROJECT_DIR/junit.xml" --coverage.enabled --coverage.provider=v8 --coverage.reporter=cobertura --coverage.reporter=text-summary --coverage.reportsDirectory="$CI_PROJECT_DIR/coverage"
    # node:test (npm i -D -E c8@10.1.3) - instead of the Jest line:
    # - npx c8 --reporter=cobertura --reporter=text-summary --reports-dir="$CI_PROJECT_DIR/coverage" node --test --test-reporter=spec --test-reporter-destination=stdout --test-reporter=junit --test-reporter-destination="$CI_PROJECT_DIR/junit.xml"
  coverage: '/Lines\s*:\s*(\d+(?:\.\d+)?)%/'
  artifacts:
    when: always
    paths: [junit.xml, coverage/cobertura-coverage.xml]
    reports:
      junit: junit.xml
      coverage_report: { coverage_format: cobertura, path: coverage/cobertura-coverage.xml }
```

**Java — Maven, Surefire, JaCoCo.** First add JaCoCo to `<build><plugins>` in your `pom.xml`:

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.12</version>
  <executions>
    <execution><goals><goal>prepare-agent</goal></goals></execution>
    <execution><id>report</id><phase>test</phase><goals><goal>report</goal></goals></execution>
  </executions>
</plugin>
```

```yaml
test:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  tags: [junior-SWAT-engineers-program]
  variables:
    APP_DIR: "."                    # the folder with pom.xml
    MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2"
  cache:
    paths: [.m2/]
  script:
    - cd "$APP_DIR"
    - mvn -B test                   # unit tests and scenarios (RunScenariosTest); JaCoCo writes its report
    - |                             # the line-coverage figure, for the merge request
      awk -F',' 'NR>1 { m += $8; c += $9 } END { if (m+c) printf "Line coverage: %.1f%%\n", 100*c/(m+c) }' target/site/jacoco/jacoco.csv
  coverage: '/Line coverage: (\d+(?:\.\d+)?)%/'
  artifacts:
    when: always
    paths:                          # APP_DIR not "."? Put it in front of both paths
      - target/surefire-reports/
      - target/site/jacoco/jacoco.xml
    reports:
      junit: target/surefire-reports/TEST-*.xml
      coverage_report: { coverage_format: jacoco, path: target/site/jacoco/jacoco.xml }
```

**On your laptop**, the same commands produce the same files — run from the root of your repo with
`CI_PROJECT_DIR` set to it, then ask the scorecard (section 5 of the workshop guide):

```bash
export CI_PROJECT_DIR="$PWD"                 # PowerShell: $env:CI_PROJECT_DIR = (Get-Location).Path
# ...your stack's test line from above, run in APP_DIR...
python3 ci/confidence.py --when merge        # reads report.xml / junit.xml / surefire, coverage, and your strategy
```

The scorecard finds `report.xml`, `scenarios.xml`, `**/junit*.xml`, `**/target/surefire-reports/TEST-*.xml`,
`coverage.xml`, `**/cobertura-coverage.xml` and `**/target/site/jacoco/jacoco.xml`. Coverage also appears in the
merge request.

## 3. How to start your app — for `api:local`

`APP_START` in `ci/confidence.yml`, run from `APP_DIR` after the job installed your dependencies:

| Stack | `APP_START` |
|---|---|
| Python | `uvicorn app.main:app --port 8000` |
| Node | `npm start` (your `start` script reads `PORT`) |
| Java | `java -jar target/*.jar` (Spring Boot reads `SERVER_PORT`) |

The app must start **without** a cloud database or secret — an in-memory or file store when no connection is
configured. If yours cannot, that is a finding for Session 16 (configuration and secrets); leave `APP_START`
empty and rely on `verify:api` after deploy for now.

## 4. A Dockerfile in `APP_DIR`

Session 12 wrote one. It must listen on `PORT` (`APP_PORT` in the pipeline) and read `APP_VERSION` from the
environment. `build:image` builds it **in Azure** (`az acr build`) — no Docker on the runner, none on your
laptop.
