#!/usr/bin/env zsh

local first=1

# $1 - n. of objects
# $2 - packed objects
# $3 - total objects
# $4 - receiving percentage
# $5 - resolving percentage
print_my_line() {
    (( first == 0 )) && print -n $'\015'
    first=0
    print -nr -- "OBJ: $1, PACKED: $2/$3, RECEIVING: $4%, RESOLVING: $5%           "
}

integer have_1_counting=0 have_2_total=0 have_3_receiving=0 have_4_deltas=0
integer counting_1=0 total_2=0 total_packed_2=0 receiving_3=0 deltas_4=0

IFS=''
local delim=$'\n'

while read -rd$delim line; do
    if [[ "$line" = "Cloning into"* ]]; then
        print $line
    fi
    if [[ "$line" = (#b)"remote: Counting objects:"[\ ]#([0-9]##)(*) ]]; then
        have_1_counting=1
        counting_1="${match[1]}"
        delim=$'\015'
    fi
    if [[ "$line" = (#b)"remote: Total"[\ ]#([0-9]##)*"pack-reused"[\ ]#([0-9]##)* ]]; then
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

    print_my_line "${${${(M)have_1_counting:#1}:+$counting_1}:-...}" \
                  "${${${(M)have_2_total:#1}:+$total_2}:-...}" \
                  "${${${(M)have_2_total:#1}:+$total_packed_2}:-...}" \
                  "${${${(M)have_3_receiving:#1}:+$receiving_3}:-...}" \
                  "${${${(M)have_4_deltas:#1}:+$deltas_4}:-...}"
done

print
