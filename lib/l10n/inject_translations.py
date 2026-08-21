import os
import json
import glob
import re
import chardet

# Maps the user's specific JSON filenames to their proper dart lang codes
filename_to_code = {
    'french': 'fr',
    'hindi': 'hi',
    'portuguese': 'pt',
    'bengali': 'bn',
    'mandarin_chinese': 'zh',
    'russian': 'ru',
    'spanish': 'es',
    'standard_arabic': 'ar',
    'urdu': 'ur'
}

def detect_encoding(file_path):
    with open(file_path, 'rb') as f:
        rawdata = f.read()
    result = chardet.detect(rawdata)
    return result['encoding'] or 'utf-8'

def clean_keys(d):
    """Qwen LLM sometimes adds trailing spaces to JSON keys. This cleans them."""
    return {k.strip(): v for k, v in d.items()}

def update_dart_file_from_json(json_path):
    basename = os.path.basename(json_path).lower()
    
    # Extract the name part (e.g. translated_french.json -> french)
    name_part = basename.replace('translated_', '').replace('.json', '')
    
    lang_code = filename_to_code.get(name_part)
    if not lang_code:
        print(f"Warning: Could not map '{basename}' to a language code. Skipping.")
        return
        
    dart_file_path = rf'd:\Physiqo\lib\l10n\lang_{lang_code}.dart'
    
    enc = detect_encoding(json_path)
    print(f"\nReading {basename} (Encoding: {enc})...")
    
    try:
        with open(json_path, 'r', encoding=enc) as f:
            translations = json.load(f)
    except json.JSONDecodeError as e:
        print(f"JSON Parsing Error in {basename}: {e}")
        return
        
    translations = clean_keys(translations)
    print(f"Found {len(translations)} keys to inject for [{lang_code.upper()}].")
    
    # Read the English file as the source of truth for key ordering
    en_file_path = r'd:\Physiqo\lib\l10n\lang_en.dart'
    with open(en_file_path, 'r', encoding='utf-8') as f:
        en_lines = f.read().split('\n')
        
    pattern = re.compile(r"^(\s*)'([^']+)':\s*'(.*)',?(\s*)$")
    
    new_content = f"final Map<String, String> lang{lang_code.capitalize()} = {{\n"
    
    missing_count = 0
    for line in en_lines:
        match = pattern.match(line)
        if match:
            k = match.group(2)
            
            # Use translated string if exists, otherwise fallback to english
            if k in translations:
                t = translations[k]
            else:
                t = match.group(3)
                missing_count += 1
                
            # Escape single quotes and format exactly like dart expects
            t = str(t).replace("'", "\\'").replace("\n", "\\n")
            new_content += f"  '{k}': '{t}',\n"
        elif line.strip() == '};' or line.strip() == '':
            pass 
            
    new_content += "};\n"
    
    with open(dart_file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
    print(f"Successfully updated {dart_file_path}")
    if missing_count > 0:
        print(f"   Note: {missing_count} keys were missing and fell back to English.")

if __name__ == '__main__':
    json_files = glob.glob(r'd:\Physiqo\lib\l10n\translated_*.json')
    
    if not json_files:
        print("No translation JSON files found!")
    
    for j_file in json_files:
        update_dart_file_from_json(j_file)
    
    print("\nInjection complete!")
