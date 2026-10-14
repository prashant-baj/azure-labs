# Switch Claude Code from the lab key to your own licence

The lab's OpenRouter keys have been **revoked** now that everyone has a Claude licence from their
organisation. If you set up Claude Code with the lab key (`claude-code-setup.md`), it will now fail
— usually with an authentication error, or by hanging — until you remove that setup. Five minutes.

## Step 1 — Remove the lab settings

Open your Claude Code settings file:

| | Settings file |
|---|---|
| Windows | `%USERPROFILE%\.claude\settings.json` — press `Win+R`, type `notepad %USERPROFILE%\.claude\settings.json`, Enter |
| macOS / Linux | `~/.claude/settings.json` |

Delete these lines from the `"env"` block — **all of them**, including the empty one:

```
"ANTHROPIC_BASE_URL": ...
"ANTHROPIC_AUTH_TOKEN": ...
"ANTHROPIC_API_KEY": ""
"ANTHROPIC_DEFAULT_SONNET_MODEL": ...
"ANTHROPIC_DEFAULT_HAIKU_MODEL": ...
"ANTHROPIC_DEFAULT_OPUS_MODEL": ...
```

If the `"env"` block is now empty, delete it too. Keep any other settings you added yourself, and
mind the commas — the file must still be valid JSON. If the lab setup was the only thing in it, the
file can simply be `{}`.

**Also check** that none of those names is set as a system or user environment variable (Windows:
*Start → "Edit environment variables for your account"*; macOS/Linux: your shell profile). An
environment variable overrides your sign-in.

## Step 2 — Turn the sign-in prompt back on

In VS Code: **Settings** (`Ctrl+,` / `Cmd+,`) → search **Claude Code: Disable Login Prompt** → **untick** it.
Then **close VS Code completely** and open it again.

## Step 3 — Sign in with your organisation's account

Open the Claude Code panel. It asks you to sign in — use the account your organisation gave you.
In the terminal version, type `/login`. If it still shows the old setup, type `/logout`, then `/login`.

## Step 4 — Check

Type `/status` in Claude Code. It should show **your** account, not a custom base URL or an API
token. Then run any command you used before, for example `/task-plan`.

## Two reminders

- **Your licence is for the coding tool.** It is not an API key, and it must never be put into your
  product, a `.env` file or a CI variable for the product.
- **The pipeline's AI review** uses `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` — and only if
  your organisation allows its licence to be used on this GitLab (see `09-session11-12-ai-engineering`).
