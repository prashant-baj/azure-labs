# Node / TypeScript — cucumber-js

```
package.json                    devDependency @cucumber/cucumber; "test" and "scenarios" scripts
cucumber.mjs                    where the features and steps are; junit report; strict
features/month_paid.feature     in your repo: specs/NNN-<slice>/features/
src/monthStatus.mjs             the rule - built test-first; amounts in paise (integers)
test/monthStatus.test.mjs       unit tests (node:test) - Jest or Vitest work the same way
steps/monthPaid.steps.mjs       thin steps
```

## Wire it into your repo

1. `npm install --save-dev @cucumber/cucumber`
2. `cucumber.mjs` at the root of your app:
   ```js
   export default {
     paths: ['../specs/*/features/**/*.feature'],   // relative to the app folder
     import: ['steps/**/*.mjs'],                      // TypeScript: see below
     format: ['progress', 'junit:scenarios.xml'],
     strict: true,
   };
   ```
3. `package.json` script: `"scenarios": "cucumber-js"`.
4. `ci/scenarios.yml` (setup-quality adds it) runs `npx cucumber-js` with a junit report.

**TypeScript:** name steps `*.steps.ts` and load them with `import: ['steps/**/*.ts']` plus
`"loader": ["ts-node/esm"]` (or run through `tsx`). Keep the steps thin either way.

## Gotchas

- Use `function () {}` in steps, not arrow functions — `this` is the scenario's World, fresh each scenario.
- `{int}` and `{}` are Cucumber expressions; `{}` takes the rest as text.
- Money: integer paise, or a decimal library. Never `0.1 + 0.2`.
