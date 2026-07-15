# log_switch

<https://github.com/turboladen/log_switch>

## Description

While developing other gems that needed a single class/singleton style logger, I
got tired of repeating the code to create that logger and mix it in to my base
class. I just wanted to require something, mix it in, and log:

```ruby
MyThing.new.log "some message"
```

...and be able to switch that logging off programmatically:

```ruby
MyThing.logging_enabled = false
```

This gem does that.

## Synopsis

### Basic use

`include LogSwitch` to give your class a class-level logger and an instance-level
`#log` method. **Logging is off by default** — turn it on explicitly:

```ruby
require 'log_switch'

class MyThing
  include LogSwitch
end

MyThing.logging_enabled = true
MyThing.new.log "I like you, Ruby."
# => D, [2026-07-15T12:46:30.206465 #66434] DEBUG -- : <MyThing> I like you, Ruby.
```

Switch it back off and calls become no-ops:

```ruby
MyThing.logging_enabled = false
MyThing.new.log "You're my favorite."   # => nothing is written
```

Note the class name is prepended to each message. That is on by default.

### Log levels

The default level is `:debug`. Change it with `default_log_level`:

```ruby
MyThing.default_log_level = :warn
MyThing.new.log "Crap!"
# => W, [2026-07-15T12:46:30.206563 #66434]  WARN -- : <MyThing> Crap!
```

Or pass a level per call:

```ruby
MyThing.new.log "Stuff!", :info
# => I, [2026-07-15T12:46:30.206499 #66434]  INFO -- : <MyThing> Stuff!
```

The level is passed straight through to your Logger, so any method it responds
to will do.

### Using your own Logger

`LogSwitch` defaults to a `Logger` writing to `STDOUT`. Point it anywhere:

```ruby
MyThing.logger = Logger.new('log.txt')
MyThing.new.log "hi!"
```

`LogSwitch.logger` sets the default for includers that have not set their own,
and `LogSwitch.reset_config!` puts things back to a fresh `STDOUT` logger.

### Multi-line messages

Anything responding to `#each_line` is logged one line per call, so a multi-line
message stays readable:

```ruby
MyThing.new.log "line one\nline two"
# => D, [...] DEBUG -- : <MyThing> line one
# => D, [...] DEBUG -- : <MyThing> line two
```

Objects that do not respond to `#each_line` (an Array, an Exception) are logged
whole.

### Hooks

Pass a block to `#log` and it runs before the message is written — handy for
one-off setup:

```ruby
MyThing.new.log("Thanks brah!") do
  FileUtils.mkdir_p(log_directory)
end
```

For something that should run before *every* call, use `before_log`:

```ruby
MyThing.before_log = proc { FileUtils.mkdir_p(log_directory) }
MyThing.new.log "Thanks brah!"    # runs the hook, then logs
MyThing.new.log "I'm hungry..."   # runs it again
```

## Requirements

- Ruby >= 3.3. Tested on 3.3, 3.4 and 4.0 (see `.github/workflows/ci.yml`).
- Runtime dependency: `logger` (no longer a default gem as of Ruby 4.0).

## Install

```sh
gem install log_switch
```

## Developers

After checking out the source:

```sh
bundle install
bundle exec rake      # specs + RuboCop
```

## Thanks

I need to thank the [savon](https://github.com/savonrb/savon) project for most of
the code here. Somehow I ran across how they do logging and started following
suit. The code in `log_switch` is almost identical to Savon's logging.
