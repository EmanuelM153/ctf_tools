import sys
import getopt
import os
import json

base_address = 0xffffffff
code_addresses = []
usage = f'{os.path.basename(sys.argv[0])} [-b <address>] ((-a <file address>) ...) <4addr.json file> <desired address>'

str_to_hex = lambda s: hex(int(s, 16))

try:
    optlist, args = getopt.getopt(sys.argv[1:], 'b:a:')
except getopt.GetoptError:
    print(usage)
    exit(1)

if len(args) != 2:
    print(usage)
    exit(1)

file = args[0]
desired_address=str_to_hex(args[1])

for opt_pair in optlist:
    opt = opt_pair[0]
    arg = opt_pair[1]
    match opt:
        case '-b':
            base_address = str_to_hex(arg)
        case '-a':
            code_addresses.append(str_to_hex(arg))



with open(file, 'r') as f:
    gadgets_queries = json.load(f)

if len(gadgets_queries) != len(code_addresses):
    print(f"ERROR: Must supply all code addresses for each gadget query")
    exit(1)
