#! /bin/bash

DIR=$(pwd)
cd "$(dirname "$0")"

source ../task-logger.sh
source ../lib/assert.sh

# easier testing
no_colors

assert "echo $LOG_DIR | sed 's/.*task-logger.*/YES/'" "YES"

# sh echo doesn't support -n option so it's necessary to run log_cmd here
# (in bash) and then use the output
OUT=$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')

assert "echo \"$OUT\"" "YES"
assert "cat ${LOG_DIR}/task.out" "Hello"

custom_fun() {
  echo "normal output"
  echo "error output" >&2
}

OUT=$(log_cmd custom custom_fun | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')

assert "echo \"$OUT\"" "YES"
assert "cat ${LOG_DIR}/custom.out" "normal output"
assert "cat ${LOG_DIR}/custom.err" "error output"

# two tasks with the same name
OUT=$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')

assert "echo \"$OUT\"" "YES"
assert "cat ${LOG_DIR}/task-1.out" "Hello"

# two tasks with the same name
OUT=$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')

assert "echo \"$OUT\"" "YES"
assert "cat ${LOG_DIR}/task-2.out" "Hello"

OUT=$((log_cmd error bad-cmd || ko) | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${ERROR_SYMBOL}' /YES/')
assert "echo \"$OUT\"" "YES"

OUT=$((log_cmd warn bad-cmd || warn) | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${WARNING_SYMBOL}' /YES/')
assert "echo \"$OUT\"" "YES"

assert_end $(basename $0)

cd "$DIR"
