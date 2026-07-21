# GoSkill

A Claude Code Skill for Go backend development, plus a decoupled review
subagent to enforce it.

## Contents

- **`SKILL.md`** — conventions for structuring and writing Go backend
  services: `cmd`/`internal`/`pkg` project layout, naming, error handling,
  dependency injection, linting, and the branch/test/lint/review/merge
  development loop.
- **`.golangci.yml`** — golangci-lint (v2 schema) config enabling `govet`,
  `staticcheck`, `errcheck`, `revive`, `gosec`, `bodyclose`, `sqlclosecheck`,
  `noctx`, plus `gofmt`/`goimports` formatters.
- **`.claude/agents/go-reviewer.md`** — a read-only subagent that reviews a
  branch's diff against the default branch. It runs the linter, then checks
  conformance to the
  [Google Go Style Guide](https://google.github.io/styleguide/go/) and
  standard Go idioms (Effective Go, Go Code Review Comments), flags missing
  test coverage, and checks structural fit with the layout in `SKILL.md`. It
  reports findings only — it never edits code — so review stays a separate
  pass from implementation.

- **`eval.yaml`** / **`fixtures/`** / **`graders/`** — a
  [skillgrade](https://github.com/mgechev/skillgrade) eval that verifies an
  agent given this skill actually follows the review step correctly against
  a fixture with a known lint violation and a known test-coverage gap. See
  "Testing the skill itself" in `SKILL.md`.

## Usage

Copy `.golangci.yml` and `.claude/agents/go-reviewer.md` into the target
repo's root and `.claude/agents/` respectively. Follow the development loop
in `SKILL.md`: branch per change, implement with tests, lint, invoke
`go-reviewer` against the branch diff, merge on approval, push.

## Testing

`skillgrade --provider=docker --agent=claude` (or see `SKILL.md` for a
local-provider alternative). Requires `npm i -g skillgrade`.
