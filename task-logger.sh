#! /bin/bash

# task-logger.sh 1.3.0 - zsh and bash fancy task logging
# Copyright (C) 2015 Eduardo San Martin Morote
# Last modification date: 2015-07-27
#
# http://github.com/posva/task-logger.sh
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Counting for errors
ERRORS=0
# Counting for warnings
WARNINGS=0
# Counting for successes
SUCCESS=0

SUCCESS_SYMBOL="✓"
ERROR_SYMBOL="✗"
WARNING_SYMBOL="⚠"
KILLED_SYMBOL="☠"

# Set color variables. They can be overrided.
set_colors() {
  RESET_COLOR="[0m"
  IMPORTANT_COLOR="[104;30m"
  WARNING_COLOR="[33m"
  GOOD_COLOR="[32m"
  BAD_COLOR="[31m"
  INFO_COLOR="[90m"
  ERROR_COLOR="[101m"
  WORKING_COLOR="[94m"
  END_GOOD_COLOR="[92m"
  END_BAD_COLOR="[91m"
  END_WARNING_COLOR="[93m"
}

# Unset colors
no_colors() {
  RESET_COLOR=
  IMPORTANT_COLOR=
  WARNING_COLOR=
  GOOD_COLOR=
  BAD_COLOR=
  INFO_COLOR=
  ERROR_COLOR=
  WORKING_COLOR=
  END_GOOD_COLOR=
  END_BAD_COLOR=
  END_WARNING_COLOR=
}

# https://github.com/posva/pretty-hrtime.sh
_desc=(d:86400:day h:3600:hour m:60:minute s:1:second ms:1000000:millisecond μs:1000:microsecond ns:1:nanosecond)
ptime() {
  local result s ns amount unit convert lconvert verbose tmp_str long
  for i in "$@"; do
    case $i in
      -v|--verbose)
        verbose=YES
        shift
        ;;
      -l|--long)
        long=YES
        shift
        ;;
      -[a-z0-9]|--*)
        echo "[ptime] Option $i doesn't exists" >&2
        shift
        ;;
    esac
  done
  s="$1"
  ns="$2"
  for desc in ${_desc[@]}; do
    convert=$(echo "$desc" | cut -d: -f2)
    unit=$(echo "$desc" | cut -d: -f1)
    # Use the seconds or the nanoseconds amount
    if echo "$unit" | grep '.s$' > /dev/null; then
      amount="$ns"
    else
      amount="$s"
    fi
    # Remove any extra time already counted
    if [[ "$unit" != d && "$unit" != ms ]]; then
      (( amount %= lconvert ))
    fi
    (( val = (100 * amount) /  convert ))
    if [[ "$unit" = s ]]; then
      (( val += ns / 10000000 ))
    fi
    if [[ "$val" -ge 100 ]]; then
      # Don't print to many decimals
      if [[ "$long" = YES || "$val" -ge 1000 ]]; then
        (( val /= 100 ))
        tmp_str="$val"
      else
        # We need a tmp var because val is treated as a number
        tmp_str=$(echo "$val" | sed -e 's/..$/.&/' -e 's/^.$/.0&/' -e 's/\.0*$//' -e 's/00*$//')
        if [[ -z "$tmp_str" ]]; then
          tmp_str=0
        fi
      fi
      if [[ ! -z "$result" ]]; then
        result="$result "
      fi
      if [[ "$verbose" = YES ]]; then
        unit=$(echo "$desc" | cut -d: -f3)
      fi
      result="${result}${tmp_str} $unit"
      if [[ "$verbose" = YES && "$tmp_str" != 1 ]]; then
        result="${result}s"
      fi
      if [[ -z "$long" ]]; then
        break
      fi
    fi
    # Save value for next iteration
    lconvert="$convert"
  done

  if [[ -z "$result" ]]; then
    if [[ -z "$verbose" ]]; then
      echo "0 s"
    else
      echo "0 seconds"
    fi
  else
    echo "$result"
  fi
}

# Parse options and args and place them in two global variables
# args and opts
# INTERNAL FUNCTION
parse_opt() {
  local io ia
  args=() # array
  opts=()
  io=1
  ia=1
  while [[ "$#" > 0 ]]; do #[[ "$1" =~ "$re" ]]; do
    if [[ "$1" =~ $re ]]; then
      opts[$io]=$1
      ((io++))
    else
      args[$ia]="$1"
      ((ia++))
    fi
    shift
  done
}

