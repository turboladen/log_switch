# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking:** configuration is now per-includer with live inheritance. Each class or module that
  includes `LogSwitch` (directly or through a module that includes it) reads each setting from its
  parent in the include chain until it assigns its own value; writes are local and never affect the
  parent or sibling includers. Previously all includers shared one global slot via class variables,
  so enabling logging on one class enabled it everywhere. The 1.0.0 entry below claimed "toggling
  logging per includer" but that was never delivered until now.
- The default logger now writes to `$stdout` rather than the `STDOUT` constant, so it follows a
  reassigned `$stdout` (test capture, daemonization). Reassign `$stdout` before the logger is first
  built, or before `reset_config!`, to redirect the default output.
- `LogSwitch::VERSION` is now frozen (`LogSwitch::VERSION.frozen?` is `true`); it was mutable before.

### Fixed

- `log_class_name = false` now sticks. The reader memoized with `||=` against a `true` default, so a
  stored `false` was flipped back to `true` on the next read.
- `before_log=` now keeps the most recently assigned hook. It memoized with `||=`, silently
  discarding every assignment after the first.

## [1.1.0] - 2026-07-15

### Added

- Declared the license (Unlicense) in the gemspec; the LICENSE file now ships with the gem.
- The gemspec now declares a `changelog_uri`, so rubygems.org links to the changelog. It points at
  the released version's tag rather than a branch, so each release's link is immutable.

### Changed

- The gemspec now requires Ruby >= 3.3. Older Rubies will continue to resolve to 1.0.0.
- Replaced the tailor linter with RuboCop, and the dead Travis config with GitHub Actions, testing
  Ruby 3.3, 3.4 and 4.0.

### Fixed

- Declared `logger` as a runtime dependency. `lib/log_switch.rb` has always required it, but the
  gemspec never declared it — so under Bundler on Ruby 4.0, where `logger` is no longer a default
  gem, requiring `log_switch` raised LoadError.

## [1.0.0] - 2014-10-10

### Added

- LogSwitch can now be included in your own module, then that included in other modules. This allows
  toggling logging per includer.

### Removed

- Removed `LogSwitch::Mixin` in favor of simpler implementation.

### Fixed

- [gh-5](https://github.com/turboladen/log_switch/issues/5): The improvements listed above alleviate
  this problem.

## 0.4.1 - 2013-01-04

### Fixed

- Initialize `@log` before calling it, thus removing warnings when running with `-w`.

## [0.4.0] - 2012-11-12

### Added

- [gh-4](https://github.com/turboladen/log_switch/issues/4): Added ability to toggle the prepending
  of the class name to log messages. This lets you know which class/object is logging each message —
  useful for when you have a number of different classes logging.

## [0.3.0] - 2012-02-03

### Added

- [gh-2](https://github.com/turboladen/log_switch/issues/2): Added ability to mix in
  `LogSwitch::Mixin` to classes to allow calling `#log` in your class and have it delegate to your
  singleton logger.

### Fixed

- [gh-3](https://github.com/turboladen/log_switch/issues/3): Fixed warning on `@before_block`.

## [0.2.0] - 2011-12-05

### Added

- Added ability to pass a block to `.log` to have code executed before logging.
- Added `before` hook to allow code to be executed every time log gets called (but before the
  message actually gets logged).

### Fixed

- [gh-1](https://github.com/turboladen/log_switch/issues/1): Only log `#each_line` when that method
  is supported on the object being logged.

## [0.1.4] - 2011-10-10

### Removed

- Removed gemspec enforcement of >= 1.9.2

## [0.1.3] - 2011-10-10

### Added

- Made 1.8.7 compatible.

### Removed

- Removed dev deps: metric_fu, code_statistics

## [0.1.2] - 2011-10-09

### Fixed

- Just realized author is supposed to be my real name. :)

## [0.1.1] - 2011-10-09

### Fixed

- Fixed author field in .gemspec

## [0.1.0] - 2011-10-07

### Added

- `require` and `extend` to mix in to your class/module to get a single point of logging
- Switch on/off logging
- Use whatever Logger you want

<!-- 0.4.1 is intentionally unlinked: it was never tagged or released to rubygems. -->

[unreleased]: https://github.com/turboladen/log_switch/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/turboladen/log_switch/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/turboladen/log_switch/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/turboladen/log_switch/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/turboladen/log_switch/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/turboladen/log_switch/compare/v0.1.4...v0.2.0
[0.1.4]: https://github.com/turboladen/log_switch/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/turboladen/log_switch/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/turboladen/log_switch/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/turboladen/log_switch/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/turboladen/log_switch/releases/tag/v0.1.0
