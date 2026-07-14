# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`log_switch` is a small Ruby gem (~150 LOC in `lib/log_switch.rb`) that mixes a shared logger into a
class and lets logging be switched on/off programmatically. Last released 1.0.0 (2014). The dev
toolchain sat broken for a decade and has been revived — Bundler works; see Commands.

## Commands

Bundler is the supported path and works on current Ruby:

```sh
bundle install

# Full suite (18 examples, 0 failures, 1 pending)
bundle exec rake              # default task -> :test -> :spec
bundle exec rspec             # the same suite, directly

# Single example, by line number
bundle exec rspec spec/log_switch_spec.rb:47
```

Verified on Ruby 3.4.9 and 4.0.5. The gemspec sets `required_ruby_version >= 3.3`. The specs were
written for rspec 2 but use `expect` syntax and pass unmodified on rspec 3. Runs write a gitignored
`coverage/` directory via SimpleCov.

### No `Gemfile.lock`

Deleted and gitignored. This is a library, not an app — the lock would only freeze dev deps, and
consumers resolve against the gemspec regardless. `bundle install` re-resolves.

### Fallback: running without Bundler

```sh
ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["spec"], $stderr, $stdout)'
```

No `-I` flag is needed, in this or any other form — rspec-core's `Configuration#requires=` puts `lib`
and the `spec` default_path on the load path itself, on every invocation path. Run it from the repo
root, since it resolves those relative to the cwd. (Verified against rspec-core 3.13.6. Earlier
revisions of this file documented an `-Ispec` that does nothing.)

**This bypass cannot see packaging defects, so never conclude the gem is healthy from it.** It loads
`lib/` off the filesystem instead of resolving the gem through Bundler, so a missing runtime
dependency is invisible. That is exactly how the `logger` dep went missing — the gem was unusable on Ruby 4.0 for
every Bundler-managed consumer — went undetected while this command reported a green 18/0/1. To test
packaging, install the gem into a scratch consumer bundle via a `path:` source and require it.

Coverage differs between the two paths (50/65 under Bundler, 52/67 bypassed). Not a defect: the
`gemspec` directive makes Bundler `require` `log_switch/version` before `SimpleCov.start`, so
version.rb's 2 lines go untracked.

### No linter is wired up

`rake test` runs specs only. `tailor` used to be wired in and was removed: last released 2014-11-05,
and it declares `log_switch ~> 0.3.0` as a *runtime* dep — a cycle back onto this gem, and one that
can't even resolve against 1.0.0. RuboCop is the intended replacement, not yet added.

## Architecture

Single file: `lib/log_switch.rb`, defining three pieces.

- `LogSwitch.included(base)` — the entry point. Extends `base` with `ClassMethods`, includes
  `InstanceMethods`, records `base` in `@includers` (used only by `reset_config!`), and **redefines
  `base.included`** so the mixin cascades: including `LogSwitch` into your own module, then including
  that module elsewhere, propagates both method sets.
- `ClassMethods` — the config surface: `logging_enabled`, `default_log_level`, `log_class_name`,
  `logger`, `before_log`.
- `InstanceMethods#log(message, level = nil)` — calls the `before_log` hook, yields an optional block,
  and only writes if `logging_enabled?`. Multi-line input is split via `each_line` and logged one line
  per call; anything not responding to `each_line` is logged whole.

### Config state is global, not per-includer

`ClassMethods` stores config in **class variables** (`@@logging_enabled`, `@@log_class_name`,
`@@default_log_level`, `@@logger`, `@@before_block`). Because they're declared in the `ClassMethods`
module body, they live on that module — every class that includes `LogSwitch` shares one slot.
Verified: `A.logging_enabled = true` makes `B.logging_enabled?` return `true`.

This contradicts History.rdoc's 1.0.0 claim that the rewrite "allows toggling logging per includer."
It does not. Treat any per-class isolation requirement as a real design change (`@ivars` on the
singleton, or `class_attribute`-style inheritance), not a tweak.

### The `||=` default-reader bug

Readers memoize with `||=` against a truthy default:

```ruby
def log_class_name
  @@log_class_name ||= true    # a stored `false` is overwritten on the next read
end
```

So `log_class_name = false` never sticks — the reader flips it back to `true`. This is the cause of
the spec at `spec/log_switch_spec.rb:64` marked `pending "Can't figure out why this doesn't pass. It
works live..."`. It does not work live; the reader is the bug. `logging_enabled` has the same shape
but is harmless only because its default (`false`) is already falsy. `before_log=` has a related
defect: it's written `@@before_block ||= block`, so the setter silently ignores every hook after the
first.

Fixing the reader will un-pend that spec — update the spec rather than leaving the `pending` in place.

## README.rdoc is stale — do not trust it

Commit ec6a5f3 ("Rewrite to simplify for 1.0.0") rewrote `lib/` and `spec/` and deleted
`lib/log_switch/mixin.rb`, but left README.rdoc untouched. Everything the README documents is the
pre-1.0.0 API, and it is verified broken:

| README shows | Reality in 1.0.0 |
|---|---|
| `extend LogSwitch` | Only `include LogSwitch` works; `extend` defines no `log` (`NoMethodError`) |
| `MyThing.log "msg"` (class-level) | `log` is an *instance* method — `MyThing.new.log "msg"` |
| `LogSwitch::Mixin` | Removed; the constant does not exist |
| `MyThing.log = false` | `MyThing.logging_enabled = false` |
| `MyThing.log_level = :warn` | `MyThing.default_log_level = :warn` |
| `MyThing.before { }` | `MyThing.before_log = Proc.new { }` |

`spec/log_switch_spec.rb` is the accurate description of the current API. Use it, not the README, as
the reference. Logging is **off by default** (`logging_enabled` defaults to `false`), which surprises
people expecting output from a fresh includer.

## Conventions

- Docs are RDoc (`.rdoc`), not Markdown; YARD tags (`@param`, `@return`) annotate the source.
- `History.rdoc` is a hand-maintained changelog, newest first — add an entry for user-facing changes.
- The version lives in `lib/log_switch/version.rb` and is asserted by a spec, so bumping it means
  updating `spec/log_switch_spec.rb:7` too.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