# WORKING should be some kind of loop. It is executed whenever a command
# is launched and can be customized. By default there are two options:
# dot_working and turning_circle. The last one being the default. To use your
# own loop just set WORKING to the function or program. Additionally you must
# also set WORKING_END to anything you want to call after the main loop is
# killed. For example I use to replace the cursor. You can set it to true or
# any other command that do not print anything
WORKING=turning_circle
WORKING_END=turning_circle_end

# How many seconds does a dot represent
DOT_SECONDS=1
# Print dots in order to show progress.
# This functions should be called with & and killed when job is done
# If you want to use this function, set WORKING to dot_working and
# WORKING_END to true
dot_working() {
  while true; do
    echo -n '.'
    sleep $DOT_SECONDS
  done
}

# Prints a turning circle with unicode to show work is in progress
turning_circle() {
  local p n symbols
  p=1
  n=4
  symbols=()
  symbols[1]=" ◐ "
  symbols[2]=" ◓ "
  symbols[3]=" ◑ "
  symbols[4]=" ◒ "

  #trap 'printf "\033[5D "; return' SIGINT
  #trap 'printf "\033[3D "; return' SIGHUP SIGTERM

  printf "   "
  while true; do
    printf "\033[3D${symbols[$p]}"
    ((p++))
    if [[ "$p" > "$n" ]]; then
      # :nocov:
      p=1
      # :nocov:
    fi
    sleep 0.2
  done
}

turning_circle_end() {
  printf "\033[3D "
}

# Little timer helper using perl to have microseconds precision even in OS X
# ex reset_timer 1 # set timer with id 1 at 0s
TIMER_INIT=()
reset_timer() {
  TIMER_INIT[$1]=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; $ts = $a; $tn = $b * 1000; print "$ts $tn";')
}

# get the current value of a timer without resetting it
# ex get_timer 1 get elapsed time since last reset_timer 1 call
get_timer() {
  local elapsed seconds nanoseconds
  seconds=$(echo "${TIMER_INIT[$1]}" | cut -d ' ' -f 1)
  nanoseconds=$(echo "${TIMER_INIT[$1]}" | cut -d ' ' -f 2)
  elapsed=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; $ts = $a - '"$seconds"'; $tn = $b * 1000 - '"$nanoseconds"'; print "$ts $tn";')
  echo "$elapsed"
}

# simple regex to parse options
re='^--?[a-zA-Z0-9]+'

# Important message that must be read and contains useful information
# Accepts same options as echo
important() {
  parse_opt "$@"
  echo ${opts[@]} "${IMPORTANT_COLOR}${args[@]}${RESET_COLOR}"
}

# Warning message in yellow
# Accepts same options as echo
warning() {
  parse_opt "$@"
  echo ${opts[@]} "${WARNING_COLOR}${args[@]}${RESET_COLOR}"
}

# Print a message in green
# Accepts same options as echo
good() {
  parse_opt "$@"
  echo ${opts[@]} "${GOOD_COLOR}${args[@]}${RESET_COLOR}"
}

# Print a message in red
# Accepts same options as echo
bad() {
  parse_opt "$@"
  echo ${opts[@]} "${BAD_COLOR}${args[@]}${RESET_COLOR}"
}

# Print a message in gray
# Accepts same options as echo
info() {
  parse_opt "$@"
  echo ${opts[@]} "${INFO_COLOR}${args[@]}${RESET_COLOR}"
}

# Error message with Red background
# Fits critical errors
# Accepts same options as echo
# Always return 1 (error)
error() {
  parse_opt "$@"
  echo ${opts[@]} "${ERROR_COLOR}${args[@]}${RESET_COLOR}"
  return 1
}

# Simple check mark. Increment the number of successes
ok() {
  ((SUCCESS++))
  echo "${GOOD_COLOR} ${SUCCESS_SYMBOL} ${RESET_COLOR}"
}

# Simple cross mark. Increment the number of errors
# Always return 1 (error)
ko() {
  echo "${BAD_COLOR} ${ERROR_SYMBOL} ${RESET_COLOR}"
  ((ERRORS++))
  return 1
}

# Simple warning mark. Increment the number of warnings
warn() {
  ((WARNINGS++))
  echo "${WARNING_COLOR} ${WARNING_SYMBOL} ${RESET_COLOR}"
}

# Helper message that prints time in gray and a message in blue
# This should be used before log_cmd
working() {
  info -n "[$(date +%H:%M:%S)] "
  parse_opt "$@"
  echo ${opts[@]} "${WORKING_COLOR}${args[@]}${RESET_COLOR}"
}

