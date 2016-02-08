#!/bin/zsh

#
# Do some setup
# Script can be run from arbitrary directory under zplugin/ tree
#

emulate ksh
source "`pwd`/${0:h}/tinclude.zsh" "$0" || exit 1

#
# Start Dtrace
#

---start

###
### Test body
###

local PLUGIN_NAME="_local/smart-cd"
local SMART_CD_GIT_STATUS="false"
cd test/tzplugin/plugins/_local---smart-cd/test_dir
{
    zplugin load "$PLUGIN_NAME"
    cd ../test_dir2
} > "$___TEST_OUT_FILE"

#
# Stop Dtrace
#

---stop

###
### Gather and compare results
###

zplugin report "$PLUGIN_NAME" > "$___TEST_REPORT_FILE" 2>&1
zplugin unload "$PLUGIN_NAME" > "$___TEST_UNLOAD_FILE" 2>&1
---dumpenv > "$___TEST_ENV_FILE" 2>&1

---compare
---end
