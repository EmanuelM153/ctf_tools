#!/bin/bash

BEFORE_PATTERN=3

script_name=$(basename $0)
context=5
show_coincidences=0
show_unique_coincidences=0

usage="usage: $script_name -f file [[-p <pattern>] ...] [-c <context>] [-s|-u]"

patterns=()

while getopts 'f:p:c:su' OPTION
do
        case "${OPTION}" in
                s)
                        show_coincidences=1
                        ;;
                u)
                        show_unique_coincidences=1
                        ;;
                f)
                        file=$OPTARG
                        ;;
                p)
                        patterns+=("$OPTARG")
                        ;;
                c)
                        context=$OPTARG
                        ;;
                *)
                        echo $usage
                        exit 1
                        ;;
        esac
done


patterns_len=${#patterns[@]}

if [ $patterns_len -gt 1 ] && ([ $show_coincidences -eq 1 ] || [ $show_unique_coincidences -eq 1 ])
then
        echo "ERROR: Can't currently use multiple patterns with -s or -u"
        exit 1
fi

if [ $patterns_len -gt $context ]
then
        echo "ERROR: The number of patterns must be less than or equal to the context window"
        exit 1
fi

if [ -z $file ]
then
        echo $usage
        exit 1
fi

if [ ${#patterns[@]} -eq 0 ]
then
        grep --color=always -B $context -E "ret$" $file
        exit 0
fi

i=0

pattern=${patterns[$i]}
coincidences=$(grep -B $context -E "ret$" $file | grep -E "$pattern")
addresses=$(echo "$coincidences" | sed "s/:.*//g")

while [ $i -lt $(($patterns_len - 1)) ]
do
        ((i++))

        pattern=${patterns[$i]}

        coincidences=""
        for base_addr in $addresses
        do
                next=$(grep -A 1 "^[ ]*$base_addr" $file)
                coincidence=$(echo "$next" | grep -E "$pattern")
                if [ -n "$coincidence" ]
                then
                        addr=$(echo "$coincidence" | sed "s/:.*//g")
                        coincidences=$(echo -e "$coincidences\n$addr")
                fi
        done

        addresses=$(echo "$coincidences" | sed "s/:.*//g")
done

if [ $show_coincidences -eq 0 ] && [ $show_unique_coincidences -eq 0 ]
then
        before_num=$(($patterns_len - 1 + $BEFORE_PATTERN))
        after_num=$(($context - $patterns_len + 1))
        for addr in $addresses
        do
                gadget=$(grep -B $before_num -A $after_num "^[ ]*$addr" $file | \
                                grep --color=always -E "${patterns[0]}|$")
                ret_line_num=$(echo "$gadget" | awk 'NR > 3 && /ret$/{print NR; exit}')

                echo "$gadget" | awk "NR >= 1 && NR <= ${ret_line_num}"
                echo -e "--------------------------------------------------------------------------------\n"
        done
else
        if [ $show_unique_coincidences -eq 0 ]
        then
                echo "$coincidences"
        elif [ $show_coincidences -eq 0 ]
        then
                offset=$(echo "$coincidences" | head -n 1 | \
                        awk 'match($0, /^.*:/) {print RLENGTH-1}')
                echo "$coincidences" | uniq -c -f $offset
        else
                echo $usage
                exit 1
        fi
fi
