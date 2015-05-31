#! /bin/bash

# task-logger.sh 1.0 - zsh and bash fancy task logging
# Copyright (C) 2015 Eduardo San Martin Morote
# Last modification date: 2015-06-01
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
  TIMER_INIT[$1]=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; $t = $a.$b;for (my $i = length $t; $i < 16; $i++){ $t = $t."0";} print $t;')
}

# get the current value of a timer without resetting it
# ex get_timer 1 get elapsed time since last reset_timer 1 call
get_timer() {
  local timer_end
  timer_end=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; $t = $a.$b;for (my $i = length $t; $i < 16; $i++){ $t = $t."0";} print $t;')
  elapsed=$(echo "scale=3; ($timer_end - ${TIMER_INIT[$1]}) / 1000000" | bc | sed 's/^-.*/0/g')
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
  echo -n "[$(get_timer 1) s]"
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
finish() {
  info -n "[$(date +%H:%M:%S)] "
  echo "Finished: ${END_GOOD_COLOR}$SUCCESS ✓ ${END_WARNING_COLOR}$WARNINGS ⚠ ${END_BAD_COLOR}$ERRORS ✗${RESET_COLOR}"
}

# Exit correctly with <C-C>
trap 'killed' SIGINT SIGTERM
set_colors

# Create a folder to redirect standard an error output
LOG_DIR=$(mktemp -d /tmp/task-logger-XXXXXXXX)

