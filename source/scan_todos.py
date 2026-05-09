import os
import sys

def scan_todos(directory):
    todos = []
    
    for root, dirs, files in os.walk(directory):
        # skip hidden folders like .git
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for filename in files:
            filepath = os.path.join(root, filename)
            relpath = os.path.relpath(filepath, directory)
            
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    for line_num, line in enumerate(f, start=1):
                        idx = line.find('//TODO:')
                        if idx != -1:
                            message = line[idx + 7:].strip()
                            todos.append({
                                'message': message,
                                'filename': filename,
                                'relpath': relpath.replace('\\', '/'),
                                'line': line_num
                            })
            except (PermissionError, IsADirectoryError):
                pass
    
    return todos

def write_todo_md(directory, todos):
    output_path = os.path.join(directory, 'TODO_python.md')
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('# TODOs\n\n')
        if not todos:
            f.write('No TODOs found!\n')
        else:
            for todo in todos:
                line = f"* {todo['message']} [{todo['filename']}](source/{todo['relpath']}#L{todo['line']})\n"
                f.write(line)
    
    print(f"Found {len(todos)} TODO(s). Written to {output_path}")

if __name__ == '__main__':
    directory = sys.argv[1] if len(sys.argv) > 1 else '.'
    directory = os.path.abspath(directory)
    
    if not os.path.isdir(directory):
        print(f"Error: '{directory}' is not a valid directory.")
        sys.exit(1)
    
    print(f"Scanning {directory}...")
    todos = scan_todos(directory)
    write_todo_md(directory, todos)
