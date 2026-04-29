#!/bin/bash

BEFORE_PATTERN=3

script_name=$(basename $0)
context=5
show_coincidences=0
show_unique_coincidences=0
show_json=0

usage="usage: $script_name -f file [[-p <pattern>] ...] [-c <context>] [-s|-u|-j]"

patterns=()

while getopts 'f:p:c:suj' OPTION
do
        case "${OPTION}" in
                s)
                        show_coincidences=1
                        ;;
                u)
                        show_unique_coincidences=1
                        ;;
                j)
                        show_json=1
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

if [ $patterns_len -gt 1 ] && [ $show_unique_coincidences -eq 1 ]
then
        echo "ERROR: Can't currently use multiple patterns with -u flag"
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

if [ $show_unique_coincidences -eq 1 ]
then
        offset=$(echo "$coincidences" | head -n 1 | \
                awk 'match($0, /^.*:/) {print RLENGTH-1}')
        echo "$coincidences" | uniq -c -f $offset 2>/dev/null
        exit 0
fi

function gadget2json()
{
        gadget="$1"
        clean_gadget=$(echo "$gadget" | \
                        awk "NR > $BEFORE_PATTERN {print; if (/ret$/) exit}")

        IFSBK=$IFS
        IFS=$'\n'
        for line in $clean_gadget
        do
                echo -e '\t\t{'

                # That weird regular expression repeated in both addr and instruction
                # is used to remove ANSI colors
                addr=$(echo "$line" | sed "s/:.*//g" | sed -E "s/\x1B\[[0-9;]*[mGK]//g" \
                       | sed "s/^[ ]*//g")
                instruction=$(echo "$line" | sed -E "s/.*:[\t ]*([0-9a-f][0-9a-f][ ])+[\t ]*//g" \
                       | sed -E "s/[ ]+/ /g" | sed -E "s/\x1B\[[0-9;]*[mGK]//g")

                echo -e "\t\t\t\"offset\": \"$addr\",\n\t\t\t\"instruction\": \"$instruction\""

                if [ $(echo "$instruction" | grep "ret") ]
                then
                        echo -e '\t\t}'
                else
                        echo -e '\t\t},'
                fi
        done
        IFS=$IFSBK
}

function check_gadget_validity()
{
        gadget="$1"

        match="yes"
        i=1
        while [ $i -lt $patterns_len ]
        do
                pattern=${patterns[i]}
                expected_line=$(echo "$gadget" | awk "NR == $(($BEFORE_PATTERN + $i + 1))")
                match=$(echo "$expected_line" | grep -E "$pattern")
                if [ -z "$match" ]
                then
                        break
                fi

                ((i++))
        done

        if [ -n "$match" ]
        then
                echo 1
        else
                echo 0
        fi
}

if [ $show_json -eq 1 ]
then
        echo "{"
        echo -e "\t\"file\": \"$(basename $file)\","
        echo -e "\t\"context_window\": $context,"
        echo -e "\t\"patterns\": ["

        echo -e "\t\t\"${patterns[0]}\""
        i=1
        while [ $i -lt $patterns_len ]
        do
                echo -e "\t\t,\"${patterns[$i]}\""
                ((i++))
        done
        echo -e "\t],"

        echo -e "\t\"gadgets\": ["
fi

first_gadget=1
num_gadgets=0
for addr in $addresses
do
        gadget=$(grep --color=always -B $BEFORE_PATTERN -A $context "^[ ]*$addr" $file)

        valid_gadget=$(check_gadget_validity "$gadget")

        if [ $valid_gadget -eq 1 ]
        then
                ((num_gadgets++))
                if [ $show_coincidences -eq 1 ]
                then
                        echo "$gadget" | \
                                awk "NR > $BEFORE_PATTERN && NR <= $(($patterns_len + $BEFORE_PATTERN))"
                        echo -e "--------------------------------------------------------------------------------\n"
                elif [ $show_json -eq 1 ]
                then
                        if [ $first_gadget -eq 1 ]
                        then
                                first_gadget=0
                        else
                                echo ','
                        fi

                        echo -e "\t\t["
                        gadget2json "$gadget"
                        echo -en "\t\t]"
                else
                        ret_line_num=$(echo "$gadget" | \
                                        awk "NR > $BEFORE_PATTERN && /ret$/{print NR; exit}")
                        echo "$gadget" | awk "NR >= 1 && NR <= $ret_line_num"
                        echo -e "--------------------------------------------------------------------------------\n"
                fi
        fi

        ((i++))
done

if [ $show_json -eq 1 ]
then
        echo -e "\n\t],"
        echo -e "\t\"num_gadgets\": $num_gadgets"
        echo -e "}"
fi
