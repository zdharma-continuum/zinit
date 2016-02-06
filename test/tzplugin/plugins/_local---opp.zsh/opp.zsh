# Vim's text-objects-ish for zsh.

# Author: Takeshi Banse <takebi@laafc.net>
# License: Public Domain

# Thank you very much, Bram Moolenaar!
# I want to use the Vim's text-objects in zsh.

# Code

bindkey -N opp

typeset -gA opps; opps=()
opp_keybuffer=

opp-accept-p () {
  [[ -n ${opps[$KEYS]-} ]] && return 0
  [[ $KEYS != *[1-9] ]]    && return 1
  return -1
}

opp-undefined-key () {
  opp_keybuffer+=$KEYS
  opp-accept-p; local ret=$?
  ((ret == 0)) && zle .accept-line
  ((ret == 1)) && zle .send-break
}

def-oppc () {
  # an abbreviation of DEFine OPerator-Pending-mode-Command.
  # see also opp-recursive-edit
  local keys="$1"
  local funcname="${2-opp+$1}"
  bindkey -M opp "$keys" .accept-line
  opps+=("$keys" "$funcname")
}

def-opp-skip () {
  eval "$(cat <<EOT
    $1 () { while [[ \${BUFFER[((CURSOR$3))]-} == $4 ]] do ((CURSOR$2)) done }
    zle -N $1
EOT
  )"
}
def-opp-skip opp-skip-blank-backward   -- -0 "[[:blank:]]"
def-opp-skip opp-skip-blank-forward    ++ +1 "[[:blank:]]"
def-opp-skip opp-skip-alnum-backward   -- -0 "[[:alnum:]_]"
def-opp-skip opp-skip-alnum-forward    ++ +1 "[[:alnum:]_]"
def-opp-skip opp-skip-punct-backward   -- -0 "[[:punct:]]~[_]"
def-opp-skip opp-skip-punct-forward    ++ +1 "[[:punct:]]~[_]"
def-opp-skip opp-skip-alpunum-backward -- -0 "[[:alnum:][:punct:]]"
def-opp-skip opp-skip-alpunum-forward  ++ +1 "[[:alnum:][:punct:]]"

