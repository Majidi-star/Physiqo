import os

file_path = r'd:\Physiqo\lib\l10n\translations.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Keys to add for 'fa'
fa_keys = """
      'model_auto_failover_title': 'تغییر خودکار به مدل پشتیبان',
      'model_auto_failover_desc': 'سوئیچ خودکار به مدلهای جایگزین در صورت بروز خطا',
      'model_text_generation': 'تولید و پردازش متن',
      'model_vision_generation': 'پردازش و تحلیل تصویر',
"""

# Keys to add for 'en'
en_keys = """
      'model_auto_failover_title': 'Universal Auto-Failover',
      'model_auto_failover_desc': 'Automatically switch to backup models if the active provider fails',
      'model_text_generation': 'Text Generation',
      'model_vision_generation': 'Vision Processing',
"""

# Insert for 'fa' (find the end of 'fa' block, or just insert at the beginning of 'fa' block)
if "model_auto_failover_title" not in content:
    # Insert after "'fa': {"
    content = content.replace(
        "'fa': {",
        "'fa': {" + fa_keys
    )
    # Insert after "'en': {"
    content = content.replace(
        "'en': {",
        "'en': {" + en_keys
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Translations added successfully!")
