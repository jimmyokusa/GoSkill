---
name: goskill
description: >-
  Conventions for structuring and writing Go backend services — package
  layout, module organization, naming, and idiomatic project skeleton. Use
  when creating a new Go backend service, adding a package/module to an
  existing one, or reviewing Go code for structural/naming conventions.
---

# GoSkill

Guidance for structuring Go backend services idiomatically. This skill
governs **where code goes and how it's named** — not business logic.

## Project layout

Use this skeleton for a new service (adapt package names to the domain):

```
myservice/
  cmd/
    myservice/
      main.go          # thin entrypoint: wiring only, no business logic
  internal/
    <domain>/           # one package per bounded concern, e.g. order, user
      <domain>.go        # types + interfaces
      service.go          # business logic
      repository.go        # storage interface + implementation
      handler.go            # HTTP/gRPC transport layer
    config/
      config.go
    platform/            # cross-cutting infra: db, logger, http client
      postgres/
      httpserver/
  pkg/                  # only for code intended to be imported by other repos
  go.mod
  go.sum
```

Rules:
- `internal/` holds everything not meant for external import — this is almost
  everything in a backend service. Only put code in `pkg/` if another repo is
  expected to import it.
- One directory per bounded domain concern under `internal/`, not one giant
  `internal/models` + `internal/handlers` split across the whole app. Group by
  what the code is about, not by technical layer.
- `cmd/<binary>/main.go` only wires dependencies (config load, DB connect,
  router setup, graceful shutdown) and calls into `internal/`. No logic lives
  in `main.go` itself.

## Naming

- Package names: short, lowercase, no underscores or mixedCaps (`order`, not
  `order_service` or `orderService`).
- Avoid stutter: `order.Service`, not `order.OrderService`. Callers already
  see the package name at the call site (`order.NewService(...)`).
- File names: lowercase snake_case matching their content (`repository.go`,
  `repository_test.go`), not `Repository.go`.
- Interfaces are named for what they do, not prefixed with `I` — `Repository`,
  not `IRepository`. Small interfaces defined at the point of use (consumer
  side), not alongside the implementation.

## Error handling

- Wrap errors with context using `fmt.Errorf("doing X: %w", err)` at each
  layer boundary (repository → service → handler) so a caller can `errors.Is`/
  `errors.As` through the chain.
- Sentinel errors for expected conditions live in the domain package
  (`order.ErrNotFound`), not as generic strings compared elsewhere.

## Dependencies

- Constructor injection (`NewService(repo Repository, logger *slog.Logger)`),
  no globals, no package-level `init()` for wiring.
- `go.mod` module path matches the repo's import path; keep `go.mod`/`go.sum`
  committed and run `go mod tidy` before committing dependency changes.

## Linting

Copy `.golangci.yml` from this skill into the target repo's root. Run
`golangci-lint run ./...` before considering Go work done — it enables
`govet`, `staticcheck`, `errcheck`, `revive`, `gosec`, and related checks
(see the file for the full set and rationale per-linter).

## Development loop

Changes are small, branched, tested, and reviewed before they reach the
default branch. For each change:

1. **Branch.** Cut a branch off the default branch (`main`) for one small,
   self-contained change. Don't stack unrelated changes on one branch.
2. **Implement + test.** Make the change. Update or add unit tests for the
   affected package(s), and update the end-to-end tests if the change
   touches externally observable behavior (API responses, CLI output,
   schema). A change isn't done until its tests are, in the same branch.
3. **Lint.** Run `golangci-lint run ./...` on the branch and fix everything
   it reports before moving on (see Linting above).
4. **Review the diff.** Invoke the `go-reviewer` subagent
   (`.claude/agents/go-reviewer.md` — copy into the target repo's
   `.claude/agents/`) against the branch's diff against `main`
   (`git diff main...HEAD`), not the whole tree. It checks lint results,
   conformance to the [Google Go Style Guide](https://google.github.io/styleguide/go/),
   and standard Go idioms (Effective Go, Go Code Review Comments). It is
   read-only — it reports findings, it does not fix them — so implementation
   and review stay independent passes. Address findings and re-review until
   there's nothing left to flag.
5. **Merge.** On approval, merge the branch into the default branch locally.
6. **Push.** Push the default branch to the remote (`git push`).

Review always runs against a real diff on a branch, never against
work-in-progress on the default branch directly.

## Testing the skill itself

This skill is tested with [skillgrade](https://github.com/mgechev/skillgrade)
(`npm i -g skillgrade`), which checks that an agent given this SKILL.md can
actually discover and correctly follow the development loop above — not
just that the loop is documented correctly. `eval.yaml` defines one task,
`catches-issues`, that materializes a fixture repo
(`fixtures/catches-issues/fixture.bundle`, a two-branch git bundle with a
feature branch adding an unchecked-error and a missing test) and checks
that following the skill's review step actually surfaces both problems
(`graders/check-catches-issues.sh`).

Run it with:

```
skillgrade --provider=docker --agent=claude   # sandboxed, needs ANTHROPIC_API_KEY
```

or, to reuse an already-authenticated local `claude` CLI instead of a raw
API key (runs unsandboxed on the host — only do this if you trust the
fixtures, which by default only run `git`/`golangci-lint`/`go`):

```
skillgrade --provider=local --agent=command --command="claude -p --permission-mode bypassPermissions"
```

`skillgrade preview` (or `skillgrade preview browser`) shows the results
after a run.
