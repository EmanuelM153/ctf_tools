#!/bin/bash

nasm -f bin $1 -o .result
xxd -p .result | tr -d '\n'
rm .result
