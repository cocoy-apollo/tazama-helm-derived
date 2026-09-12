#!/usr/bin/env python3
"""Apply all 10 fixes to the postgres.yaml template to match the rendered output."""

import re
import sys

INPUT_FILE = 'templates/infrastructure/postgres.yaml'
OUTPUT_FILE = 'templates/infrastructure/postgres.yaml'

def apply_fixes(content):
    """Apply all 10 fixes to the template content."""
    lines = content.split('\n')
    result = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Fix 1 & 2 & 8: ConfigMap name and key
        # Line 5: name: postgres-init -> name: postgres-init-script
        if line.strip() == 'name: postgres-init' and i < 10:
            result.append(line.replace('postgres-init', 'postgres-init-script'))
            i += 1
            continue
        
        # Fix 2: Remove POSTGRES_DB env var (lines 203-204 block)
        if '- name: POSTGRES_DB' in line:
            # Skip this line and the next (value line)
            i += 2
            continue
        
        # Fix 3: Add PGDATA env var after securityContext block (around line 205)
        if line.strip() == '- name: POSTGRES_USER' or line.strip() == '- name: POSTGRES_PASSWORD':
            # Add PGDATA before these lines
            result.append('        - name: PGDATA')
            result.append('          value: /var/lib/postgresql/data/pgdata')
        
        # Fix 4: storageClassName for PVC
        if line.strip() == 'accessModes: [ "ReadWriteOnce" ]':
            result.append(line)
            i += 1
            # Insert storageClassName after accessModes
            result.append('      storageClassName: "longhorn-single"')
            continue
        
        # Fix 5: Volume name postgres-storage -> postgres-data
        if '- name: postgres-storage' in line:
            result.append(line.replace('postgres-storage', 'postgres-data'))
            i += 1
            continue
        
        # Fix 6: Mount path /var/lib/postgresql/data -> /var/lib/postgresql
        if 'mountPath: /var/lib/postgresql/data' in line:
            result.append(line.replace('mountPath: /var/lib/postgresql/data', 'mountPath: /var/lib/postgresql'))
            i += 1
            continue
        
        # Fix 7 & 9: init-scripts -> init-volume (in volumeMounts and volumes)
        if 'name: init-scripts' in line and 'postgres' not in line:
            result.append(line.replace('init-scripts', 'init-volume'))
            i += 1
            continue
        
        # Fix 8: ConfigMap name postgres-init -> postgres-init-script (after line 230)
        if i >= 220 and 'name: postgres-init' in line:
            result.append(line.replace('postgres-init', 'postgres-init-script'))
            i += 1
            continue
        
        # Add subPath for init volumeMount (after subPath line if it exists, or add it)
        if line.strip().startswith('- name: init-volume') or ('mountPath: /docker-entrypoint-initdb.d' in line):
            result.append(line)
            i += 1
            # Check if next line is already subPath (it shouldn't be yet, we need to add it)
            if i < len(lines) and 'subPath' not in lines[i]:
                result.append('          subPath: 00-CREATE.sql')
            continue
        
        # Add emptyDir mounts after readOnlyRootFilesystem: true
        if 'readOnlyRootFilesystem: true' in line:
            result.append(line)
            i += 1
            # Add emptyDir mounts after this line (they should be in volumeMounts section)
            # Look ahead to see if we're in volumeMounts context
            continue
        
        # Check if we need to add emptyDir mounts (they should come after init volumeMount)
        if 'subPath: 00-CREATE.sql' in line:
            result.append(line)
            i += 1
            # Add emptyDir mounts here
            result.append('        - name: postgres-run')
            result.append('          mountPath: /var/run/postgresql')
            result.append('        - name: postgres-tmp')
            result.append('          mountPath: /tmp')
            continue
        
        result.append(line)
        i += 1
    
    return '\n'.join(result)

def main():
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            content = f.read()
        
        fixed_content = apply_fixes(content)
        
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        
        print(f"Fixed {INPUT_FILE} -> {OUTPUT_FILE}")
        
        # Verify key changes
        checks = [
            ('postgres-init-script' in fixed_content, 'postgres-init-script found'),
            ('POSTGRES_DB' not in fixed_content, 'POSTGRES_DB removed'),
            ('PGDATA' in fixed_content, 'PGDATA added'),
            ('postgres-data' in fixed_content, 'postgres-data PVC name'),
            ('/var/lib/postgresql/data/pgdata' in fixed_content, 'PGDATA path'),
            ('/var/lib/postgresql\"' in fixed_content, 'Mount path fixed'),
            ('init-volume' in fixed_content, 'init-volume name'),
            ('longhorn-single' in fixed_content, 'storageClassName'),
            ('postgres-run' in fixed_content, 'emptyDir postgres-run'),
            ('postgres-tmp' in fixed_content, 'emptyDir postgres-tmp'),
            ('subPath: 00-CREATE.sql' in fixed_content, 'subPath added'),
        ]
        
        all_pass = True
        for check, desc in checks:
            status = '✓' if check else '✗'
            if not check:
                all_pass = False
            print(f'  {status} {desc}')
        
        sys.exit(0 if all_pass else 1)
        
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()