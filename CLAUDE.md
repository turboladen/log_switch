# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Overview

`log_switch` is a small Ruby gem (~200 LOC in `lib/log_switch.rb`) that mixes a logger into a
class/module and lets logging be switched on/off programmatically, per includer. Develop is at
**2.0.0 (unreleased)** — a breaking change that made config per-includer with live inheritance (see
Architecture); last released 1.1.0 (2026), which broke a decade of silence after 1.0.0 (2014); the
dev toolchain sat broken for most of that gap and has been revived — Bundler works; see Commands.

## Commands

Bundler is the supported path and works on current Ruby:

```sh
bundle install

# Full suite (26 examples, 0 failures, 0 pending)
bundle exec rake              # default task -> :test -> [:spec, :rubocop, :dprint]
bundle exec rspec             # the same suite, directly
bundle exec rubocop           # the linter on its own

# Single example, by line number
bundle exec rspec spec/log_switch_spec.rb:47
```

The specs were written for rspec 2 but use `expect` syntax and pass unmodified on rspec 3. Runs
write a gitignored `coverage/` directory via SimpleCov.

### CI defines the supported Rubies — this file does not

`.github/workflows/ci.yml` is the authority on both the matrix and which gates run — read it rather
than trusting a summary here. Don't restate either: an earlier revision listed the jobs and went
stale once per gate added after it.

`required_ruby_version >= 3.3` is verified, not just asserted — the suite and RuboCop both pass on
the floor. CI exercises it on every change; a local run against whatever Ruby you happen to have
does not. Note `bundle exec` resolves `ruby` from `PATH` rather than from the interpreter running
Bundler, so use your version manager's exec wrapper to test a specific Ruby.

The binding constraint on that floor is a _transitive_ dep and is invisible in the gemspec:
`parallel` (via rubocop) requires `>= 3.3`, sitting exactly on it — not simplecov's `>= 3.2`, which
is merely the highest _direct_ floor. Walk transitive deps before trusting the floor.

There's no lockfile, so CI re-resolves every run. If `parallel` ever raises its floor above ours,
Bundler backtracks to an older version rather than failing, and the 3.3 job quietly tests a
different dependency set than 3.4/4.0 do. Expect silent skew, not a red build. Latent, not current —
all three Rubies resolve an identical set today.

### No `Gemfile.lock`

Deleted and gitignored. This is a library, not an app — the lock would only freeze dev deps, and
consumers resolve against the gemspec regardless. `bundle install` re-resolves.

### Fallback: running without Bundler

```sh
ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["spec"], $stderr, $stdout)'
```

No `-I` flag is needed, in this or any other form — rspec-core's `Configuration#requires=` puts
`lib` and the `spec` default_path on the load path itself, on every invocation path. Run it from the
repo root, since it resolves those relative to the cwd. (Verified against rspec-core 3.13.6. Earlier
revisions of this file documented an `-Ispec` that does nothing.)

**This bypass cannot see packaging defects, so never conclude the gem is healthy from it.** It loads
`lib/` off the filesystem instead of resolving the gem through Bundler, so a missing runtime
dependency is invisible. That is exactly how the missing `logger` dep went undetected — the gem was
unusable on Ruby 4.0 for every Bundler-managed consumer while this command reported a green suite.
CI's `package` job is the gate for that class of defect now — it builds the gem, unpacks it, and
requires it from a consumer bundle holding only the declared runtime deps. To check packaging
locally, reproduce that job; never infer it from this command.

Coverage differs between the two paths (64/74 under Bundler, 66/76 bypassed). Not a defect: the
`gemspec` directive makes Bundler `require` `log_switch/version` before `SimpleCov.start`, so
version.rb's 2 lines go untracked.

### RuboCop is the linter

`rake test` runs `[:spec, :rubocop, :dprint]`. The whole tree — `lib/` included — is now clean:
`.rubocop_todo.yml` is empty, kept only as the inherited parent so `.rubocop.yml`'s pins can override
a regeneration (see below). A new violation still fails the gate.

For years `lib/log_switch.rb` was held byte-identical to its 1.0.0 release, so all its offenses sat
quarantined rather than fixed. **2.0.0 deliberately retired that invariant** — it was the release that
could carry breaking change. The config-state refactor cleared `Style/ClassVars` by removing the class
variables outright (their absence is now the regression test for the config-leak bug); `#log` was
split into a `write_message` helper + guard clause for `Metrics/AbcSize`/`MethodLength`/`GuardClause`;
`STDOUT` became `$stdout` (`Style/GlobalStdStream` — the default logger now follows a reassigned
`$stdout`); and `frozen_string_literal` went tree-wide, which froze `LogSwitch::VERSION` (API-observable,
which is why it shipped in the major). `RuboCop::RakeTask` still exposes `rake rubocop:autocorrect_all`
— hand-edit `lib/` instead so behavioral changes stay deliberate.

`tailor` used to be wired in here and was removed. It installed fine — pure Ruby, no
`required_ruby_version` — so "tailor doesn't build" (an old claim in this file) was never true. The
real reason is a runtime dependency cycle back onto this gem, and the versions differ: tailor 1.1.2
(what `Gemfile.lock` froze) needs `log_switch >= 0.3.0`, which 1.0.0 satisfies; tailor 1.4.1 needs
`~> 0.3.0`, which it does not. The cycle silently pinned the linter to a 2012-era release.

