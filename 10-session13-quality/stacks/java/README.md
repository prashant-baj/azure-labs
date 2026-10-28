# Java / Maven — Cucumber-JVM on the JUnit Platform

```
pom.xml                                     junit-bom + cucumber-bom; four test dependencies
features/month_paid.feature                 in your repo: specs/NNN-<slice>/features/
src/main/java/dues/MonthStatus.java         the rule - built test-first; BigDecimal
src/test/java/dues/MonthStatusTest.java     unit tests, one per example (JUnit 5)
src/test/java/dues/RunScenariosTest.java    the runner: which folder, which glue, junit report
src/test/java/dues/MonthPaidSteps.java      thin steps
```

## Wire it into your repo

1. `pom.xml`: copy the two BOMs into `<dependencyManagement>` and the four test dependencies
   (`junit-jupiter`, `junit-platform-suite`, `cucumber-java`, `cucumber-junit-platform-engine`).
2. Copy `RunScenariosTest.java` into your test package. Point it at the spec:
   `@SelectDirectories("../specs")` if your `pom.xml` is in a sub-folder, `"specs"` if it is at the root.
   Set `GLUE_PROPERTY_NAME` to your step package.
3. `mvn test` runs unit tests and scenarios together — your existing `test` job runs them already.
4. `ci/scenarios.yml` (setup-quality adds it) runs only `RunScenariosTest`, with its own report.

**Spring Boot?** Add `cucumber-spring` and one `@CucumberContextConfiguration @SpringBootTest` class in the
glue package — but start with plain objects: most rules need no Spring at all.

## Gotchas

- Compare `BigDecimal` with `compareTo`, not `equals` (`2500` and `2500.00` are not `equals`).
- Step classes get a fresh instance per scenario — fields are safe; `static` fields are not.
