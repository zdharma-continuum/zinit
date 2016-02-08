#!/bin/zsh

#
# Do some setup
# Script can be run from arbitrary directory under zplugin/ tree
#

setopt NO_KSH_ARRAYS
source "`pwd`/${0:h}/tinclude.zsh" "$0" || exit 1

#
# Start Dtrace
#

---start

###
### Test body
###

local PLUGIN_NAME="_local/opp.zsh"
zplugin load "$PLUGIN_NAME"

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
