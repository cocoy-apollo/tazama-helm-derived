import sys
path = sys.argv[1]
with open(path, 'r') as f:
    for i, line in enumerate(f):
        if i < 160:
            print(f"{i+1:4d}: {line}", end='')
