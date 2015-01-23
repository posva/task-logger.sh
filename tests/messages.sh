#! /bin/bash

DIR=$(pwd)
cd "$(dirname "$0")"

source ../task-logger.sh
source ../lib/assert.sh

assert 'info "info message"' "${INFO_COLOR}info message${RESET_COLOR}"

assert_end messages-text

cd "$DIR"
