#!/bin/bash
#file: tests.sh

source task-logger.sh

# first with colors
testColors() {
  set_colors
  assertEquals "$(info "sample text")" "${INFO_COLOR}sample text${RESET_COLOR}"
  assertEquals "$(good "sample text")" "${GOOD_COLOR}sample text${RESET_COLOR}"
  assertEquals "$(bad "sample text")" "${BAD_COLOR}sample text${RESET_COLOR}"
  assertEquals "$(warning "sample text")" "${WARNING_COLOR}sample text${RESET_COLOR}"
  assertEquals "$(error "sample text")" "${ERROR_COLOR}sample text${RESET_COLOR}"
  assertEquals "$(important "sample text")" "${IMPORTANT_COLOR}sample text${RESET_COLOR}"
  assertEquals "$(working "sample text" | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")" "${INFO_COLOR}[00:00:00] ${RESET_COLOR}${WORKING_COLOR}sample text${RESET_COLOR}"
}

#then without
testNoColors() {
  no_colors
  assertEquals "$(info "sample text")" "sample text"
  assertEquals "$(good "sample text")" "sample text"
  assertEquals "$(bad "sample text")" "sample text"
  assertEquals "$(warning "sample text")" "sample text"
  assertEquals "$(error "sample text")" "sample text"
  assertEquals "$(important "sample text")" "sample text"
  assertEquals "$(working "sample text" | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")" "[00:00:00] sample text"
}

testCounters() {
  # easier testing
  no_colors

  assertEquals "$(echo ${SUCCESS})" "0"
  assertEquals "$(echo ${WARNINGS})" "0"
  assertEquals "$(echo ${ERRORS})" "0"
  assertEquals "$(ok)" " ${SUCCESS_SYMBOL} "
  ok > /dev/null
  assertEquals "$(echo ${SUCCESS})" "1"
  assertEquals "$(echo ${WARNINGS})" "0"
  assertEquals "$(echo ${ERRORS})" "0"
  assertEquals "$(ko)" " ${ERROR_SYMBOL} "
  ko > /dev/null
  assertEquals "$(echo ${SUCCESS})" "1"
  assertEquals "$(echo ${WARNINGS})" "0"
  assertEquals "$(echo ${ERRORS})" "1"
  assertEquals "$(warn)" " ${WARNING_SYMBOL} "
  warn > /dev/null
  assertEquals "$(echo ${SUCCESS})" "1"
  assertEquals "$(echo ${WARNINGS})" "1"
  assertEquals "$(echo ${ERRORS})" "1"


  ok > /dev/null
  ok > /dev/null
  assertEquals "$(echo ${SUCCESS})" "3"
  assertEquals "$(echo ${WARNINGS})" "1"
  assertEquals "$(echo ${ERRORS})" "1"

  warn > /dev/null
  assertEquals "$(echo ${SUCCESS})" "3"
  assertEquals "$(echo ${WARNINGS})" "2"
  assertEquals "$(echo ${ERRORS})" "1"

  ko > /dev/null
  ko > /dev/null
  ko > /dev/null
  ko > /dev/null
  assertEquals "$(echo ${SUCCESS})" "3"
  assertEquals "$(echo ${WARNINGS})" "2"
  assertEquals "$(echo ${ERRORS})" "5"
}

custom_fun() {
  echo "normal output"
  echo "error output" >&2
}

testWorking() {
  # easier testing
  no_colors

  # test with another WORKING
  WORKING=turning_circle
  WORKING_END=turning_circle_end

  OUT=$(log_cmd custom custom_fun | sed 's/.*\[3D.*\[3D *\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')

  assertEquals "$OUT" "YES"
  assertEquals "$(cat ${LOG_DIR}/custom.out)" "normal output"
  assertEquals "$(cat ${LOG_DIR}/custom.err)" "error output"

  OUT=$( (log_cmd fail idontexists || ko) | sed 's/.*\[3D.*\[3D *\[[0-9.][0-9.]* s\] '${ERROR_SYMBOL}' /YES/')

  assertEquals "$OUT" "YES"
}

error_test() {
  log_cmd error bad-cmd || ko
}
warn_test() {
  log_cmd warn bad-cmd || warn
}

