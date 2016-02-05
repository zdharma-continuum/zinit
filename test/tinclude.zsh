typeset -gH ___TEST_NAME="${${1:t}:r}"

___TEST_DIR="`pwd`"

if [ "${___TEST_DIR/\/zplugin/}" = "${___TEST_DIR}" ]; then
    echo "Test run not from zplugin's directory tree"
    return 1
fi

if [ "${___TEST_DIR:t}" != "test" ]; then
    () {
        setopt localoptions extendedglob
        local -a match mbegin mend
        local MATCH; integer MBEGIN MEND

        ___TEST_DIR="${___TEST_DIR/\/zplugin*//zplugin/test}"
    }
fi

if [ ! -d "$___TEST_DIR" ]; then
    echo "Could not resolve test directory (tried $___TEST_DIR)"
    return 1
fi

export TERM=vt100

___REPORT_FILE="$___TEST_DIR/models/${___TEST_NAME}_report.txt"
___UNLOAD_FILE="$___TEST_DIR/models/${___TEST_NAME}_unload.txt"
___TEST_REPORT_FILE="$___TEST_DIR/.report.txt"
___TEST_UNLOAD_FILE="$___TEST_DIR/.unload.txt"
___DIFF_FILE="$___TEST_DIR/.diff"
___SUCCEEDED_MSG="--- Succeeded ---"
___FAILED_MSG="--- Failed [ < model, > result ] ---"
___STARTING_MSG="----- Starting $___TEST_NAME -----"
___ZPLG_TESTING_HOME="$___TEST_DIR/tzplugin"

#
# Functions
#

---start() {
    print -- "$___STARTING_MSG"
}

---stop() {
    integer len="${#___STARTING_MSG}"
    integer left_len=len/2
    integer right_len=len-left_len
    print -- "${(r:left_len-3::-:):--} END ${(r:right_len-2::-:):--}"
}

---s-or-f() {
    [ "$1" -eq "0" ] && print -- "$___SUCCEEDED_MSG" || print -- "$___FAILED_MSG"
}

---compare() {
    print
    diff "$___REPORT_FILE" "$___TEST_REPORT_FILE" > "$___DIFF_FILE"
    ---s-or-f $?
    cat "$___DIFF_FILE"

    print "\n----- REPORT results showed, hit enter for UNLOAD results -----"
    local enter
    read enter

    diff "$___UNLOAD_FILE" "$___TEST_UNLOAD_FILE" > "$___DIFF_FILE"
    ---s-or-f $?
    cat "$___DIFF_FILE"

    print "\n----- End of $___TEST_NAME -----"
}

#
# Load zplugin (testability maintained)
#

ZPLG_TESTING_HOME="$___ZPLG_TESTING_HOME"
cd "$___TEST_DIR"
cd ..
source "./zplugin.zsh"
