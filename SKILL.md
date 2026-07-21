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

## Review

Code review is decoupled from implementation: use the `go-reviewer` subagent
(`.claude/agents/go-reviewer.md` in this skill — copy into the target repo's
`.claude/agents/`) to review Go changes. It checks lint results, conformance
to the [Google Go Style Guide](https://google.github.io/styleguide/go/), and
standard Go idioms (Effective Go, Go Code Review Comments). It is read-only:
it reports findings rather than fixing them, so implementation and review
stay independent passes.
