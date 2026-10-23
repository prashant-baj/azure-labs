# Test deployment record - lab 09c

Fill this in after your first green deployment on main, and commit it in your **second** merge request
(the one that also changes `message` in `infra-test/variables.tf`). That second merge deploys again -
the page must then show the new commit.

| | |
|---|---|
| Pipeline (first deploy) | <!-- https://gitlab.stackroute.in/<group>/<project>/-/pipelines/NNN --> |
| Site URL | <!-- https://st....z13.web.core.windows.net/ --> |
| Commit shown on the page | <!-- short SHA --> |
| Signed in with | <!-- OIDC or fallback secret: copy the line from the cdtest:state log --> |
| Pipeline (second deploy) | <!-- the pipeline that rolled out your changed message --> |
| Destroyed | <!-- yes, by cdtest:destroy on <date> / auto-stop --> |

## What we learned

<!-- Two or three lines: what failed first, and what you would change before pointing this at infra/. -->