**`.rubocop.yml` is policy; `.rubocop_todo.yml` is debt.** Policy is what we choose never to enforce
(RSpec block length) or always enforce (modern style). Debt is what we intend to fix — and it is now
empty. The lone entry that used to straddle the split
(`Layout/SpaceAroundEqualsInParameterDefault`, a policy pin carrying a debt `Exclude` for `lib/`)
lost its Exclude when `lib/` was cleaned; it is now a plain defensive-default pin alongside
`Style/HashSyntax` and `Style/SpecialGlobalVars`.

To regenerate the todo:

```sh
bundle exec rubocop --auto-gen-config --auto-gen-only-exclude --no-exclude-limit
```

**`--auto-gen-config` inverts the project's style, and `--auto-gen-only-exclude` does not stop it.**
For a cop whose offences are self-consistent it writes an `EnforcedStyle` into the todo — a
permanent policy change, filed under a name that reads as temporary. Verified: even with the flag it
still emits `hash_rockets`, `use_perl_names`, `no_space`, `brackets`. **Convert any `EnforcedStyle:`
in the regenerated todo to `Exclude:` by hand**, and expect `rake test` to be RED in between. The
pins in `.rubocop.yml` exist to override this and must win.

## Architecture

Single file: `lib/log_switch.rb`, defining three pieces.

- `LogSwitch.included(base)` delegates to `LogSwitch.register_includer(includer, parent)` — the
  entry point. It records `includer` in `@includers` (used only by `reset_config!`, de-duplicated),
  sets `@log_switch_parent` (the config fall-through link — `nil` for a direct includer), extends
  `ClassMethods`, includes `InstanceMethods`, and **redefines `includer.included`** so the mixin
  cascades to arbitrary depth: including a LogSwitch-including module elsewhere propagates both method
  sets and the parent link. (A consequence: an intermediate cascading module that defines its own
  `self.included` is unsupported — this redefinition shadows it.)
- `ClassMethods` — the config surface: `logging_enabled`, `default_log_level`, `log_class_name`,
  `logger`, `before_log`. Each reader is `read_config(ivar, reader) { default }` (see below).
- `InstanceMethods#log(message, level = nil)` — calls the `before_log` hook, yields an optional
  block, then `return unless logging_enabled?` and delegates to the private `write_message`.
  Multi-line input is split via `each_line` and logged one line per call; anything not responding to
  `each_line` is logged whole.

### Config state is per-includer with live inheritance (2.0.0)

Config lives in **per-includer singleton ivars** (`@logging_enabled`, `@log_class_name`,
`@default_log_level`, `@logger`, `@before_block`) on each includer object — not class variables.
Because `ClassMethods` is `extend`ed onto each includer, method bodies run with `self` = that
includer, so the ivars are naturally per-class. Verified: `A.logging_enabled = true` leaves
`B.logging_enabled?` `false`.

Reads fall through the include chain via the private `read_config(ivar, reader)`: return the local
ivar if `instance_variable_defined?`, else `@log_switch_parent.public_send(reader)` (which applies
its own fall-through, composing to any depth), else the block default. Writers are plain local
assignments, so a write shadows the parent locally without touching the parent or any sibling.
`reset_config!` `remove_instance_variable`s each of `CONFIG_VARIABLES` (restoring fall-through) but
deliberately keeps `@log_switch_parent`, which is structural.

This is what 1.0.0's CHANGELOG claimed ("toggling logging per includer") but never delivered; the
2.0.0 entry corrects the record forward without rewriting the 1.0.0 entry.

Three bugs the old class-variable design carried, all now fixed with regression specs (this is the
substance of the 2.0.0 config refactor): config leaked across every includer (shared `@@` slot);
`log_class_name = false` never stuck (the `||= true` reader flipped a stored `false` back); and
`before_log=` silently ignored every hook after the first (`@@before_block ||= block`). The readers
no longer memoize with `||=`, so a stored `false`/`nil` is honored — note the flip side, filed as a
follow-up: `logger = nil` now sticks and would `NoMethodError` in `#log`.

Two design edges of the per-includer model are tracked as open follow-ups, not bugs to fix blindly:
a **subclass** of an includer does not inherit its config (singleton ivars aren't inherited); and
`@includers` holds every includer by strong reference forever.

## Conventions

- Docs are Markdown. YARD tags (`@param`, `@return`) annotate the source.
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/); newest first — add an
  entry for user-facing changes, and a link reference for each new version.
- The version lives in `lib/log_switch/version.rb` and is asserted by a spec
  (`specify { expect(LogSwitch::VERSION).to eq '...' }` in `spec/log_switch_spec.rb`), so bumping it
  means updating that expectation too. Cited by name, not line: an earlier revision pointed at a
  line number that had drifted onto the `describe`.
- The gemspec's `summary` and `description` are single source lines and deliberately distinct
  strings. They were multi-line literals until 2.0.0, where `description` published an embedded
  newline + ~20 spaces of indentation to rubygems.org; collapsing it fixed that, and it is worded
  differently from `summary` because byte-identical strings make `gem build` warn. **After any
  gemspec change, diff the _loaded_ spec (`Gem::Specification.load`), not the source** — a formatting
  cop once silently altered `description` that way. RubyGems normalizes `summary=` on assignment but
  publishes `description=` verbatim, so keep both on one line.
- `Gem::Specification#validate` **raises** on an `s.files` entry that doesn't exist; it does not
  warn. Edit the list and the filesystem in the same step.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->

## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and
commands.

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

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git
remote; `.beads/issues.jsonl` is a passive export. See
https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or
orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or
  Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and
  suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git
  policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run
  quality gates, commit, and push as part of session close. A current "do not commit" or "do not
  push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit
user, repository, and orchestrator instructions.

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
