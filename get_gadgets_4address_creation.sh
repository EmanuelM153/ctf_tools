#!/bin/bash

OUTPUT_FILE="4addr.json"
script_name=$(basename $0)
usage="$script_name ((-f <file>) ...)"

files=()
while getopts 'f:' OPTION
do
        case "${OPTION}" in
                f)
                        files+=("$OPTARG")
                        ;;
                *)
                        echo $usage
                        exit 1
                        ;;
        esac
done

echo "[" > $OUTPUT_FILE

i=0
while [ $i -lt ${#files[@]} ]
do
        file=${files[$i]}

        if [ $i -ne 0 ]
        then
                echo -n "," >> $OUTPUT_FILE
        fi

        bash ./find_possible_gadgets.sh -f "$file" -p "lea.*-.*%eax.,%e[bacd]x" -p "mov[ ]*%e[bacd]x,%eax|ret$" -j -c 2 >> $OUTPUT_FILE
        ((i++))
done

echo "]" >> $OUTPUT_FILE
