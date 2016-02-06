# textobj-between code for opp.zsh.

# Author Takeshi Banse <takebi@laafc.net>
# Licence: Public Domain

# Thank you very much, thinca and tarao!
#
# http://d.hatena.ne.jp/thinca/20100614/1276448745
# http://d.hatena.ne.jp/tarao/20100715/1279185753

def-oppc-inbetween-1 f tb

with-opp-tb-read () {
  local OPP_TB_READ_CHAR=;
  local c; read -s -k 1 c
  [[ "$c" == [[:print:]] ]] || return
  OPP_TB_READ_CHAR="$c"
  "$@"
}

# XXX: redefined!
opp-gps-tb-s-ref () { : ${(P)1:=$OPP_TB_READ_CHAR} }
opp+if () {
  with-opp-tb-read \
    opp-generic \
      -0 opp-gps-tb-a \
      -0 opp-gps-tb-b \
      "$@"
}
opp+af () {
  with-opp-tb-read \
    opp-generic \
      -1 opp-gps-tb-a \
      +1 opp-gps-tb-b \
      "$@"
}