# Stops the dot_working function and print elapsed time with a mark depending
# whether the previously ran command ended correctly.
# INTERNAL FUNCTION
cleanup() {
  local elapsed
  while [[ "$DOT" == "" ]]; do
    # :nocov:
    sleep 1
    # :nocov:
  done
  kill $DOT 2>/dev/null
  wait $DOT 2>/dev/null
  DOT=
  if [[ "$1" != -99 ]]; then
    $WORKING_END
  fi
  elapsed="$(get_timer 1)"
  echo -n "[$(ptime $(echo "$elapsed"))]"
  if [[ "$1" == 0 ]]; then
    ok
  fi
}

# Function called when the user kills the script
killed() {
  # clean ^C
  printf "\033[2D"
  #kill 0
  if [[ "$DOT" != "" ]]; then
    cleanup -99
  fi
  bad " ${KILLED_SYMBOL} "
  finish
  exit 1
}

# Main command to run a task and log the output
# log_cmd [OPTIONS] NAME COMMAND || (ko|warn)
# Enter the command normally. You must escape any special shell characters (&, |, &&, ||, ;)
# Follow this command by || ko or || warn depending of how bad it is
# for the command to fail
# OPTIONS:
# -c, --critical: If this task is marked as critical, the scripto will stop
# right away and launch less on the last error output of the file
# -o, --overwrite: Don't use a new name for error and standard output files if
# the file already exists. You should always use this option if you don't need
# to save the output of a command ran inside a loop.
log_cmd() {
  local cmd critical p name p_cmd i overwrite tmp
  reset_timer 1
  $WORKING &
  DOT=$!
  critical=
  overwrite=
  for i in "$@"; do
    case $i in
      -c|--critical)
        critical=YES
        shift
        ;;
      -o|--overwrite)
        overwrite=YES
        shift
        ;;
      -[a-z0-9]|--*)
        error "[task-logger] Option $i doesn't exists for log_cmd"
        shift
        ;;
    esac
  done
  name="$1"
  # check if name can be be used as a file
  i=0
  if [[ -z "$overwrite" ]]; then
    tmp="$name"
    while [[ -f "${LOG_DIR}/${name}.out" || -f "${LOG_DIR}/${name}.err" ]]; do
      ((i++))
      name="$tmp-$i"
    done
  fi
  cmd="$2"
  shift
  shift
  if [[ "$critical" == YES ]]; then
    $cmd "$@" > ${LOG_DIR}/${name}.out 2> ${LOG_DIR}/${name}.err &
    p_cmd=$!
    wait $p_cmd 2>/dev/null
    p=$?
    cleanup $p
    if [[ "$p" != 0 ]]; then
      error ' CRITICAL '
      warning "Log is at ${LOG_DIR}/${name}.err"
      less ${LOG_DIR}/${name}.err
      exit 1
    fi
  else
    $cmd "$@" > ${LOG_DIR}/${name}.out 2> ${LOG_DIR}/${name}.err &
    p_cmd=$!
    wait $p_cmd 2>/dev/null
    p=$?
    cleanup $p
    return $p
  fi
}

# Helper function that should be called at the end.
# Prints a summary with the number of errors, warnings and successes
# If there are no errors, cleanup the whole log directory
finish() {
  local no_cleanup force_cleanup
  for i in "$@"; do
    case $i in
      -c|--no-cleanup)
        no_cleanup=YES
        shift
        ;;
      -f|--force-cleanup)
        force_cleanup=YES
        shift
        ;;
      *)
        ;;
    esac
  done
  info -n "[$(date +%H:%M:%S)] "
  echo "Finished: ${END_GOOD_COLOR}$SUCCESS ✓ ${END_WARNING_COLOR}$WARNINGS ⚠ ${END_BAD_COLOR}$ERRORS ✗${RESET_COLOR}"
  if test "$force_cleanup" -o \( "$ERRORS" -le 0 -a ! "$no_cleanup" \); then
    tmp_cleanup
  fi
}

# Clean the tmp data. If your script run for a very long time you migth want
# to clean up the mess in tmp.
# This function may be called at any time and it is called by the finish
# method if there were no errors
tmp_cleanup() {
  local dir
  if [[ ! -z "$1" ]]; then
    dir="$1"
  else
    dir="$LOG_DIR"
  fi
  if ! rm -rf "$dir"; then
    bad "Error cleaning up the logs"
  fi
}

# Exit correctly with <C-C>
trap 'killed' SIGINT SIGTERM
set_colors

# Create a folder to redirect standard an error output
new_log_dir() {
  LOG_DIR=$(mktemp -d /tmp/task-logger-XXXXXXXX)
}
new_log_dir

# Reset global variables used for counting errors, warnings and successes
# If you're calling finish multiple times you may need this
reset_counters() {
  ERRORS=0
  WARNINGS=0
  SUCCESS=0
}

