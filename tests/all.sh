#!/bin/bash
#file: tests.sh

source task-logger.sh

testCleanIfNoErrors() {
  no_colors
  log_cmd test true > /dev/null || ko > /dev/null
  assertTrue "[[ -d "$LOG_DIR" && -f "$LOG_DIR/test.out" ]]"
  finish > /dev/null
  assertTrue "[[ ! -d "$LOG_DIR" && ! -f "$LOG_DIR/test.out" ]]"
  new_log_dir
  reset_counters
}

testNoCleanIfErrors() {
  no_colors
  log_cmd test false > /dev/null || ko > /dev/null
  assertTrue "[[ -d "$LOG_DIR" && -f "$LOG_DIR/test.out" ]]"
  finish > /dev/null
  assertTrue "[[ -d "$LOG_DIR" && -f "$LOG_DIR/test.out" ]]"
  tmp_cleanup
  new_log_dir
  reset_counters
}

testNoCleanIfOption() {
  no_colors
  log_cmd test true > /dev/null || ko > /dev/null
  assertTrue "[[ -d "$LOG_DIR" && -f "$LOG_DIR/test.out" ]]"
  finish --no-cleanup > /dev/null
  assertTrue "[[ -d "$LOG_DIR" && -f "$LOG_DIR/test.out" ]]"
  tmp_cleanup
  new_log_dir
  reset_counters
}

testCleanIfForce() {
  no_colors
  log_cmd test false > /dev/null || ko > /dev/null
  assertTrue "[[ -d "$LOG_DIR" && -f "$LOG_DIR/test.out" ]]"
  finish --force-cleanup > /dev/null
  assertTrue "[[ ! -d "$LOG_DIR" && ! -f "$LOG_DIR/test.out" ]]"
  new_log_dir
  reset_counters
}

# first with colors
testColors() {
  set_colors
  assertEquals "${INFO_COLOR}sample text${RESET_COLOR}" "$(info "sample text")"
  assertEquals "${GOOD_COLOR}sample text${RESET_COLOR}" "$(good "sample text")"
  assertEquals "${BAD_COLOR}sample text${RESET_COLOR}" "$(bad "sample text")"
  assertEquals "${WARNING_COLOR}sample text${RESET_COLOR}" "$(warning "sample text")"
  assertEquals "${ERROR_COLOR}sample text${RESET_COLOR}" "$(error "sample text")"
  assertEquals "${IMPORTANT_COLOR}sample text${RESET_COLOR}" "$(important "sample text")"
  assertEquals "${INFO_COLOR}[00:00:00] ${RESET_COLOR}${WORKING_COLOR}sample text${RESET_COLOR}" "$(working "sample text" | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")"
}

#then without
testNoColors() {
  no_colors
  assertEquals "sample text" "$(info "sample text")"
  assertEquals "sample text" "$(good "sample text")"
  assertEquals "sample text" "$(bad "sample text")"
  assertEquals "sample text" "$(warning "sample text")"
  assertEquals "sample text" "$(error "sample text")"
  assertEquals "sample text" "$(important "sample text")"
  assertEquals "[00:00:00] sample text" "$(working "sample text" | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")"
}

testCounters() {
  # easier testing
  no_colors

  assertEquals "0" "$(echo ${SUCCESS})"
  assertEquals "0" "$(echo ${WARNINGS})"
  assertEquals "0" "$(echo ${ERRORS})"
  assertEquals " ${SUCCESS_SYMBOL} " "$(ok)"
  ok > /dev/null
  assertEquals "1" "$(echo ${SUCCESS})"
  assertEquals "0" "$(echo ${WARNINGS})"
  assertEquals "0" "$(echo ${ERRORS})"
  assertEquals " ${ERROR_SYMBOL} " "$(ko)"
  ko > /dev/null
  assertEquals "1" "$(echo ${SUCCESS})"
  assertEquals "0" "$(echo ${WARNINGS})"
  assertEquals "1" "$(echo ${ERRORS})"
  assertEquals " ${WARNING_SYMBOL} " "$(warn)"
  warn > /dev/null
  assertEquals "1" "$(echo ${SUCCESS})"
  assertEquals "1" "$(echo ${WARNINGS})"
  assertEquals "1" "$(echo ${ERRORS})"


  ok > /dev/null
  ok > /dev/null
  assertEquals "3" "$(echo ${SUCCESS})"
  assertEquals "1" "$(echo ${WARNINGS})"
  assertEquals "1" "$(echo ${ERRORS})"

  warn > /dev/null
  assertEquals "3" "$(echo ${SUCCESS})"
  assertEquals "2" "$(echo ${WARNINGS})"
  assertEquals "1" "$(echo ${ERRORS})"

  ko > /dev/null
  ko > /dev/null
  ko > /dev/null
  ko > /dev/null
  assertEquals "3" "$(echo ${SUCCESS})"
  assertEquals "2" "$(echo ${WARNINGS})"
  assertEquals "5" "$(echo ${ERRORS})"
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

  OUT=$(log_cmd custom custom_fun | sed 's/.*\[3D.*\[3D *\[[0-9.][0-9.]* [mns]*\] '${SUCCESS_SYMBOL}' /YES/')

  assertEquals "YES" "$OUT"
  assertEquals "normal output" "$(cat ${LOG_DIR}/custom.out)"
  assertEquals "error output" "$(cat ${LOG_DIR}/custom.err)"

  OUT=$( (log_cmd fail idontexists || ko) | sed 's/.*\[3D.*\[3D *\[[0-9.][0-9.]* [mns]*\] '${ERROR_SYMBOL}' /YES/')

  assertEquals "YES" "$OUT"
}