testLog() {
  # easier testing
  no_colors
  WORKING=dot_working
  WORKING_END=true

  assertEquals "$(echo $LOG_DIR | sed 's/.*task-logger.*/YES/')" "YES"

  assertEquals "$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')" "YES"
  assertEquals "$(cat ${LOG_DIR}/task.out)" "Hello"

  assertEquals "$(log_cmd custom custom_fun | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')" "YES"
  assertEquals "$(cat ${LOG_DIR}/custom.out)" "normal output"
  assertEquals "$(cat ${LOG_DIR}/custom.err)" "error output"

  # two tasks with the same name
  assertEquals "$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')" "YES"
  assertEquals "$(cat ${LOG_DIR}/task-1.out)" "Hello"

  assertEquals "$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${SUCCESS_SYMBOL}' /YES/')" "YES"
  assertEquals "$(cat ${LOG_DIR}/task-2.out)" "Hello"

  # using a functions here should be more compatible
  assertEquals "$(error_test | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${ERROR_SYMBOL}' /YES/')" "YES"

  assertEquals "$(warn_test | sed 's/\.\.*\[[0-9.][0-9.]* s\] '${WARNING_SYMBOL}' /YES/')" "YES"
}

testMessages() {
  # no colors for easier testing
  no_colors

  #Works without quotes
  assertEquals "$(info message without quotes)" "message without quotes"
  assertEquals "$(good message without quotes)" "message without quotes"
  assertEquals "$(bad message without quotes)" "message without quotes"
  assertEquals "$(error message without quotes)" "message without quotes"
  assertEquals "$(warning message without quotes)" "message without quotes"
  assertEquals "$(important message without quotes)" "message without quotes"
  assertEquals "$(working message without quotes | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")" "[00:00:00] message without quotes"

  # test -n for echo
  assertEquals "$(info -n message without quotes; echo " OK")" "message without quotes OK"
  assertEquals "$(good -n message without quotes; echo " OK")" "message without quotes OK"
  assertEquals "$(bad -n message without quotes; echo " OK")" "message without quotes OK"
  assertEquals "$(error -n message without quotes; echo " OK")" "message without quotes OK"
  assertEquals "$(warning -n message without quotes; echo " OK")" "message without quotes OK"
  assertEquals "$(important -n message without quotes; echo " OK")" "message without quotes OK"
  assertEquals "$((working -n message without quotes; echo " OK") | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")" "[00:00:00] message without quotes OK"
}

testReturnCodes() {
  no_colors

  # symbols
  assertFalse 'ko 1 >/dev/null 2>/dev/null'
  assertTrue 'ok >/dev/null 2>/dev/null'
  assertTrue 'warn >/dev/null 2>/dev/null'

  # message helpers
  assertFalse 'error critical error >/dev/null 2>/dev/null'
  assertTrue 'info >/dev/null 2>/dev/null'
  assertTrue 'good >/dev/null 2>/dev/null'
  assertTrue 'bad >/dev/null 2>/dev/null'
  assertTrue 'warning >/dev/null 2>/dev/null'
  assertTrue 'working >/dev/null 2>/dev/null'
  assertTrue 'important >/dev/null 2>/dev/null'

  # log_cmd
  log_cmd task-name non-existant-command >/dev/null 2>/dev/null
  assertEquals "$?" 127
  assertFalse 'log_cmd grep grep unexistant-word-in-lib task-logger.sh >/dev/null 2>/dev/null'
  assertTrue 'log_cmd echo echo >/dev/null 2>/dev/null'
}

testFinish() {
  no_colors

  ERRORS=3
  SUCCESS=2
  WARNINGS=34
  assertEquals "$(finish| sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")" "[00:00:00] Finished: $SUCCESS ✓ $WARNINGS ⚠ $ERRORS ✗"
}

testCritical() {
  no_colors

  # non failing
  assertTrue 'log_cmd -c task-name echo >/dev/null 2>/dev/null'

  # failing
  # I must quit the less loop somehow
  #assertFalse 'log_cmd -c task-name nope'
}

SHUNIT_PARENT="$0"
source lib/shunit2
