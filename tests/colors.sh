#! /bin/bash

DIR=$(pwd)
cd "$(dirname "$0")"

source ../task-logger.sh
source ../lib/assert.sh

# first with colors
set_colors
assert 'info "sample text"' "${INFO_COLOR}sample text${RESET_COLOR}"
assert 'good "sample text"' "${GOOD_COLOR}sample text${RESET_COLOR}"
assert 'bad "sample text"' "${BAD_COLOR}sample text${RESET_COLOR}"
assert 'warning "sample text"' "${WARNING_COLOR}sample text${RESET_COLOR}"
assert 'error "sample text"' "${ERROR_COLOR}sample text${RESET_COLOR}"
assert 'important "sample text"' "${IMPORTANT_COLOR}sample text${RESET_COLOR}"
assert 'working "sample text" | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g"' "${INFO_COLOR}[00:00:00] ${RESET_COLOR}${WORKING_COLOR}sample text${RESET_COLOR}"

# then without
no_colors
assert 'info "sample text"' "sample text"
assert 'good "sample text"' "sample text"
assert 'bad "sample text"' "sample text"
assert 'warning "sample text"' "sample text"
assert 'error "sample text"' "sample text"
assert 'important "sample text"' "sample text"
assert 'working "sample text" | sed "s/\[[0-9]*:[0-9]*:[0-9]*\]/[00:00:00]/g"' "[00:00:00] sample text"

assert_end messages-text

cd "$DIR"
