# surround.vim-ish for zsh.

# Author: Takeshi Banse <takebi@laafc.net>
# Licence: Public Domain

# Thank you very much, Tim Pope!
# I want to use the surround.vim in zsh.

# Configuration
# Predefined targets as follows,
#
# Eight punctiation marks with aliased by, (k is my taste)
#   [ ]  < >  ( )  { }
#     k         b    B
# When insertion,
#   [, <, ( and { will add the pairs with one whitespace
#   ], >, ) and } will add the pairs without whitespaces
#   k,    b and B will add the pairs without whitespaces
# When deletion,
#   [, <, ( and { will remove the pairs with stripping any whitespaces
#   ], >, ) and } will remove the pairs without stripping
#   k,    b and B will remove the pairs without stripping
#
# and three quate marks.
#   " ' `
#
# To customize the surroundings, you can use the function `def-opp-surround'.
#   def-opp-surround KEYBINDING LEFT RIGHT STRIPP(t|nil)
# For example,
# % def-opp-surround '${' '${' '}' t
# will associate a keybinding '${' to replace the pair # '${','}'.
# You will get the followings,
#   Old text              Command  New text
#   "Hello ${ w*orld }!"  ds${     Hello world!
#   "Hello ${w*orld}!"    ds${     Hello world!
#   "Hello ${w*orld}!"    cs${'    Hello 'world'!
#   "Hello w*orld!"       ysiw${   Hello ${world}!
# (An asterisk (*) is used to denote the cursor position.)
#
# STRIPP (t|nil) controls the whitespace retaining/stripping behavior.
# If you use 'nil' instead of 't', for example,
# % def-opp-surround '${' '${' '}' nil
# You will get the following,
#   Old text              Command  New text
#   "Hello ${ w*orld }!"  ds${     Hello  world !
# Please notice that the whitespaces surrounding the "world" are not
# stripped in this case.

# TODO: parameterize these 'y, c, d and s's.
# TODO: insert mode mappings.

# Code

opp_surround_op=
def-oppc s opp+surround; opp+surround () {
  local op="$opp_keybuffer"
  {
    opp_surround_op=${opp_surround_op:-$op}
    # TODO: parameterize
    [[ $op == 'y' ]] && {
      zle opp-recursive-edit opp-s-read+y opp-id opp-id nil; return $?
    } || [[ -n $opp_surround_op ]] && {
      opp-s-read $opp_surround_op opp-surround; return $?
    }
  } always {
    opp_surround_op=
    zle set-mark-command -n -1
    zle -R
    succ=vi-cmd-mode # TODO: THIS IS VERY BAD
  }
}

