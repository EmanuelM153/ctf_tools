#!/bin/bash

script_name=$(basename $0)
context=5
show_coincidences=0

while getopts 'f:p:c:s' OPTION
do
        case "${OPTION}" in
                s)
                        show_coincidences=1
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
                        echo "usage: $script_name -f file [-p pattern] [-c context]"
                        exit 1
                        ;;
        esac
done

if [ -z $file ]
then
        echo "usage: $script_name -f file [-p pattern] [-c context]"
        exit 1
fi

if [ -n "$pattern" ]
then
        coincidences=$(grep -B $context -E "ret$" $file | grep -E "$pattern")
        addresses=$(echo "$coincidences" | sed "s/:.*//g")

        if [ $show_coincidences -eq 0 ]
        then
                for addr in $addresses
                do
                        grep --color=always -B 3 -A $context "^[ ]*$addr" $file
                done
        else
                echo "$coincidences"
        fi
else
        grep -B $context -E "ret$" $file
fi
