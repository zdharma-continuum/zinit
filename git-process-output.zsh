#!/usr/bin/env zsh

emulate -LR zsh -o typesetsilent -o extendedglob -o warncreateglobal

# Alpine Linux doesn't have tput; FreeBSD and Dragonfly BSD have termcap
if whence tput &> /dev/null; then
  if [[ $OSTYPE == freebsd* ]] || [[ $OSTYPE == dragonfly* ]]; then
    # termcap commands
    ZPLG_CNORM='tput ve'
    ZPLG_CIVIS='tput vi'
  else
    # terminfo is more common
    ZPLG_CNORM='tput cnorm'
    ZPLG_CIVIS='tput civis'
  fi
fi

if (( $+ZPLG_CNORM )); then
  trap $ZPLG_CNORM EXIT
  trap $ZPLG_CNORM INT
  trap $ZPLG_CNORM TERM
fi

local first=1

# Code by leoj3n
timeline() {
  local sp='▚▞'; sp="${sp:$2%2:1}"
  local bar="$(print -f "%-$2s▓%$(($3-$2))s" "${sp}" "${sp}")"
  print -f "%s %s" "${bar// /░}" ""
}

# $1 - n. of objects
# $2 - packed objects
# $3 - total objects
# $4 - receiving percentage
# $5 - resolving percentage
print_my_line() {
    print -nr -- "OBJ: $1, PACKED: $2/$3${${4:#...}:+, RECEIV.: $4%}${${5:#...}:+, RESOLV.: $5%}  "
    print -n $'\015'
}

print_my_line_compress() {
    print -nr -- "OBJ: $1, PACKED: $2/$3, COMPR.: $4%${${5:#...}:+, RECEIV.: $5%}${${6:#...}:+, RESOL.: $6%}  "
    print -n $'\015'
}

integer have_1_counting=0 have_2_total=0 have_3_receiving=0 have_4_deltas=0 have_5_compress=0
integer counting_1=0 total_2=0 total_packed_2=0 receiving_3=0 deltas_4=0 compress_5=0
integer loop_count=0

IFS=''

(( $+ZPLG_CIVIS )) && eval $ZPLG_CIVIS

{ command perl -pe 'BEGIN { $|++; $/ = \1 }; tr/\r/\n/' || \
    gstdbuf -o0 gtr '\r' '\n' || \
    cat } |& \
while read -r line; do
    (( ++ loop_count ))
    if [[ "$line" = "Cloning into"* ]]; then
        print; print $line
        continue
    elif [[ "$line" = (#i)*user*name* || "$line" = (#i)*password* ]]; then
        print; print $line
        continue
    elif [[ "$line" = remote:*~*(Counting|Total|Compressing|Enumerating)* || "$line" = fatal:* ]]; then
        print $line
        continue
    fi
    if [[ "$line" = (#b)"remote: Counting objects:"[\ ]#([0-9]##)(*) ]]; then
        have_1_counting=1
        counting_1="${match[1]}"
    fi
    if [[ "$line" = (#b)"remote: Enumerating objects:"[\ ]#([0-9]##)(*) ]]; then
        have_1_counting=1
        counting_1="${match[1]}"
    fi
    if [[ "$line" = (#b)*"remote: Total"[\ ]#([0-9]##)*"pack-reused"[\ ]#([0-9]##)* ]]; then
        have_2_total=1
        total_2="${match[1]}" total_packed_2="${match[2]}"
    fi
    if [[ "$line" = (#b)"Receiving objects:"[\ ]#([0-9]##)%* ]]; then
        have_3_receiving=1
        receiving_3="${match[1]}"
    fi
    if [[ "$line" = (#b)"Resolving deltas:"[\ ]#([0-9]##)%* ]]; then
        have_4_deltas=1
        deltas_4="${match[1]}"
    fi
    if [[ "$line" = (#b)"remote: Compressing objects:"[\ ]#([0-9]##)"%"(*) ]]; then
        have_5_compress=1
        compress_5="${match[1]}"
    fi

    if (( loop_count >= 2 )); then
        integer pr
        (( pr = have_4_deltas ? deltas_4 / 10 : (
                have_3_receiving ? receiving_3 / 10 : (
                have_5_compress ? compress_5 / 10 : ( ( ( loop_count - 1 ) / 14 ) % 10 ) + 1 ) ) ))
	timeline "" $pr 11
        if (( have_5_compress )); then
            print_my_line_compress "${${${(M)have_1_counting:#1}:+$counting_1}:-...}" \
                                   "${${${(M)have_2_total:#1}:+$total_packed_2}:-0}" \
                                   "${${${(M)have_2_total:#1}:+$total_2}:-0}" \
                                   "${${${(M)have_5_compress:#1}:+$compress_5}:-...}" \
                                   "${${${(M)have_3_receiving:#1}:+$receiving_3}:-...}" \
                                   "${${${(M)have_4_deltas:#1}:+$deltas_4}:-...}"
        else
            print_my_line "${${${(M)have_1_counting:#1}:+$counting_1}:-...}" \
                          "${${${(M)have_2_total:#1}:+$total_packed_2}:-0}" \
                          "${${${(M)have_2_total:#1}:+$total_2}:-0}" \
                          "${${${(M)have_3_receiving:#1}:+$receiving_3}:-...}" \
                          "${${${(M)have_4_deltas:#1}:+$deltas_4}:-...}"
        fi
    fi
done

print

(( $+ZPLG_CNORM )) && eval $ZPLG_CNORM

unset ZPLG_CNORM ZPLG_CIVIS