error_test() {
  echo lol >&2
  log_cmd error bad-cmd || ko
  echo end >&2
}
warn_test() {
  log_cmd warn bad-cmd || warn
}

testLog() {
  # easier testing
  no_colors
  WORKING=dot_working
  WORKING_END=true

  assertEquals "YES" "$(echo $LOG_DIR | sed 's/.*task-logger.*/YES/')"

  assertEquals "YES" "$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* [mns]*\] '${SUCCESS_SYMBOL}' /YES/')"
  assertEquals "Hello" "$(cat ${LOG_DIR}/task.out)"

  assertEquals "YES" "$(log_cmd custom custom_fun | sed 's/\.\.*\[[0-9.][0-9.]* [mns]*\] '${SUCCESS_SYMBOL}' /YES/')"
  assertEquals "normal output" "$(cat ${LOG_DIR}/custom.out)"
  assertEquals "error output" "$(cat ${LOG_DIR}/custom.err)"

  # two tasks with the same name
  assertEquals "YES" "$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* [mns]*\] '${SUCCESS_SYMBOL}' /YES/')"
  assertEquals "Hello" "$(cat ${LOG_DIR}/task-1.out)"

  assertEquals "YES" "$(log_cmd task echo Hello | sed 's/\.\.*\[[0-9.][0-9.]* [mns]*\] '${SUCCESS_SYMBOL}' /YES/')"
  assertEquals "Hello" "$(cat ${LOG_DIR}/task-2.out)"
}

testMessages() {
  # no colors for easier testing
  no_colors

  #Works without quotes
  assertEquals "message without quotes" "$(info message without quotes)"
  assertEquals "message without quotes" "$(good message without quotes)"
  assertEquals "message without quotes" "$(bad message without quotes)"
  assertEquals "message without quotes" "$(error message without quotes)"
  assertEquals "message without quotes" "$(warning message without quotes)"
  assertEquals "message without quotes" "$(important message without quotes)"
  assertEquals "[00:00:00] message without quotes" "$(working message without quotes | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")"

  # test -n for echo
  assertEquals "message without quotes OK" "$(info -n message without quotes; echo " OK")"
  assertEquals "message without quotes OK" "$(good -n message without quotes; echo " OK")"
  assertEquals "message without quotes OK" "$(bad -n message without quotes; echo " OK")"
  assertEquals "message without quotes OK" "$(error -n message without quotes; echo " OK")"
  assertEquals "message without quotes OK" "$(warning -n message without quotes; echo " OK")"
  assertEquals "message without quotes OK" "$(important -n message without quotes; echo " OK")"
  assertEquals "[00:00:00] message without quotes OK" "$((working -n message without quotes; echo " OK") | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g")"
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
  assertEquals "[00:00:00] Finished: $SUCCESS ✓ $WARNINGS ⚠ $ERRORS ✗" "$(finish | sed -e "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g" -e 's/[^✗]*$//')"
}

testCritical() {
  no_colors

  # non failing
  assertTrue 'log_cmd -c task-name echo >/dev/null 2>/dev/null'

  # failing
  # I must quit the less loop somehow
  #assertFalse 'log_cmd -c task-name nope'
}

testOverwrite() {
  no_colors

  log_cmd -o overwrite 'echo overwritetest' >/dev/null 2>/dev/null
  assertTrue "[[ -f '$LOG_DIR/overwrite.out' && -f '$LOG_DIR/overwrite.out' ]]"
  assertEquals "overwritetest" "$(cat $LOG_DIR/overwrite.out)"

  log_cmd -o overwrite 'echo overwritetest2' >/dev/null 2>/dev/null
  assertTrue "[[ -f '$LOG_DIR/overwrite.out' && -f '$LOG_DIR/overwrite.err' ]]"
  assertTrue "[[ ! -f '$LOG_DIR/overwrite-1.out' && ! -f '$LOG_DIR/overwrite-1.err' ]]"
  assertEquals "overwritetest2" "$(cat $LOG_DIR/overwrite.out)"
}

testLogWithOptions() {
  no_colors

  assertEquals "$(log_cmd task echo -n Hello | sed 's/\.\.*\[[0-9.][0-9.]* [mns]*\] '${SUCCESS_SYMBOL}' /YES/')" "YES"
  assertEquals "$(cat $LOG_DIR/task.out)" "Hello"
}

# Must be called at the end
# It cleans up the temporary dirs used
testTeardown() {
  tmp_cleanup
  show_cursor
}

SHUNIT_PARENT="$0"
source lib/shunit2
