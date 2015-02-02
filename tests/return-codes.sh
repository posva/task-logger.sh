#! /bin/bash

DIR=$(pwd)
cd "$(dirname "$0")"

source ../task-logger.sh
source ../lib/assert.sh

# easier testing
no_colors

# symbols
assert_raises 'ko' 1
assert_raises 'ok'
assert_raises 'warn'

# message helpers
assert_raises 'error critical error' 1
assert_raises 'info'
assert_raises 'good'
assert_raises 'bad'
assert_raises 'warning'
assert_raises 'working'
assert_raises 'important'

# log_cmd
assert_raises 'log_cmd task-name non-existant-command' 127
assert_raises 'log_cmd grep grep unexistant-word-in-lib ../task-logger.sh' 1
assert_raises 'log_cmd echo echo'

assert_end $(basename $0)

cd "$DIR"
