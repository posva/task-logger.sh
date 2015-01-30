task-logger.sh [![Build Status](https://travis-ci.org/posva/task-logger.sh.svg?branch=master)](https://travis-ci.org/posva/task-logger.sh)
===

![img](https://cloud.githubusercontent.com/assets/664177/5983128/d10492d4-a8ca-11e4-87c6-d9ae680d2b88.png)

Shell library to log tasks with nice output. Supports zsh and bash.

|      Property| Value                                              |
|-------------:|:---------------------------------------------------|
|      Version | 1.0.0                                              |
|       Author | Eduardo San Martin Morote                          |
|      License | The MIT License                                    |
| Requirements | `bc` (an arbitrary precision calculator language)  |

# Example

```sh
#! /bin/bash

# Load the lib
source task-logger.sh

# Print some information message
info "Logs are available at $LOG_DIR"

# Print a message and do the corresponding message
# If the task fail treat it as an error
working -n "Taking a nap"
log_cmd nap sleep 3 || ko

# Print a summary about what have been done
finish
```

#Motivation

When writing shell scripts you usually want to perform tasks with minimal
output while logging everything somewhere else in order to check it later.
Critical tasks should stop the script when they fail. At the end you should
have a summary about errors, warnings and successes.

Everything with colors and unicode to make your shell look :sparkles:fabulous:sparkles:.

#Features

* :lollipop:Colors
* Timers: every task displays the elapsed time
* Customizable:
  * Change any color
  * Create your own messages functions with 2 lines of code
* Critical tasks
* Summary
* Can be killed

#Usage

###Initialisation
As every shell lib you start by sourcing it: `source task-logger.sh`

###Messages
The lib has some printing functions defined. Every one of them follows this structure:

```sh
warning() {
  parse_opt "$@"
  echo ${opts[@]} "${WARNING_COLOR}${args[@]}${RESET_COLOR}"
}
```

You can define your own functions adding more text and changing colors.
You can use `printf` or any other printing functions instead of `echo`.
Look at `working` function for an example.

The available functions are:

* `important`: prints a message with a blue background so it is quite visible
* `warning`: prints a message in yellow
* `good`: prints a message in green
* `bad`: prints a message in red
* `info`: prints a message in gray
* `error`: prints a message in white with red background. best fit for critical errors
* `ok`, `ko` and `warn` increments the numbers of successes, errors and warnings, respectively.
They also print fancy unicode characters
* `working`: prints the current time with format `[HH:MM:SS]` in `info` color and the prints
a message in blue. This function is usually called with the `-n` option (no end line) and just
before calling `log_cmd`.

###Logs
Launch tasks with `log_cmd`:

```sh
# log_cmd [-c] <task-name> <command> || (ko|warn)

log_cmd -c critical-task sleep 2 || ko
log_cmd error-task not-a-cmd || ko
log_cmd warn-task not-a-cmd || warn

# prints a summary
finish
```

Don't forget to call `finish` at the end!

