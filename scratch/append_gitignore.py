import os

gitignore_path = r'd:\Physiqo\.gitignore'
with open(gitignore_path, 'a', encoding='utf-8') as f:
    f.write('''
# Sensitive API Keys & Environments
.env
.env.*
*.env
*.env.*

# Keystores & Signing
*.keystore
*.jks
key.properties
local.properties

# Cloud Configs (Optional but safe to ignore if containing keys)
# google-services.json
# GoogleService-Info.plist
secrets.json
''')
    
print("Added sensitive files to .gitignore")
