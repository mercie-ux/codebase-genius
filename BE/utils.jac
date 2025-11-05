import from datetime { datetime }
import os;
import json;

# Get current datetime in ISO format
def get_current_datetime() -> str {
    return datetime.now().isoformat();
}

# Get current date
def get_current_date() -> str {
    return datetime.now().strftime("%Y-%m-%d");
}

# Get current time
def get_current_time() -> str {
    return datetime.now().strftime("%H:%M:%S");
}

# Format datetime string
def format_datetime(dt_str: str, format: str = "%Y-%m-%d %H:%M:%S") -> str {
    try {
        dt = datetime.fromisoformat(dt_str);
        return dt.strftime(format);
    } except Exception as e {
        return dt_str;
    }
}

# Check if file exists
def file_exists(file_path: str) -> bool {
    return os.path.exists(file_path) and os.path.isfile(file_path);
}

# Check if directory exists
def directory_exists(dir_path: str) -> bool {
    return os.path.exists(dir_path) and os.path.isdir(dir_path);
}

# Get file extension
def get_file_extension(file_path: str) -> str {
    return os.path.splitext(file_path)[1];
}

# Get file name without extension
def get_file_name(file_path: str) -> str {
    return os.path.splitext(os.path.basename(file_path))[0];
}

# Read JSON file
def read_json_file(file_path: str) -> dict {
    try {
        with open(file_path, 'r', encoding='utf-8') as f {
            return json.load(f);
        }
    } except Exception as e {
        return {"error": f"Failed to read JSON file: {e}"};
    }
}

