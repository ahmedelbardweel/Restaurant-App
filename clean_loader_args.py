import os
import re

lib_dir = r"c:\Users\Ahmed\AndroidStudioProjects\splash_screen\lib"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # CustomLoader(color1: XYZ, size: 8) -> CustomLoader(size: 8)
    # CustomLoader(color1: XYZ) -> CustomLoader()
    
    # regex to remove `color1: something, `
    content = re.sub(r'color1:\s*[^,)]+,\s*', '', content)
    # regex to remove `color1: something` (if it's the last or only arg)
    content = re.sub(r'color1:\s*[^,)]+\s*', '', content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated args in: {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
