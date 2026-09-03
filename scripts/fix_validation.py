#!/usr/bin/env python3
import re

with open('templates/_validation.tpl', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and fix - look for the exact pattern
# We need to add {{- end -}} for if $infra.enabled AND for define "tazama.validation.nats"

# Find where JetStream block ends
pattern = r'(  {{- end -}})\r?\n\r?\n\r?\n({{- define "tazama\.validation\.all")'
match = re.search(pattern, content)

if match:
    print(f"Found pattern at position {match.start()}")
    content = content[:match.start(1)] + match.group(1) + '\r\n{{- end -}}\r\n\r\n{{- end -}}\r\n\r\n' + match.group(2) + content[match.end():]
    with open('templates/_validation.tpl', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed!")
else:
    print("Pattern not found")
    # Let's see what's there
    lines = content.split('\n')
    for i, line in enumerate(lines[170:180], start=171):
        print(f"{i}: {repr(line)}")
