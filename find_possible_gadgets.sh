#!/bin/bash

script_name=$(basename $0)
context=5
show_coincidences=0
show_unique_coincidences=0

usage="usage: $script_name -f file [-p pattern] [-c context] [-s|-u]"

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
                        pattern=$OPTARG
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

if [ -z $file ]
then
        echo $usage
        exit 1
fi

if [ -n "$pattern" ]
then
        coincidences=$(grep -B $context -E "ret$" $file | grep -E "$pattern")
        addresses=$(echo "$coincidences" | sed "s/:.*//g")

        if [ $show_coincidences -eq 0 ] && [ $show_unique_coincidences -eq 0 ]
        then
                for addr in $addresses
                do
                        grep --color=always -B 3 -A $context "^[ ]*$addr" $file
                done
        else
                if [ $show_unique_coincidences -eq 0 ]
                then
                        echo "$coincidences"
                elif [ $show_coincidences -eq 0 ]
                then
                        offset=$(echo "$coincidences" | head -n 1 | awk 'match($0, /^.*:/) {print RLENGTH-1}')
                        echo "$coincidences" | uniq -c -f $offset
                else
                        echo $usage
                        exit 1
                fi
        fi
else
        grep -B $context -E "ret$" $file
fi
