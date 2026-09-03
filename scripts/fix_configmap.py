#!/usr/bin/env python3
# Fix the configmaps.yaml to quote the nats.url value

with open('templates/configmaps.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# Quote the SERVER_URL value to handle cluster URLs with special characters
content = content.replace(
    'SERVER_URL: {{ include "tazama.nats.url" $ }}',
    'SERVER_URL: {{ include "tazama.nats.url" $ | quote }}'
)

with open('templates/configmaps.yaml', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed SERVER_URL quoting in configmaps.yaml")
