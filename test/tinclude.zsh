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

bkpTERM="$TERM"
export TERM=vt100

___REPORT_FILE="$___TEST_DIR/models/${___TEST_NAME}_report.txt"
___UNLOAD_FILE="$___TEST_DIR/models/${___TEST_NAME}_unload.txt"
___ENV_FILE="$___TEST_DIR/models/${___TEST_NAME}_env.txt"
___OUT_FILE="$___TEST_DIR/models/${___TEST_NAME}_out.txt"
___TEST_REPORT_FILE="$___TEST_DIR/.report.txt"
___TEST_UNLOAD_FILE="$___TEST_DIR/.unload.txt"
___TEST_ENV_FILE="$___TEST_DIR/.env.txt"
___TEST_OUT_FILE="$___TEST_DIR/.out.txt"
___DIFF_FILE="$___TEST_DIR/.diff"
___SUCCEEDED_MSG="--- Succeeded ---"
___FAILED_MSG="--- Failed [ < model, > result ] ---"
___STARTING_MSG="----- Starting ${(U)___TEST_NAME} -----"
___ZPLG_TESTING_HOME="$___TEST_DIR/tzplugin"

#
# Functions
#

___restore_term() {
    if [ -z "${functions[colors]}" ]; then
        autoload -Uz colors
        colors
    fi
    if [ "$TERM" = "vt100" ]; then
        export TERM="$bkpTERM"
    fi
}

___msg() {
    [ "$2" = "color" ] && ___restore_term

    integer len="${#___STARTING_MSG}"
    integer left_len=len/2
    integer right_len=len-left_len

    local msg=" $1 "
    integer len2="${#msg}"
    integer left_correct=len2/2
    integer right_correct=len2-left_correct

    print -- "${fg_bold[blue]}${(r:left_len-left_correct::-:):--}${msg}${(r:right_len-right_correct::-:):--}$reset_color"
}

___s-or-f() {
    setopt localoptions extendedglob
    [ "$1" -eq "0" ] && print -- "${fg_bold[green]}$___SUCCEEDED_MSG$reset_color" || {
        local col="${fg_bold[green]}" main="${fg_bold[red]}"
        print -- "${main}${___FAILED_MSG//(#m)(model|result)/${col}${MATCH}${main}}$reset_color"
    }
}

#
# User functions
#

---start() {
    print -- "$___STARTING_MSG"
    command rm -f "$___TEST_REPORT_FILE" "$___TEST_UNLOAD_FILE" "$___TEST_ENV_FILE" "$___TEST_OUT_FILE"
}

---stop() {
    ___msg "END"
}

---dumpenv() {
    print "ZPLG_DIR '$ZPLG_DIR'"
    print "ZPLG_NAME '$ZPLG_NAME'"
    print "ZPLG_HOME '$ZPLG_HOME'"
    print "ZPLG_PLUGINS_DIR '$ZPLG_PLUGINS_DIR'"
    print "ZPLG_COMPLETIONS_DIR '$ZPLG_COMPLETIONS_DIR'"
    print "ZPLG_SNIPPETS_DIR '$ZPLG_SNIPPETS_DIR'"
    print "ZPLG_HOME_READY '$ZPLG_HOME_READY'"
}

---end() {
    print
    ___msg "End of ${(U)___TEST_NAME}" "color"
}

---mark() {
    ___msg "Additional data ^" "color"
}

---compare() {
    local ret

    ___restore_term

    print "\n${fg_bold[yellow]}----- Press any key for REPORT results -----$reset_color"
    read -sk

    diff "$___REPORT_FILE" "$___TEST_REPORT_FILE" > "$___DIFF_FILE"
    ret=$?
    print
    ___s-or-f $ret
    cat "$___DIFF_FILE"

    print "\n${fg_bold[yellow]}----- ${fg_bold[magenta]}REPORT${fg_bold[yellow]} results showed, press any key for UNLOAD results -----$reset_color"
    read -sk

    diff "$___UNLOAD_FILE" "$___TEST_UNLOAD_FILE" > "$___DIFF_FILE"
    ret=$?
    print
    ___s-or-f $ret
    cat "$___DIFF_FILE"

    print "\n${fg_bold[yellow]}----- ${fg_bold[magenta]}UNLOAD${fg_bold[yellow]} results showed, press any key for ENVIRONMENT results -----$reset_color"
    read -sk

    diff "$___ENV_FILE" "$___TEST_ENV_FILE" > "$___DIFF_FILE"
    ret=$?
    print
    ___s-or-f $ret
    cat "$___DIFF_FILE"

    if [ ! -f "$___TEST_OUT_FILE" ]; then
        print "\n${fg_bold[yellow]}----- End of ${fg_bold[magenta]}ENVIRONMENT${fg_bold[yellow]} results -----$reset_color"
    else
        print "\n${fg_bold[yellow]}----- ${fg_bold[magenta]}ENVIRONMENT${fg_bold[yellow]} results showed, press any key for OUTPUT results -----$reset_color"
        read -sk

        diff "$___OUT_FILE" "$___TEST_OUT_FILE" > "$___DIFF_FILE"
        ret=$?
        print
        ___s-or-f $ret
        cat "$___DIFF_FILE"

        print "\n${fg_bold[yellow]}----- End of ${fg_bold[magenta]}OUTPUT${fg_bold[yellow]} results -----$reset_color"
    fi
}

#
# Load zplugin (testability maintained)
#

ZPLG_HOME="$___ZPLG_TESTING_HOME"
cd "$___TEST_DIR"
cd ..
source "./zplugin.zsh"
