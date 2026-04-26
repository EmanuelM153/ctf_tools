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

pattern=${patterns[0]}
coincidences=$(grep -B $context -E "ret$" $file | grep -E "$pattern")
addresses=$(echo "$coincidences" | sed "s/:.*//g")

if [ $show_coincidences -eq 0 ] && [ $show_unique_coincidences -eq 0 ]
then
        for addr in $addresses
        do
                gadget=$(grep --color=always -B $BEFORE_PATTERN -A $context "^[ ]*$addr" $file)

                matches_next="yes"
                i=1
                while [ $i -lt $patterns_len ]
                do
                        pattern=${patterns[i]}
                        expected_line=$(echo "$gadget" | awk "NR == $(($BEFORE_PATTERN + $i + 1))")
                        matches_next=$(echo "$expected_line" | grep -E "$pattern")
                        if [ -z "$matches_next" ]
                        then
                                break
                        fi

                        ((i++))
                done

                if [ -n "$matches_next" ]
                then
                        ret_line_num=$(echo "$gadget" | awk 'NR > 3 && /ret$/{print NR; exit}')
                        echo "$gadget" | awk "NR >= 1 && NR <= ${ret_line_num}"
                        echo -e "--------------------------------------------------------------------------------\n"
                fi
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
