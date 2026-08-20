import os
import re

file_path = r'd:\Physiqo\lib\services\ai_service.dart'
methods_path = r'd:\Physiqo\scratch\ai_service_methods.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

with open(methods_path, 'r', encoding='utf-8') as f:
    methods_content = f.read()

# Find the start of sendMessage and the end of the file.
start_idx = content.find('  Future<AiResponse> sendMessage')
if start_idx != -1:
    content = content[:start_idx] + methods_content + "\n}\n"
    
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done phase 2")
