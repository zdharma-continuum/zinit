#!/usr/bin/env zsh

emulate -LR zsh

setopt typesetsilent extendedglob warncreateglobal

{ typeset -g COLS="$(tput cols)" } 2>/dev/null
if (( COLS < 10 )) {
    COLS=40
}
# Credit to molovo/revolver for the ideas
typeset -ga progress_frames
progress_frames=(
  '0.2 ▹▹▹▹▹ ▸▹▹▹▹ ▹▸▹▹▹ ▹▹▸▹▹ ▹▹▹▸▹ ▹▹▹▹▸'
  '0.2 ▁ ▃ ▄ ▅ ▆ ▇ ▆ ▅ ▄ ▃'
  '0.2 ▏ ▎ ▍ ▌ ▋ ▊ ▉ ▊ ▋ ▌ ▍ ▎'
  '0.2 ▖ ▘ ▝ ▗'
  '0.2 ◢ ◣ ◤ ◥'
  '0.2 ▌ ▀ ▐ ▄'
  '0.2 ✶ ✸ ✹ ✺ ✹ ✷'
)

integer -g progress_style=$(( RANDOM % 7 + 1 )) cur_frame=1
typeset -F SECONDS=0 last_time=0

# Alpine Linux doesn't have tput; FreeBSD and Dragonfly BSD have termcap
if whence tput &> /dev/null; then
  if [[ $OSTYPE == freebsd* ]] || [[ $OSTYPE == dragonfly* ]]; then
    # termcap commands
    ZINIT_CNORM='tput ve'
    ZINIT_CIVIS='tput vi'
  else
    # terminfo is more common
    ZINIT_CNORM='tput cnorm'
    ZINIT_CIVIS='tput civis'
  fi
fi

if (( $+ZINIT_CNORM )); then
  trap $ZINIT_CNORM EXIT
  trap $ZINIT_CNORM INT
  trap $ZINIT_CNORM TERM
fi

local first=1

# Code by leoj3n
timeline() {
  local sp='▚▞'; sp="${sp:$2%2:1}"
  # Maximal width is 24 characters
  local bar="$(print -f "%.$2s█%0$(($3-$2-1))s" "████████████████████████" "")"

  local -a frames_splitted
  frames_splitted=( ${(@zQ)progress_frames[progress_style]} )
  if (( SECONDS - last_time >= frames_splitted[1] )) {
      (( cur_frame = (cur_frame+1) % (${#frames_splitted}+1-1) ))
      (( cur_frame = cur_frame ? cur_frame : 1 ))
      last_time=$SECONDS
  }

  print -nr -- ${frames_splitted[cur_frame+1]}" "
  print -nPr "%F{183}"
  print -f "%s %s" "${bar// /░}" ""
  print -nPr "%f"
}

# $1 - n. of objects
# $2 - packed objects
# $3 - total objects
# $4 - receiving percentage
# $5 - resolving percentage
print_my_line() {
    local col="%F{155}" col3="%F{155}" col4="%F{155}" col5="%F{155}"
    [[ -n "${4#...}" && -z "${5#...}" ]] && col3="%F{81}"
    [[ -n "${5#...}" ]] && col4="%F{81}"
    if (( COLS >= 70 )) {
        print -Pnr -- "${col}OBJ%f: $1, ${col}PACK%f: $2/$3${${4:#...}:+, ${col3}REC%f: $4%}${${5:#...}:+, ${col4}RES%f: $5%}  "
    } elif (( COLS >= 60 )) {
        print -Pnr -- "${col}OBJ%f: $1, ${${4:#...}:+, ${col3}REC%f: $4%}${${5:#...}:+, ${col4}RES%f: $5%}  "
    } else {
        print -Pnr -- "${${4:#...}:+, ${col3}REC%f: $4%}${${5:#...}:+, ${col4}RES%f: $5%}  "
    }
    print -n $'\015'
}

print_my_line_compress() {
    local col="%F{155}" col3="%F{155}" col4="%F{155}" col5="%F{155}"
    [[ -n "${4#...}" && -z "${5#...}" && -z "${6#...}" ]] && col3="%F{81}"
    [[ -n "${5#...}" && -z "${6#...}" ]] && col4="%F{81}"
    [[ -n "${6#...}" ]] && col5="%F{81}"
    if (( COLS >= 80 )) {
        print -Pnr -- "${col}OBJ%f: $1, ${col}PACK%f: $2/$3, ${col3}COMPR%f: $4%%${${5:#...}:+, ${col4}REC%f: $5%%}${${6:#...}:+, ${col5}RES%f: $6%%}  "
    } elif (( COLS >= 65 )) {
        print -Pnr -- "${col}OBJ%f: $1, ${col3}COMPR%f: $4%%${${5:#...}:+, ${col4}REC%f: $5%%}${${6:#...}:+, ${col5}RES%f: $6%%}  "
    } else {
        print -Pnr -- "${col}OBJ%f: $1, ${${5:#...}:+, ${col4}REC%f: $5%%}${${6:#...}:+, ${col5}RES%f: $6%%}  "
    }
    print -n $'\015'
}

integer have_1_counting=0 have_2_total=0 have_3_receiving=0 have_4_deltas=0 have_5_compress=0
integer counting_1=0 total_2=0 total_packed_2=0 receiving_3=0 deltas_4=0 compress_5=0
integer loop_count=0

IFS=''

[[ $+ZINIT_CIVIS == 1 && -n $TERM ]] && eval $ZINIT_CIVIS

if [[ -n $TERM ]] {

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
    if [[ "$line" = (#b)"Receiving objects:"[\ ]#([0-9]##)%([[:blank:]]#\(([0-9]##)/([0-9]##)\)|)* ]]; then
        have_3_receiving=1
        receiving_3="${match[1]}"
        [[ -n "${match[2]}" ]] && {
            have_2_total=1
            total_packed_2="${match[3]}" total_2="${match[4]}"
        }
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

} else {
    grep fatal:
}

print

[[ $+ZINIT_CNORM == 1 && -n $TERM ]] && eval $ZINIT_CNORM

unset ZINIT_CNORM ZINIT_CIVIS