opp-s-reading () {
  [[ -n ${OPP_SURROUND_VERBOSE-} ]] || return
  local f0="$1"
  local op="$2"
  local  a="$3"
  shift 3
  local b=; # b+="$f0"
  b+="${op[1]}s"; (($#@!=0)) && { b+="{$@[1]|$@[2]}" }; b+="$a"
  zle -R "$b"
}

opp-s-read+y () {
  opp-s-reading "$0" "y" ''
  opp-s-read $opp_surround_op opp-surround
}; zle -N opp-s-read+y

opp-s-read () {
  local   op="$1"; shift
  local succ="$1"; shift
  # TODO: parameterize
  [[ $op == 'y' ]] && [[ $KEYS == 's' ]] && {
    opp-s-read+linewise; return $?
  } || {
    opp-s-read-1 "$op" "$succ" opp-s-reading "$@"
  }
}

opp-s-read+linewise () {
  opp-s-read "linewise" opp-surround
}

opp-s-read-1 () {
  local   op="$1"; shift
  local succ="$1"; shift
  local mess="$1"; shift
  opp-s-read-acc () {
    opp-s-read-acc-base "$@";{local -i ret=$?; ((ret==255)) || return $((ret))}
    local      c="$1"
    local aplace="$2"
    local avalue="$3"
    [[ $op == 'c' ]] && {
      local e="$4"; local -a ks; {eval "ks=($e)"}
      local -i n0; ((n0=${#${(@M)ks:#$avalue${c}*}}))
      local -i n1; ((n1=${#${(@M)ks:#${c}*}}))
      ((n0==0)) && ((n1!=0)) && {
        # XXX: ambigous.
        zle -U "$c"; return 0
      }
    }
    : ${(P)aplace::=$avalue$c}
    return -1
  }
  opp-s-read-2 "$op" opp-s-read-acc "$succ" opp-s-read-fail "$mess" "$@"
}

opp-s-read-acc-base () {
  local      c="$1"
  local aplace="$2"
  local avalue="$3"
  [[ $c == "" ]]          && return -255 # XXX: read interrupted
  [[ $c == "" ]]        && return 0
  [[ $c == "" ]]        && {: ${(P)aplace::=$avalue[1,-2]}; return  1}
  [[ $c != [[:print:]] ]] && return 0
  [[ -z $avalue ]]        && {: ${(P)aplace::=$avalue$c}    ; return -1}
  return 255 # indicate to the caller that it did *not* return.
}

opp-s-read-2 () {
  local   op="$1"; shift
  local pacc="$1"; shift
  local succ="$1"; shift
  local fail="$1"; shift
  local mess="$1"; shift

  "$mess" "$0" "$op" '' "$@"

  local c; read -s -k 1 c
  { # TODO: parameterize
    [[ $op == 'd' ]] && [[ $c == 's' ]] && return -1
    [[ $op == 'c' ]] && [[ $c == 's' ]] && {opp-s-read+linewise; return $?}
  }
  opp-s-loop \
    "$op" \
    '${(@k)opp_surrounds}' \
    "$c" \
    "$pacc" \
    '' \
    0 \
    "$succ" \
    "$fail" \
    "$mess" \
    "$succ" \
    "$fail" \
    "$@"
}

opp-s-loop () {
  local o="$1"
  local e="$2"; local -a ks; { eval "ks=($e)" }
  local c="$3"
  local p="$4"
  local a="$5"; "$p" "$c" a "$a" "$e"; local -i r=$?
  local f="$6"
  local succ="$7"
  local fail="$8"
  local mess="$9"
  local sk="$10"
  local fk="$11"
  shift 11 # At this point "$@" indicates refering the &rest argument.

  ((r==-255)) && { return -1 }
  ((r==   1)) && { f=0; succ=$sk; fail=$fk } # XXX: >_<

  "$mess" "$0" "$o" "$a" "$@"

  opp-s-loop-1 () {
    local fn="$1"; shift
    "$fn" $o $e "$c" $p "$a" $f $succ $fail $mess $sk $fk "$@"
  }
  local -i n0; ((n0=${#${(@M)ks:#${a}}} ))
  local -i n1; ((n1=${#${(@M)ks:#${a}*}}))
  ((n0==1)) && ((r ==0)) &&              {"$succ" "$o" "$a" "$@";return $?} ||
  ((n0==1)) && ((n1==1)) &&              {"$succ" "$o" "$a" "$@";return $?} ||
  ((n1==0)) && ((r ==0)) && ((f ==1)) && {"$succ" "$o" "$a" "$@";return $?} ||
  ((n1==0)) && {   opp-s-loop-1    "$fail" "$@";return $?                 } ||
  { read -s -k 1 c;opp-s-loop-1 opp-s-loop "$@";return $?}
}

opp-s-read-fail () {
  local o="$1"
  local e="$2"; local -a ks; { eval "ks=($e)" }
  local c="$3"
  local p="$4"
  local a="$5"
  local f="$6"
  local succ="$7"
  local fail="$8"
  local mess="$9"
  local sk="$10"
  local fk="$11"
  shift 11 # At this point "$@" indicates refering the &rest argument.

  opp-surround-tagish () {
    local o="$1"
    local tagish="$2"; [[ $tagish == '<'* ]] || return -1
    local tag1="$tagish"
    local tag2="</$tag1[2,-1]"
    shift 2
    [[ -z ${1-} ]] && [[ -z ${2-} ]] && {
      "$opp_sopps[$o]" "$tag1" "$tag2"; return $?
    } || {
      opp-s-wrap-maybe nil $tag1 $tag2 $1 $2
    }
  }
  # TODO: Add an appropriate code for editing the command line.
  # XXX: Embeded the tag code for the place-holder purpose.
  # XXX: Please `unset "opp_surrounds[<]"' if you want to see the effect.
  opp-s-read-acc-tagish () {
    opp-s-read-acc-base "$@";{local -i ret=$?; ((ret==255)) || return $((ret))}
    local      c="$1"
    local aplace="$2"
    local avalue="$3"
    : ${(P)aplace::=$avalue$c}
    [[ -n ${avalue-} ]] && [[ $avalue[1] == '<' ]] && [[ $c == '>' ]] && {
      return 0
    }
    return -1
  }
  [[ $o == 'c' ]] && (($#@!=0)) && [[ -n $c ]] &&
  [[ $c != '<' ]] && [[ $a[1] != '<' ]] && [[ $c != '>' ]]  && {
    opp-s-wrap-maybe nil $c $c "$@"; return $?
  }

  "$mess" "$0" "$o" "$a" "$@"

  read -s -k 1 c
  opp-s-loop  $o $e "$c" \
    opp-s-read-acc-tagish "$a" 1 opp-surround-tagish \
    $fail $mess $sk $fk "$@"
}

typeset -A opp_surrounds; opp_surrounds=()
def-opp-surround-raw () {
  local keybind="$1"
  local     fun="$2"
  local       a="$3"
  local       b="$4"
  local  stripp="$5"
  shift 5
  local expanded=
  local x; for x in $@; do
    expanded+="reply+=${(q)x};"
  done
  opp_surrounds+=("$keybind" opp+surround"$keybind")
  eval "$(cat <<EOT
    opp+surround${(q)keybind} () {
      reply=(${(q)fun} ${(q)a} ${(q)b} ${(q)stripp})
      ${expanded}
    }
EOT
  )"
}

def-opp-surround-0 () {
  local k="$1" a="$2" b="$3" sp="$4"; shift 4
  def-opp-surround-raw "$k" opp-surround-sopp "$a" "$b" "$sp" "$@"
}

def-opp-surround () {
  local k="$1" a="$2" b="$3"
  local sp;
  (($#@==3)) && { sp=nil       ; shift 3}
  (($#@>=4)) && { sp="${4-nil}"; shift 4}
  def-opp-surround-0 "$k" "$a" "$b" "$sp" "$@"
}

def-opp-surround-pair () {
  {
    DAS () {
      def-opp-surround "$1" "$1 " " $2" t "$1" "$2"
      def-opp-surround "$2" "$1" "$2" nil
      [[ -n ${3-} ]] && def-opp-surround "$3" "$1" "$2" nil
    }
    local x; while read x; do
      [[ -n $x ]] && {
        local -a y; while read -A y; do
          DAS "$y[1]" "$y[2]" "${y[3]-}"
        done <<< "$x"
      }
    done
  } always { unfunction DAS } <<< "$1"
}

# XXX: 'k' stands for 'bracKet'. (my taste)
def-opp-surround-pair '
  [ ] k
  < >
  ( ) b
  { } B
'

def-opp-surround-q () {
  local s; for s in "$@"; do
    def-opp-surround "$s" "$s" "$s" nil
  done
}

def-opp-surround-q '"' "'" '`'

typeset -A opp_sopps; opp_sopps=()
opp_sopps+=(linewise opp-surround+linewise)
opp_sopps+=(y opp-surround+y) # TODO: link this key 'y' <=> def-oppc's 'y'
opp_sopps+=(d opp-surround+d)
opp_sopps+=(c opp-surround+c)

opp-surround () {
  local o="$1"
  local k="$2"
  local -a box; opp-s-ref $opp_surrounds[$k] box
  local   proc="$box[1]"
  local   arg1="$box[2]"
  local   arg2="$box[3]"
  local stripp="$box[4]"
  shift 4 box
  "$proc" "$o" "$arg1" "$arg2" "$stripp" "$box[@]"
}

opp-surround-sopp () {
  local o="$1"; shift
  "$opp_sopps[$o]" "$@"
}

opp-s-ref () {
  local ebody=$1
  local place=$2
  local -a reply; "$ebody"; eval "$place=(${(q)reply[@]})"
}

opp-surround+linewise () {
  zle vi-goto-column -n 0
  [[ ${BUFFER[((CURSOR+1))]-} == [[:blank:]] ]] && opp-skip-blank-forward
  RBUFFER="${1}$RBUFFER"
  zle vi-goto-column -n 0; zle end-of-line
  [[ ${BUFFER[((CURSOR+0))]-} == [[:blank:]] ]] && opp-skip-blank-backward
  LBUFFER="$LBUFFER${2}"
}

opp-surround+y () {
  RBUFFER="${2}${RBUFFER}"
  zle exchange-point-and-mark
  LBUFFER="${LBUFFER}${1}"
  zle set-mark-command -n -1
}

opp-surround+d () {
  local a1="$1"; shift
  local a2="$1"; shift
  local sp="$1"; shift
  opp-s-wrap-maybe "$sp" '' '' "$a1" "$a2" "$@"
}

opp-surround+c () {
  opp-s-read "c" opp-surround+c-1 "$@"
}

opp-surround+c-1 () {
  shift
  local  k="$1"
  local s1="$2"
  local s2="$3"
  local sp="$4"
  shift 4
  [[ -n "$opp_surrounds[$k]" ]] && {
    local -a box; opp-s-ref "$opp_surrounds[$k]" box
    local   _proc="$box[1]"
    local    arg1="$box[2]"
    local    arg2="$box[3]"
    local _stripp="$box[4]"
    shift 4 box # TODO: pass the 'box[@]' downward somehow.
    opp-s-wrap-maybe $sp $arg1 $arg2 $s1 $s2 "$@"
  } || {
    opp-s-wrap-maybe $sp $k $k $s1 $s2 "$@"
  }
}

opp-s-wrap-maybe () {
  local sp="$1"
  local t1="$2"
  local t2="$3"
  local s1="$4"
  local s2="$5"
  shift 5
  [[ $RBUFFER == *${s2}* ]] && [[ $LBUFFER == *${s1}* ]] && {
    [[ $RBUFFER == *${s2}* ]] && {
      local -i k; opp-s-wrap-scan 1 ${s2} ${s1} "$RBUFFER" +1 0 k
      (($?==0)) || return -1
      CURSOR+=k; ((CURSOR--))
      [[ $sp == t ]] && {
        zle set-mark-command
        opp-skip-blank-backward
        zle kill-region
      }
      zle set-mark-command
      CURSOR+=${#s2}
      zle kill-region
      RBUFFER=${t2}$RBUFFER
    }
    [[ $LBUFFER == *${s1}* ]] && {
      local -i k; opp-s-wrap-scan $#LBUFFER ${s1} ${s2} "$LBUFFER" -1 0 k
      (($?==0)) || return -1
      CURSOR=k; ((CURSOR--))
      zle set-mark-command
      CURSOR+=${#s1}
      [[ $sp == t ]] && opp-skip-blank-forward
      if [[ -n "${keymaps[(r)viopp]-}" ]]; then
        ((CURSOR--))
      fi
      zle kill-region
      LBUFFER=$LBUFFER${t1}
    }
    return 0
  }
  (($#@<2)) && return -1
  opp-s-wrap-maybe "$sp" "$t1" "$t2" "$@"; return $?
}

opp-s-wrap-scan () {
  local -i  pos="${1}"
  local       a="${2}"
  local       b="${3}"
  local     buf="${4}"
  local     suc="${5}"
  local -i nest="${6}"
  local   place="${7}"

  ((pos==0))           && return -1
  ((pos==(($#buf+1)))) && return -1

  [[ $a != $b  ]] && {       opp-generic-pair-scan "$@"; return $?}||
  [[ $suc = +1 ]] && { : ${(P)place::=${(BS)buf#${a}*}}; return 0 }||
  [[ $suc = -1 ]] && { : ${(P)place::=${(BS)buf%${a}*}}; return 0 }
}

# opp-installer
opp-installer-install-surround () {
  echo "typeset -g opp_surround_op="
  echo ${"$(typeset -p opp_sopps)"/typeset -A/typeset -gA}
  echo ${"$(typeset -p opp_surrounds)"/typeset -A/typeset -gA}
}; opp-installer-add opp-installer-install-surround
