import os
import re

lib_dir = r"c:\Users\Ahmed\AndroidStudioProjects\splash_screen\lib"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'CircularProgressIndicator' not in content:
        return

    original_content = content

    # 1. Replace custom button style
    content = re.sub(
        r'CircularProgressIndicator\(\s*color:\s*textColor,\s*strokeWidth:\s*2,?\s*\)',
        r'CustomLoader(color1: textColor, size: 6)',
        content
    )

    # 2. Replace generic CircularProgressIndicator(color: XYZ)
    content = re.sub(
        r'CircularProgressIndicator\(\s*color:\s*([^,)]+)\s*\)',
        r'CustomLoader(color1: \1)',
        content
    )

    # 3. Replace strokeWidth: 2 with size 8
    content = re.sub(
        r'CircularProgressIndicator\(\s*strokeWidth:\s*2\s*\)',
        r'CustomLoader(size: 8)',
        content
    )
    
    # 4. Multi-line replacement for buttons
    content = re.sub(
        r'CircularProgressIndicator\([\s\S]*?strokeWidth:\s*2,[\s\S]*?\)',
        r'CustomLoader(color1: Colors.white, size: 8)',
        content
    )

    if content != original_content:
        # Check if import is needed
        if 'custom_loader.dart' not in content:
            # Find the last import using regex to insert after it
            imports = re.findall(r"^import\s+['\"].*?['\"];\s*", content, re.MULTILINE)
            if imports:
                last_import_match = re.search(r"(^import\s+['\"].*?['\"];\s*\n)(?!import)", content, re.MULTILINE)
                if last_import_match:
                    content = content[:last_import_match.end()] + "import 'package:splash_screen/core/widgets/custom_loader.dart';\n" + content[last_import_match.end():]
                else:
                    content = "import 'package:splash_screen/core/widgets/custom_loader.dart';\n" + content
            else:
                content = "import 'package:splash_screen/core/widgets/custom_loader.dart';\n" + content

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
