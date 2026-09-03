#!/usr/bin/env python3
"""Update NATS section in values.yaml to add JetStream and external cluster support."""

import re

# Read the file
with open('values.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# New NATS section
new_nats_section = '''  # ==============================================================================
  # INFRASTRUCTURE: NATS (Message Broker)
  # ==============================================================================
  nats:
    enabled: true  # Default: internal [C13]
    
    image: "nats:2"
    
    # NATS JetStream Configuration (persistence)
    jetStream:
      enabled: true           # Enable JetStream for message persistence
      storageSize: "5Gi"      # PVC size for JetStream storage
      maxMemory: "512Mi"      # Max memory for JetStream stream storage (optional)
      maxStore: "2Gi"         # Max disk storage for JetStream streams (optional)
    
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"
    
    # External NATS configuration
    external:
      enabled: false
      
      # Single NATS endpoint
      host: ""
      port: 4222
      
      # OR cluster endpoints (use this for HA clusters)
      cluster:
        enabled: false
        urls: []
        # urls:
        #   - "nats://nats-1.example.com:4222"
        #   - "nats://nats-2.example.com:4222"
        #   - "nats://nats-3.example.com:4222"
      
      # TLS Configuration
      ssl:
        enabled: true
        skipVerify: false
      
      # Credential reference (Secret must contain: user, password)
      # OR for JWT auth: jwt, seed (nkey seed)
      secretRef:
        name: ""
        keys:
          user: "user"
          password: "password"
          # JWT auth (optional):
          jwt: "jwt"
          seed: "seed"
'''

# Pattern to match the old NATS section
pattern = r'  # ==============================================================================\n  # INFRASTRUCTURE: NATS.*?(?=\n# ==============================================================================\n# CORE SERVICES)'

# Replace
new_content = re.sub(pattern, new_nats_section, content, flags=re.DOTALL)

# Write back
with open('values.yaml', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("NATS section updated successfully")
