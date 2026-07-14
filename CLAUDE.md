# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`log_switch` is a small Ruby gem (~150 LOC in `lib/log_switch.rb`) that mixes a shared logger into a
class and lets logging be switched on/off programmatically. Last released 1.0.0 (2014); the
toolchain predates modern Ruby (see below).

## Commands

**The Bundler toolchain does not work on current Ruby.** `Gemfile` uses `source :rubygems`, which
modern Bundler rejects outright (`[REMOVED] The source :rubygems is disallowed`). So `bundle install`,
`bundle exec rspec`, and every `rake` task (`rake spec`, `rake test`, `rake yard`, the default task)
fail before running anything. Don't document or suggest them as working commands; don't "fix" the
Gemfile casually either, since the pinned deps in `Gemfile.lock` (rspec 2.12, tailor 1.1.2) won't
resolve on current Ruby anyway.

Run the specs with the system-installed rspec 3, bypassing Bundler:

```sh
# Full suite (18 examples, 1 pending)
ruby -Ispec -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["spec"], $stderr, $stdout)'

# Single example, by line number
ruby -Ispec -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["spec/log_switch_spec.rb:47"], $stderr, $stdout)'
```

`-Ispec` is required (spec_helper adds `lib/` itself). There is no `rspec` executable on PATH. The
specs were written for rspec 2 but use `expect` syntax and pass on rspec 3. Runs write a gitignored
`coverage/` directory via SimpleCov.

`tailor` (the style linter wired into `rake test`) is unavailable and unrunnable — note that it
depends on this very gem, so any circular-dependency confusion there is expected.

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
