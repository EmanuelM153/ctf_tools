import sys

hex_num = sys.argv[1].replace("0x", '')

print('echo -ne "', end='')
for i in range(0, len(hex_num), 2):
    print(f'\\x{hex_num[i:i+2]}', end='')

print('"')

print('echo -ne "', end='')
for i in range(len(hex_num), 0, -2):
    print(f'\\x{hex_num[i-2:i]}', end='')

print('"')
