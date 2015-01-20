# Counting for errors
ERRORS=0
# Counting for warnings
WARNINGS=0
# Counting for successes
SUCCESS=0

# Parse options and args and place them in two global variables
# args and opts
# INTERNAL FUNCTION
parse_opt() {
  local io ia
  args=() # array
  opts=()
  io=0
  ia=0
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

# How many seconds does a dot represent
DOT_SECONDS=1
# Print dots in order to show progress.
# This functions should be called with & and killed when job is done
# INTERNAL FUNCTION
dot_working() {
  WORKING=YES
  while true; do
    echo -n '.'
    sleep $DOT_SECONDS
  done
}

# Little timer helper using perl to have microseconds precision even in OS X
# ex reset_timer 1 # set timer with id 1 at 0s
TIMER_INIT=()
reset_timer() {
  TIMER_INIT[$1]=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; print $a.$b;')
}

# get the current value of a timer without resetting it
# ex get_timer 1 get elapsed time since last reset_timer 1 call
get_timer() {
  local timer_end
  timer_end=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; print $a.$b;')
  elapsed=$(echo "scale=3; ($timer_end - ${TIMER_INIT[$1]}) / 1000000" | bc)
  echo "$elapsed"
}

# simple regex to parse options
re='^--?[a-zA-Z0-9]+'

# Important message that must be read and contains useful information
# Accepts same options as echo
important() {
  parse_opt "$@"
  echo ${opts[@]} "[104;30m${args[@]}[0m"
}

# Warning message in yellow
# Accepts same options as echo
warning() {
  parse_opt "$@"
  echo ${opts[@]} "[33m${args[@]}[0m"
}

# Print a message in green
# Accepts same options as echo
good() {
  parse_opt "$@"
  echo ${opts[@]} "[32m${args[@]}[0m"
}

# Print a message in red
# Accepts same options as echo
bad() {
  parse_opt "$@"
  echo ${opts[@]} "[31m${args[@]}[0m"
}

# Print a message in gray
# Accepts same options as echo
info() {
  parse_opt "$@"
  echo ${opts[@]} "[90m${args[@]}[0m"
}

# Error message with Red background
# Fits critical errors
# Accepts same options as echo
error() {
  parse_opt "$@"
  echo ${opts[@]} "[101m${args[@]}[0m"
  return 1
}

# Simple check mark. Increment the number of successes
ok() {
  echo "[32m ✓ [0m"
  ((SUCCESS++))
}

# Simple cross mark. Increment the number of errors
ko() {
  echo "[31m ✗ [0m"
  ((ERRORS++))
  return 1
}

# Simple warning mark. Increment the number of warnings
warn() {
  ((WARNINGS++))
  echo "[33m ⚠ [0m"
}

# Helper message that prints time in gray and a message in blue
# This should be used before log_cmd
working() {
  info -n "[$(date +%H:%M:%S)] "
  parse_opt "$@"
  echo ${opts[@]} "[94m${args[@]}[0m"
}

# Stops the dot_working function and print elapsed time with a mark depending
# whether the previously ran command ended correctly.
# INTERNAL FUNCTION
cleanup() {
  local elapsed LOG_END
  while [[ "$DOT" == "" ]]; do
    sleep 1
  done
  kill $DOT 2>/dev/null
  wait $DOT 2>/dev/null
  DOT=
  LOG_END=$(perl -e 'use Time::HiRes qw( gettimeofday ); my ($a, $b) = gettimeofday; print $a.$b;')
  echo -n "[$(get_timer 0) s]"
  if [[ "$1" == 0 ]]; then
    ok
  fi
}

# Function called when the user kills the script
killed() {
  kill 0
  if [[ "$DOT" ]]; then
    cleanup 1
  fi
  bad " ☠ "
  exit 1
}

# Main command to run a task and log the output
# log_cmd [OPTIONS] NAME COMMAND || (ko|warn)
# Enter the command normally. You must escape any special shell characters (&, |, &&, ||, ;)
# Follow this command by || ko or || warn depending of how bad it is
# for the command to fail
log_cmd() {
  local cmd critical p name p_cmd
  reset_timer 0
  dot_working &
  DOT=$!
  critical=
  if [[ "$1" == "-c" ]]; then
    critical=YES
    shift
  fi
  name="$1"
  cmd="$2"
  shift
  shift
  if [[ "$critical" == YES ]]; then
    $cmd "$@" > ${LOG_DIR}/${name}.out 2> ${LOG_DIR}/${name}.err &
    p_cmd=$!
    wait $p_cmd
    p=$?
    cleanup $p
    if [[ "$p" != 0 ]]; then
      error ' CRITICAL '
      warning "Checking log at ${LOG_DIR}/${name}.err"
      less ${LOG_DIR}/${name}.err
      exit 1
    fi
  else
    $cmd "$@" > ${LOG_DIR}/${name}.out 2> ${LOG_DIR}/${name}.err &
    p_cmd=$!
    wait $p_cmd
    p=$?
    cleanup $p
    return $p
  fi
}

# Helper function that should be called at the end.
# Prints a summary with the number of errors, warnings and successes
finish() {
  info -n "[$(date +%H:%M:%S)] "
  echo "Finished: [92m$SUCCESS ✓ [93m$WARNINGS ⚠ [91m$ERRORS ✗[0m"
}

# Exit correctly with <C-C>
trap 'killed' SIGINT SIGTERM

# Create a folder to redirect standard an error output
LOG_DIR=$(mktemp -d /tmp/sparkXXXXXXXX)

