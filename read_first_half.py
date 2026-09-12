with open('templates/infrastructure/postgres.yaml', 'r') as f:
    for i, line in enumerate(f):
        if i >= 160:
            break
        print(f"{i+1:4d}: {line}", end='')