opp-generic-w () {
  local -a fun1 fun2
  zparseopts -D 1+:=fun1 2+:=fun2
  local beg end fun
  local -a fs
  fs=(${=fun1}); for fun in ${fs:#-1}; do "$fun"; done; ((beg=$CURSOR))
  fs=(${=fun2}); for fun in ${fs:#-2}; do "$fun"; done; ((end=$CURSOR))
  "$@" $beg $end
}

def-oppc iw; opp+iw () {
  if [[ $BUFFER[((CURSOR+1))] == [[:blank:]] ]]; then
    opp-generic-w \
      -1 opp-skip-blank-backward \
      -2 opp-skip-blank-forward \
      -- \
      "$@"
  elif [[ $BUFFER[((CURSOR+1))] == [[:punct:]]~[_] ]]; then
    opp-generic-w \
      -1 opp-skip-punct-backward \
      -2 opp-skip-punct-forward \
      -- \
      "$@"
  else
    opp-generic-w \
      -1 opp-skip-alnum-backward \
      -2 opp-skip-alnum-forward \
      -- \
      "$@"
  fi
}

opp-skip-aw-forward-on-blank () {
  zle opp-skip-blank-forward
  if [[ $BUFFER[((CURSOR+1))] == [[:punct:]]~[_] ]]; then
    opp-skip-punct-forward
  else
    opp-skip-alnum-forward
  fi
}

def-oppc aw; opp+aw () {
  if [[ $BUFFER[((CURSOR+1))] == [[:blank:]] ]]; then
    opp-generic-w \
      -1 opp-skip-blank-backward \
      -2 opp-skip-aw-forward-on-blank \
      "$@"
  elif [[ $BUFFER[((CURSOR+1))] == [[:punct:]]~[_] ]]; then
    opp-generic-w \
      -1 opp-skip-punct-backward \
      -1 opp-skip-blank-backward \
      -2 opp-skip-blank-forward \
      -2 opp-skip-punct-forward \
      "$@"
  else
    opp-generic-w \
      -1 opp-skip-alnum-backward \
      -2 opp-skip-alnum-forward \
      -2 opp-skip-blank-forward \
      "$@"
  fi
}

def-oppc iW; opp+iW () {
  if [[ $BUFFER[((CURSOR+1))] == [[:blank:]] ]]; then
    opp-generic-w \
      -1 opp-skip-blank-backward \
      -2 opp-skip-blank-forward \
      "$@"
  else
    opp-generic-w \
      -1 opp-skip-alpunum-backward \
      -2 opp-skip-alpunum-forward \
      "$@"
  fi
}

def-oppc aW; opp+aW () {
  if [[ $BUFFER[((CURSOR+1))] == [[:space:]] ]]; then
    opp-generic-w \
      -1 opp-skip-blank-backward \
      -2 opp-skip-blank-forward \
      -2 opp-skip-alpunum-forward \
      "$@"
  else
    opp-generic-w \
      -1 opp-skip-alpunum-backward \
      -2 opp-skip-alpunum-forward \
      -2 opp-skip-blank-forward \
      "$@"
  fi
}

opp-generic () {
  local fix1="$1"; shift
  local fun1="$1"; shift
  local fix2="$1"; shift
  local fun2="$1"; shift
  local beg end
  [[ $fun1 != none ]] && zle $fun1; ((beg=$CURSOR $fix1))
  [[ $fun2 != none ]] && zle $fun2; ((end=$CURSOR $fix2))
  "$@" $beg $end
}

opp-generic-pair-scan () {
  local -i  pos="${1}"
  local       a="${2}"
  local       b="${3}"
  local     buf="${4}"
  local     suc="${5}"
  local -i nest="${6}"
  local   place="${7}"

  ((pos==0))           && return -1
  ((pos==(($#buf+1)))) && return -1

  opp-generic-pair-scan-1 () {
    local newnest="$1"
    opp-generic-pair-scan $((pos $suc)) $a $b "$buf" "$suc" $newnest $place
    return $?
  }

  [[ ${buf[$pos, $((pos+$#a-1))]-} == $a ]] && {
    ((nest==0)) && { : ${(P)place::=$pos}; return 0 } ||
    opp-generic-pair-scan-1 $((nest-1)); return $?
  } ||
  [[ ${buf[$pos, $((pos+$#b-1))]-} == $b ]] && {
    opp-generic-pair-scan-1 $((nest+1)); return $?
  }
  opp-generic-pair-scan-1 $nest; return $?
}

def-oppc-pair-1 () {
  local -a xs; : ${(A)xs::=${(s; ;)1}}
  local a=$xs[1]    # '('
  local b=$xs[2]    # ')'
  local c=${xs[3]-} # 'b' (optional)
  eval "$(cat <<EOT
    opp-gps-${(q)a} () {
      local k
      opp-pair-scan \$CURSOR ${(q)a} ${(q)b} \$BUFFER -1 0 k
      ((\$?==0)) && CURSOR=\$k
    }
    zle -N opp-gps-${(q)a}
    opp-gps-${(q)b} () {
      local k
      opp-generic-pair-scan "\$((\$CURSOR+1))" ${(q)b} ${(q)a} \$BUFFER +1 0 k
      ((\$?==0)) && ((CURSOR=\$k - 1))
    }
    zle -N opp-gps-${(q)b}

    def-oppc i${(q)a}; def-oppc i${(q)b}; ${c:+def-oppc i${(q)c}}
    opp+i${(q)a} opp+i${(q)b} ${c:+opp+i${(q)c}} () {
      opp-generic \
        -0 opp-gps-${(q)a} \
        -0 opp-gps-${(q)b} \
        "\$@"
    }
    def-oppc a${(q)a}; def-oppc a${(q)b}; ${c:+def-oppc a${(q)c}}
    opp+a${(q)a} opp+a${(q)b} ${c:+opp+a${(q)c}} () {
      opp-generic \
        -1 opp-gps-${(q)a} \
        +1 opp-gps-${(q)b} \
        "\$@"
    }
EOT
  )"
}

opp-pair-scan () {
  shift
  local -i ret=0
  local a; a="$1"
  [[ "${BUFFER[((CURSOR+1))]-}" ==  "$a" ]] && {
    opp-generic-pair-scan $((CURSOR+1)) "$@"; return $?
  }
  opp-generic-pair-scan $CURSOR "$@"; return $?
}

def-oppc-pair () {
  local x; while read x; do
    [[ -n $x ]] && def-oppc-pair-1 $x
  done <<< "$1"
}

# XXX: 'k' stands for 'bracKet'. (my taste)
def-oppc-pair '
  [ ] k
  < >
  ( ) b
  { } B
'

def-oppc-inbetween-1 () {
  def-oppc-inbetween-2 "$1" "opp+i$1" "opp+a$1" "$2"
}

def-oppc-inbetween-2 () {
  local s="$1"
  local ifun="$2"
  local afun="$3"
  local gsym="$4"
  eval "$(cat <<EOT
    opp-gps-${(q)gsym}-s-ref () { : \${(P)1:=${(q)s}} }
    opp-gps-${(q)gsym}-a () {
      local k
      local s=; opp-gps-${(q)gsym}-s-ref s
      opp-inbetween-scan "\$s" k
      ((\$?==0)) && CURSOR=\$k
    }
    zle -N opp-gps-${(q)gsym}-a
    opp-gps-${(q)gsym}-b () {
      local k
      local s=; opp-gps-${(q)gsym}-s-ref s
      opp-generic-pair-scan "\$((\$CURSOR+1))" \$s \$s \$BUFFER +1 0 k
      ((\$?==0)) && ((CURSOR=\$k - 1))
    }
    zle -N opp-gps-${(q)gsym}-b
    def-oppc i${(q)s}; ${(q)ifun} () {
      opp-generic \
        -0 opp-gps-${(q)gsym}-a \
        -0 opp-gps-${(q)gsym}-b \
        "\$@"
    }
    def-oppc a${(q)s}; ${(q)afun} () {
      opp-generic \
        -1 opp-gps-${(q)gsym}-a \
        +1 opp-gps-${(q)gsym}-b \
        "\$@"
    }
EOT
  )"
}

opp-inbetween-scan () {
  local -i ret=0
  local a="$1"; shift
  local kplace="$1"; shift
  local buf="$BUFFER";
  if [[ "${buf[((CURSOR+1))]-}" == "$a" ]]; then
    () {
      local -i i=0 nest=0
      local c=;
      for ((i=1; i<CURSOR; i++)); do
        ((i+1==CURSOR)) && break
        [[ "${buf[$i,$((i+$#a-1))]-}" == "$a" ]] && {
          ((nest++)); continue
        }
      done
      ((nest & 1))
    }
    ((?==1)) && {
      opp-generic-pair-scan $CURSOR "$a" "$a" "$buf" +1 0 "$kplace"; ((ret=?))
      ((ret==0)) && {
        : ${(P)kplace:=$CURSOR}
        return ret
      }
    }
  fi
  opp-generic-pair-scan $CURSOR "$a" "$a" "$buf" -1 0 "$kplace"; ((ret=?))
  ((ret==0)) || {
    [[ "${buf[((CURSOR+1))]-}" == "$a" ]] && {
      ((CURSOR++))
      opp-generic-pair-scan $CURSOR "$a" "$a" "$buf" +1 0 "$kplace"
      ((ret=?))
    }
  }
  return ret
}

def-oppc-inbetween () {
  local -i i=0
  local s; for s in "$@"; do
    def-oppc-inbetween-1 "$s" "inbetween-$((i++))"
  done
}

def-oppc-inbetween '"' "'" '`'

with-opp () {
  {
    emulate -L zsh
    setopt extended_glob
    zle -N undefined-key opp-undefined-key
    zmodload zsh/zleparameter || {
      echo 'Failed loading zsh/zleparameter module, aborting.'
      return -1
    }
    opp_keybuffer=$KEYS
    "$@[1,-2]" "$opp_keybuffer" "$5"
  } always {
    zle -N undefined-key opp-id # TODO: anything better?
  }
}

opp-recursive-edit-1 () {
  local oppk="${1}"
  local fail="${2}"
  local succ="${3}"
  local   op="${4}"
  local mopp="${5}" # Mimic the OPerator or not.

  local numeric=$NUMERIC
  zle recursive-edit -K opp && {
    ${opps[$KEYS]} opp-k $oppk
    zle $succ
  } || {
    [[ -z "${numeric-}" ]] || { local NUMERIC=$numeric }
    local arg=$opp_keybuffer[(($#op+1)),-1]
    [[ -n $arg ]] && {
      opp-read-motion "$op" "$arg[-1]" "$arg" \
        opp-linewise~ opp-motion "$oppk" "$succ" "$fail" "$mopp"
    }
  }
}

opp-read-motion () {
  local   op="${1}"; shift
  local   cc="${1}"; shift
  local  acc="${1}"; shift
  local succ="${1}"; shift
  local fail="${1}"; shift

  [[ $op  == $acc   ]] && {"$succ" "$op" "$acc"   "$@";return $?} ||
  { opp-read-motion-p "$cc" "$acc" } && {
    local c;read -s -k 1 c
    opp-read-motion "$op" "$c" "$acc$c" "$succ" "$fail" "$@";return $?
  } ||
  [[ $op != "$acc"* ]] && {"$fail" "$op" "$acc"   "$@";return $?} ||
  [[ $cc == ''      ]] && {"$fail" "$op" "$acc"   "$@";return $?} ||
  [[ $op == "$acc"* ]] && {
    local c;read -s -k 1 c
    opp-read-motion "$op" "$c" "$acc$c" "$succ" "$fail" "$@";return $?
  }
}

opp-read-motion-p () {
  local   c="${1}"
  local acc="${2}"
  local -a match mbegin mend
  local -i len=${#acc/*[[:digit:]](#b)(*)/$match}
  ((len==1)) ||\
    # Already read a motion char. This prevents an infinite looping
    # like 'dttt...'.
    return 1
  # TODO: This may not be enough, or may be too much.
  [[ $c == 't' ]] && return 0
  [[ $c == 'T' ]] && return 0
  [[ $c == 'f' ]] && return 0
  [[ $c == 'F' ]] && return 0
  [[ $c == "'" ]] && return 0
  [[ $c == 'g' ]] && return 0
  [[ $c == '[' ]] && return 0
  [[ $c == ']' ]] && return 0
  return 1
}

opp-linewise () {
  zle vi-goto-column -n 0
  zle set-mark-command
  zle end-of-line
  zle "$1"
}

opp-linewise~ () {
  local   _op="${1}"
  local  _arg="${2}"
  local appk="${3}"
  local succ="${4}"
  opp-linewise $oppk
  zle $succ
}

opp-oneshot-region () {
  local fn="$1"
  local c0="$2"
  local c1=$CURSOR
  local c2="$2"
  (($c0 < $c1)) || { local tmp=$c0; c0=$c1; c1=$tmp }
  CURSOR=$c0
  zle set-mark-command
  CURSOR=$c1
  zle $fn
  CURSOR=$c2
}

opp-motion () {
  local   _op="${1}"
  local  arg="${2}"
  local _appk="${3}"
  local _succ="${4}"
  local fail="${5}"
  local mopp="${6}"
  if [[ ${mopp} == t ]]; then
    # Execute the ${fail} function after *THIS* zle widget finished
    # because of the use of a "zle -U" to mimic the operators.
    OPP_ONESHOT_KEY="\033[999~"
    eval "
      opp+oneshot+ () {
        bindkey -M $KEYMAP -r '$OPP_ONESHOT_KEY'
        opp-oneshot-region $fail \"$CURSOR\"
      }; zle -N opp+oneshot+"
    bindkey -M $KEYMAP "$OPP_ONESHOT_KEY" opp+oneshot+
    zle -U "${arg}$OPP_ONESHOT_KEY"
  else
    zle -U "$arg"
    zle $fail
  fi
}

opp-recursive-edit () {
  with-opp opp-recursive-edit-1 "$@"
}; zle -N opp-recursive-edit

opp-k () {
  CURSOR="$2"
  zle set-mark-command
  CURSOR="$3"
  if [[ -n "${keymaps[(r)viopp]-}" ]]; then
    [[ "$1" == (kill-region|*-copy-region) ]] && { ((CURSOR--)) }
  fi
  zle "$1"
}

opp-id () { "$@" }; zle -N opp-id

with-opp-regioned () {
  ((REGION_ACTIVE)) || return
  {
    "$@"
  } always {
    zle set-mark-command -n -1
  }
}

opp-copy-region () {
  with-opp-regioned zle copy-region-as-kill
}; zle -N opp-copy-region

opp-regioned-buffer-each () {
  local i; for i in {$((MARK+1))..$((CURSOR))}; do
    local c=$BUFFER[$i]
    "$@" $i "$c"
  done
}

opp-regioned-buffer-each~ () { with-opp-regioned opp-regioned-buffer-each "$@" }

opp-swap-case-region-0 () {
  local -i i=$1; local c="$2"
  case "$c" in
    ([[:lower:]]) BUFFER[$i]="${(U)c}" ;;
    ([[:upper:]]) BUFFER[$i]="${(L)c}" ;;
  esac
}

opp-swap-case-region () {
  opp-regioned-buffer-each~ opp-swap-case-region-0
}; zle -N opp-swap-case-region

opp-register-zle () {
  eval "$1 () { zle opp-recursive-edit -- $2 $3 $4 ${5:=nil} }; zle -N $1"
}

opp-register-zle opp-vi-change kill-region vi-change vi-insert
opp-register-zle opp-vi-delete kill-region vi-delete opp-id
opp-register-zle opp-vi-yank opp-copy-region vi-yank opp-id

opp-register-zle-operator-mimic () { opp-register-zle "$1" "$2" "$2" "$3" t }

opp-register-zle-operator-mimic opp-vi-tilde opp-swap-case-region opp-id

opp-register-zle-operator-mimic-case () {
  local case="$1" buffexpnflags="$2"
  eval "$(cat <<EOT
    opp-${case}-case-region-0 () {
      BUFFER[\$1]="\${${buffexpnflags}2}"
    }
    opp-${case}-case-region () {
      opp-regioned-buffer-each~ opp-${case}-case-region-0
    }; zle -N opp-${case}-case-region
    opp-register-zle-operator-mimic \
     opp-vi-${case}case opp-${case}-case-region opp-id
EOT
  )"
}
opp-register-zle-operator-mimic-case upper "(U)"
opp-register-zle-operator-mimic-case lower "(L)"

# Entry point.
typeset -gA opp_operators; opp_operators=()
opp () {
  # to implement autoloading easier,
  # all of the operator commands will be dispatched through this func.
  opp1
}
opp1 () { $opp_operators[$KEYS]; }

opp-install () {
  {
    zle -N opp opp
    typeset -gA opp_operators; opp_operators=()
    BK () {
      opp_operators+=("$1" $2)
      bindkey -M vicmd "$1" opp
      { bindkey -M afu-vicmd "$1" opp } > /dev/null 2>&1
    }
    BK "c" opp-vi-change
    BK "d" opp-vi-delete
    BK "y" opp-vi-yank
    BK "g~" opp-vi-tilde
    BK "gU" opp-vi-uppercase
    BK "gu" opp-vi-lowercase
    { "$@" }
  } always {
    unfunction BK
  }
}
opp-install

# zcompiling code.

opp-clean () {
  local d=${1:-~/.zsh/zfunc}
  rm -f ${d}/{opp,opp.zwc*(N)}
  rm -f ${d}/{opp-install,opp-install.zwc*(N)}
}

opp-install-installer () {
  local match mbegin mend
  eval ${${${"$(<=(cat <<"EOT"
    opp-install-after-load () {
      typeset -g opp_keybuffer
      bindkey -N opp
      { $opp_installer_codes }
      { $body }
      opp_loaded_p=t
    }
    opp-install-maybe () {
      [[ -z ${opp_loaded_p-} ]] || return
      opp-install-after-load
    }
    # redefine opp
    opp () {
      opp-install-maybe
      opp1
    }
EOT
  ))"}/\$body/
  $(print -l \
    "# opp's zle widget" \
    ${${(M)${(@f)"$(zle -l)"}:#(opp*)}/(#b)(*)/zle -N ${(qqq)match}} \
    "# bindkeys on the opp keymap" \
    ${(q@f)"$(bindkey -M opp -L)"})
  }/\$opp_installer_codes/$(opp-installer-expand)}
}

opp_installer_codes=()

opp-installer-add () { opp_installer_codes+=($1) }

opp-installer-expand () {
  local c; for c in $opp_installer_codes; do
    "$c"
  done
}

opp-installer-install-opps () {
  echo ${"$(typeset -p opps)"/typeset -A/typeset -gA}
}; opp-installer-add opp-installer-install-opps

opp-zcompile () {
  #local opp_zcompiling_p=t
  local s=${1:?Please specify the source file itself.}
  local d=${2:?Please specify the directory for the zcompiled file.}
  emulate -L zsh
  setopt extended_glob no_shwordsplit

  echo "** zcompiling opp in ${d} for a little faster startups..."
  [[ -n ${OPP_PARANOID-} ]] && {
    echo "* reloading ${s}"
    source ${s} >/dev/null 2>&1
  }
  echo "mkdir -p ${d}" | sh -x
  opp-clean ${d}
  opp-install-installer

  local g=${d}/opp
  echo "* writing code ${g}"
  {
    local -a fs
    : ${(A)fs::=${(Mk)functions:#(*opp*)}}
    echo "#!zsh"
    echo "# NOTE: Generated from opp.zsh ($0). Please DO NOT EDIT."; echo
    local -a es; es=('def-*' '*register*' 'opp-installer-*' \
      opp-clean opp-install-installer opp-zcompile opp-install opp+oneshot+)
    echo "$(functions ${fs:#${~${(j:|:)es}}})"
    echo "\nopp"
  }>! ${g}

  local gi=${d}/opp-install
  echo "* writing code ${gi}"
  {
    echo "#!zsh"
    echo "# NOTE: Generated from opp.zsh ($0). Please DO NOT EDIT."; echo
    echo "$(functions opp-install)"
  }>! ${gi}

  [[ -z ${OPP_NOZCOMPILE-} ]] || return
  autoload -U zrecompile && {
    Z () { echo -n "* "; zrecompile -p -R "$1" }; Z ${g} && Z ${gi}
  } && {
    zmodload zsh/datetime
    touch --date="$(strftime "%F %T" $((EPOCHSECONDS + 10)))" {${g},${gi}}.zwc
    [[ -z ${OPP_ZCOMPILE_NOKEEP-} ]] || { echo "rm -f ${g} ${gi}" | sh -x }
    echo "** All done."
    echo "** Please update your .zshrc to load the zcompiled file like this,"
    cat <<EOT
-- >8 --
## opp.zsh stuff.
# source ${s/$HOME/~}
autoload opp
{ . ${gi/$HOME/~}; opp-install; }
-- 8< --
EOT
  }
}

# (os=(${(ok)opp_operators}); os=(${(j:, :)os[1,-2]} and $os[-1]); echo $os)
