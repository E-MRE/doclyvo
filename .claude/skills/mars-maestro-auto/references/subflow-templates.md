# Subflow & config templates (copy into `.maestro/`, fill the `<PLACEHOLDERS>` live)

Everything here is a STARTER. Never ship a placeholder — replace each `<…>` with a value you
confirmed via `inspect` on the running app. Keep credentials in `.env` only.

---

## `config.yaml`
```yaml
# .maestro/config.yaml
appId: <com.example.app>        # from Info.plist / build.gradle
flows:
  - smoke/*
  - regression/*
# Single-locale contract — every text selector comes from this language's locale asset.
# (documentation only; set the device/emulator to this locale)
# locale: en-US
```

## `.env.example`  (copy to `.env`, which is gitignored)
```
# Dedicated test account. Injected at run time via the MCP `env` param / -e. Never commit real values.
TEST_EMAIL=you@example.com
TEST_PASSWORD=changeme
```

---

## `subflows/bootstrap.yaml` — reach a known logged-in home
```yaml
# Launches, skips first-run wizard, logs in ONLY if logged out, clears popups, lands on Home.
# clearState is OFF by default (session persists); set it true per-flow when you need isolation.
appId: <com.example.app>
---
- stopApp
- launchApp

# Skip a first-run welcome/onboarding wizard if present (anchor = a string unique to it).
- runFlow:
    when:
      visible: '<WELCOME_ANCHOR e.g. Already have an account\?[\s\S]*>'
    commands:
      - tapOn: '<GO_TO_LOGIN e.g. Already have an account\?[\s\S]*>'

# Log in ONLY when the login screen shows. Anchor on a string UNIQUE to logged-out
# (e.g. "Forgot password?") — never one shared with a button (e.g. "Login").
- runFlow:
    when:
      visible: '<LOGGED_OUT_ANCHOR e.g. Forgot password?>'
    commands:
      - runFlow: login.yaml

- runFlow: dismiss-popups.yaml

# Land on Home deterministically. Prefer a deep link if the app has one; else tap the Home tab.
- extendedWaitUntil:
    visible: '<HOME_ANCHOR e.g. a durable home label>'
    timeout: 15000
```

## `subflows/login.yaml` — credentials from env, never inline
```yaml
appId: <com.example.app>
---
- tapOn: '<EMAIL_FIELD_LABEL e.g. Email Address>'
- inputText: ${TEST_EMAIL}
- tapOn: '<PASSWORD_FIELD_LABEL e.g. Password>'
- inputText: ${TEST_PASSWORD}
- hideKeyboard
# If the submit control text also appears as a heading, disambiguate with index.
- tapOn:
    text: '<SUBMIT e.g. Login>'
    index: 1
# iOS may show a system "Save Password?" dialog right after — dismiss if present.
- runFlow:
    when:
      visible: "Save Password?"
    commands:
      - tapOn: "Not Now"
- waitForAnimationToEnd:
    timeout: 5000
```

## `subflows/dismiss-popups.yaml` — clear first-run interstitials (make every step optional)
```yaml
appId: <com.example.app>
---
- runFlow:
    when: { visible: "Allow" }            # notification / tracking permission
    commands: [{ tapOn: "Allow" }]
- runFlow:
    when: { visible: "Not Now" }
    commands: [{ tapOn: "Not Now" }]
- runFlow:
    when: { visible: '<IN_APP_MSG_CLOSE e.g. an X / Close on a marketing sheet>' }
    commands: [{ tapOn: '<IN_APP_MSG_CLOSE>' }]
# Add one optional block per real first-run popup you actually observe. Keep them all `when:`-guarded
# so the subflow is a no-op when nothing is showing.
```

## `subflows/goto-<screen>.yaml` — one cached navigation per mapped screen
```yaml
# e.g. goto-<screen>.yaml — bottom nav / menu path to a screen, confirmed live.
appId: <com.example.app>
---
- tapOn: '<NAV_LABEL>'
- extendedWaitUntil:
    visible: '<SCREEN_ANCHOR>'
    timeout: 30000
```

---

## Streaming-change assertion (prove a value is LIVE without asserting a number)
```yaml
- copyTextFrom:
    text: '<VOLATILE_ELEMENT_SELECTOR>'   # a row/label whose text includes the ticking value
- evalScript: ${output.v1 = maestro.copiedText}
- retry:
    maxRetries: 5
    commands:
      - waitForAnimationToEnd: { timeout: 4000 }
      - copyTextFrom: { text: '<VOLATILE_ELEMENT_SELECTOR>' }
      - evalScript: ${output.v2 = maestro.copiedText}
      - assertTrue: ${output.v1 != output.v2}   # string inequality — regex-special chars are harmless here
```

## Running a flow via MCP (inject creds through the `env` param)
- `run_flow_files` with `flow_files: ".maestro/smoke/<flow>.yaml"` and
  `env: {"TEST_EMAIL":"…","TEST_PASSWORD":"…"}` (read from `.maestro/.env`).
- Ad-hoc driving: `run_flow` with inline YAML; `tap_on` with `use_fuzzy_matching:false` for exact text.
