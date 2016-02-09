#!/usr/bin/env zsh

#
# Common test suite code
#

setopt KSH_ARRAYS
source "`pwd`/${0:h}/tinclude.zsh" "$0" || exit 1

#
# Start Dtrace
#

---start
zplugin dtrace

###
### Test body
###

{

zplugin dstart

echo "### Zstatus "
zplugin zstatus
echo -e "\n### List ###"
zplugin list
echo -e "\n### Clist ###"
zplugin clist
echo -e "\n### Csearch ###"
zplugin csearch
echo -e "\n### Compile-all ###"
zplugin compile-all
echo -e "\n### Uncompile-all ###"
zplugin uncompile-all

zplugin dstop

} >> "$___TEST_OUT_FILE"

#
# Stop Dtrace
#

zplugin dstop
---stop

###
### Gather and compare results
###

zplugin dreport > "$___TEST_REPORT_FILE" 2>&1
zplugin dunload > "$___TEST_UNLOAD_FILE" 2>&1
---dumpenv > "$___TEST_ENV_FILE" 2>&1

---compare
---end
