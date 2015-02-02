#! /bin/bash

DIR=$(pwd)
cd "$(dirname "$0")"

source ../task-logger.sh
source ../lib/assert.sh

# easier testing
no_colors

assert 'echo ${SUCCESS}' "0"
assert 'echo ${WARNINGS}' "0"
assert 'echo ${ERRORS}' "0"
assert 'ok' " ${SUCCESS_SYMBOL} "
ok > /dev/null
assert 'echo ${SUCCESS}' "1"
assert 'echo ${WARNINGS}' "0"
assert 'echo ${ERRORS}' "0"
assert 'ko' " ${ERROR_SYMBOL} "
ko > /dev/null
assert 'echo ${SUCCESS}' "1"
assert 'echo ${WARNINGS}' "0"
assert 'echo ${ERRORS}' "1"
assert 'warn' " ${WARNING_SYMBOL} "
warn > /dev/null
assert 'echo ${SUCCESS}' "1"
assert 'echo ${WARNINGS}' "1"
assert 'echo ${ERRORS}' "1"


ok > /dev/null
ok > /dev/null
assert 'echo ${SUCCESS}' "3"
assert 'echo ${WARNINGS}' "1"
assert 'echo ${ERRORS}' "1"

warn > /dev/null
assert 'echo ${SUCCESS}' "3"
assert 'echo ${WARNINGS}' "2"
assert 'echo ${ERRORS}' "1"

ko > /dev/null
ko > /dev/null
ko > /dev/null
ko > /dev/null
assert 'echo ${SUCCESS}' "3"
assert 'echo ${WARNINGS}' "2"
assert 'echo ${ERRORS}' "5"

assert_end $(basename $0)

cd "$DIR"
