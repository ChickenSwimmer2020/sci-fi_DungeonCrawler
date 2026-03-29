import re
from pathlib import Path
root = Path('.')
import_file = root / 'source' / 'Import.hx'
imports = []
for line in import_file.read_text(encoding='utf-8').splitlines():
    m = re.match(r'\s*import\s+([^;]+);?', line)
    if m:
        imp = m.group(1).strip()
        if imp:
            imports.append(imp)
all_text = ''
for p in root.rglob('*'):
    if p.is_file() and p.suffix in ['.hx','.xml','.md','.txt']:
        try:
            all_text += p.read_text(encoding='utf-8', errors='ignore') + '\n'
        except Exception:
            pass
unused = []
for imp in imports:
    name = imp.split('.')[-1]
    if not re.search(r'\b' + re.escape(name) + r'\b', all_text):
        unused.append(imp)
print('maybe-unused:')
for u in unused:
    print(u)
print('---')
print('total imports', len(imports), 'unused', len(unused))
