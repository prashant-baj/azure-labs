// cucumber-js reads this file. In your repo: paths -> 'specs/*/features/**/*.feature'.
export default {
  paths: ['features/**/*.feature'],
  import: ['steps/**/*.mjs'],
  format: ['progress', 'junit:scenarios.xml'],   // the junit file is the merge request's test report
  strict: true,                                   // an undefined step is a failure, not a skip
};
