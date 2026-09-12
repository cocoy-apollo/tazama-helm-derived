import sys

INPUT_FILE = 'templates/infrastructure/postgres.yaml'

with open(INPUT_FILE, 'r', encoding='utf-8') as f:
    content = f.read()

checks = [
    ('postgres-init-script' in content, 'postgres-init-script'),
    ('POSTGRES_DB' not in content, 'POSTGRES_DB removed'),
    ('PGDATA' in content, 'PGDATA added'),
    ('postgres-data' in content, 'postgres-data PVC name'),
    ('/var/lib/postgresql/data/pgdata' in content, 'PGDATA path'),
    ('mountPath: /var/lib/postgresql' in content, 'Mount path'),
    ('init-volume' in content, 'init-volume name'),
    ('longhorn-single' in content, 'storageClassName'),
    ('postgres-run' in content, 'emptyDir postgres-run'),
    ('postgres-tmp' in content, 'emptyDir postgres-tmp'),
    ('subPath: 00-CREATE.sql' in content, 'subPath'),
]

all_pass = True
for check, desc in checks:
    status = 'OK' if check else 'FAIL'
    if not check:
        all_pass = False
    print(f'  [{status}] {desc}')

print(f'\nAll checks: {"PASS" if all_pass else "FAIL"}')