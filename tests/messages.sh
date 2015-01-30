#! /bin/bash

DIR=$(pwd)
cd "$(dirname "$0")"

source ../task-logger.sh
source ../lib/assert.sh

# no colors for easier testing
no_colors

#Works without quotes
assert 'info message without quotes' "message without quotes"
assert 'good message without quotes' "message without quotes"
assert 'bad message without quotes' "message without quotes"
assert 'error message without quotes' "message without quotes"
assert 'warning message without quotes' "message without quotes"
assert 'important message without quotes' "message without quotes"
assert 'working message without quotes | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g"' "[00:00:00] message without quotes"

# test -n for echo
assert 'info -n message without quotes; echo " OK"' "message without quotes OK"
assert 'good -n message without quotes; echo " OK"' "message without quotes OK"
assert 'bad -n message without quotes; echo " OK"' "message without quotes OK"
assert 'error -n message without quotes; echo " OK"' "message without quotes OK"
assert 'warning -n message without quotes; echo " OK"' "message without quotes OK"
assert 'important -n message without quotes; echo " OK"' "message without quotes OK"
assert '(working -n message without quotes; echo " OK") | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g"' "[00:00:00] message without quotes OK"

assert_end messages-text

cd "$DIR"