# Write JSON file
def write_json_file(file_path: str, data: dict) -> bool {
    try {
        with open(file_path, 'w', encoding='utf-8') as f {
            json.dump(data, f, indent=2);
        return True;
    } except Exception as e {
        print(f"Failed to write JSON file: {e}");
        return False;
    }
}

# Get file size in bytes
def get_file_size(file_path: str) -> int {
    try {
        return os.path.getsize(file_path);
    } except Exception {
        return 0;
    }
}

# Format file size to human readable
def format_file_size(size_bytes: int) -> str {
    if size_bytes < 1024 {
        return f"{size_bytes} B";
    } elif size_bytes < 1024 * 1024 {
        return f"{size_bytes / 1024:.2f} KB";
    } elif size_bytes < 1024 * 1024 * 1024 {
        return f"{size_bytes / (1024 * 1024):.2f} MB";
    } else {
        return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB";
    }
}

# Get programming language from file extension
def detect_language(file_path: str) -> str {
    extension_map = {
        ".py": "Python",
        ".js": "JavaScript",
        ".ts": "TypeScript",
        ".java": "Java",
        ".c": "C",
        ".cpp": "C++",
        ".cs": "C#",
        ".go": "Go",
        ".rs": "Rust",
        ".rb": "Ruby",
        ".php": "PHP",
        ".swift": "Swift",
        ".kt": "Kotlin",
        ".scala": "Scala",
        ".r": "R",
        ".m": "Objective-C",
        ".html": "HTML",
        ".css": "CSS",
        ".scss": "SCSS",
        ".sass": "Sass",
        ".less": "Less",
        ".json": "JSON",
        ".xml": "XML",
        ".yaml": "YAML",
        ".yml": "YAML",
        ".toml": "TOML",
        ".md": "Markdown",
        ".sql": "SQL",
        ".sh": "Shell",
        ".bash": "Bash",
        ".ps1": "PowerShell",
        ".jac": "Jac",
        ".vue": "Vue",
        ".jsx": "JSX",
        ".tsx": "TSX"
    };
    
    ext = get_file_extension(file_path).lower();
    return extension_map.get(ext, "Unknown");
}

# Check if file is a code file
def is_code_file(file_path: str) -> bool {
    code_extensions = [
        ".py", ".js", ".ts", ".java", ".c", ".cpp", ".cs", ".go", ".rs",
        ".rb", ".php", ".swift", ".kt", ".scala", ".r", ".m", ".jac",
        ".vue", ".jsx", ".tsx"
    ];
    
    ext = get_file_extension(file_path).lower();
    return ext in code_extensions;
}

# Check if file is a config file
def is_config_file(file_path: str) -> bool {
    config_extensions = [".json", ".xml", ".yaml", ".yml", ".toml", ".ini", ".conf", ".config"];
    config_names = ["dockerfile", "makefile", ".env", ".gitignore", ".dockerignore"];
    
    ext = get_file_extension(file_path).lower();
    name = os.path.basename(file_path).lower();
    
    return ext in config_extensions or name in config_names;
}

# Check if file is a documentation file
def is_doc_file(file_path: str) -> bool {
    doc_extensions = [".md", ".txt", ".rst", ".adoc"];
    return get_file_extension(file_path).lower() in doc_extensions;
}

# Get relative path from base
def get_relative_path(file_path: str, base_path: str) -> str {
    try {
        return os.path.relpath(file_path, base_path);
    } except Exception {
        return file_path;
    }
}

# Sanitize string for use as filename
def sanitize_filename(filename: str) -> str {
    invalid_chars = ['<', '>', ':', '"', '/', '\\', '|', '?', '*'];
    sanitized = filename;
    for char in invalid_chars {
        sanitized = sanitized.replace(char, '_');
    }
    return sanitized;
}

# Count lines in file
def count_lines(file_path: str) -> int {
    try {
        with open(file_path, 'r', encoding='utf-8') as f {
            return len(f.readlines());
        }
    } except Exception {
        return 0;
    }
}

# Count code lines (excluding blank lines and comments)
def count_code_lines(file_path: str) -> dict {
    try {
        with open(file_path, 'r', encoding='utf-8') as f {
            lines = f.readlines();
        }
        
        total_lines = len(lines);
        blank_lines = 0;
        comment_lines = 0;
        code_lines = 0;
        
        in_block_comment = False;
        
        for line in lines {
            stripped = line.strip();
            
            if not stripped {
                blank_lines += 1;
                continue;
            }
            
            # Multi-line comment detection
            if stripped.startswith('"""') or stripped.startswith("'''") {
                if stripped.count('"""') == 2 or stripped.count("'''") == 2 {
                    comment_lines += 1;
                } else {
                    in_block_comment = not in_block_comment;
                    comment_lines += 1;
                }
                continue;
            }
            
            if in_block_comment {
                comment_lines += 1;
                continue;
            }
            
            # Single line comment detection
            if stripped.startswith('#') or stripped.startswith('//') {
                comment_lines += 1;
                continue;
            }
            
            code_lines += 1;
        }
        
        return {
            "total": total_lines,
            "code": code_lines,
            "comments": comment_lines,
            "blank": blank_lines
        };
    } except Exception as e {
        return {
            "total": 0,
            "code": 0,
            "comments": 0,
            "blank": 0,
            "error": str(e)
        };
    }
}

# Create directory if it doesn't exist
def ensure_directory(dir_path: str) -> bool {
    try {
        os.makedirs(dir_path, exist_ok=True);
        return True;
    } except Exception as e {
        print(f"Failed to create directory: {e}");
        return False;
    }
}

# Get list of files in directory
def list_files(dir_path: str, recursive: bool = False) -> list {
    files = [];
    try {
        if recursive {
            walk_result = os.walk(dir_path);
            for item in walk_result {
                root = item[0];
                filenames = item[2];
                for filename in filenames {
                    files.append(os.path.join(root, filename));
                }
            }
        } else {
            entries = os.listdir(dir_path);
            for entry in entries {
                full_path = os.path.join(dir_path, entry);
                if os.path.isfile(full_path) {
                    files.append(full_path);
                }
            }
        }
    } except Exception as e {
        print(f"Error listing files: {e}");
    }
    
    return files;
}

# Parse git ignore patterns (basic implementation)
def should_ignore(file_path: str, ignore_patterns: list) -> bool {
    basename = os.path.basename(file_path);
    
    for pattern in ignore_patterns {
        if pattern in file_path or pattern == basename {
            return True;
        }
    }
    
    return False;
}

# Get common ignore patterns
def get_default_ignore_patterns() -> list {
    return [
        '.git',
        '__pycache__',
        'node_modules',
        '.venv',
        'venv',
        '.env',
        '.DS_Store',
        'Thumbs.db',
        '*.pyc',
        '*.pyo',
        '*.pyd',
        '.Python',
        'pip-log.txt',
        'pip-delete-this-directory.txt',
        '.coverage',
        '*.log',
        '.pytest_cache',
        '.mypy_cache',
        'dist',
        'build',
        '*.egg-info',
        '.idea',
        '.vscode',
        '*.swp',
        '*.swo',
        '*~'
    ];
}