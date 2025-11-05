# python_helpers/parser_utils.py
import os, json
from pathlib import Path

# NOTE: This is a simplified parser helper. For full functionality:
#  - Build a tree-sitter shared lib with languages you need (see tree-sitter docs)
#  - Load Language('build/my-languages.so', 'python'), etc.
#  - Implement language-specific visitor code to extract functions, classes, calls.

def _read_file_bytes(path):
    try:
        with open(path, "rb") as fh:
            return fh.read()
    except Exception as e:
        return None

def parse_with_treesitter(file_path: str):
    """
    Attempt to parse with tree-sitter; if not available or unsupported, fallback to lightweight heuristics.
    Returns: {"ok": True, "symbols": [...], "calls": [...], "summary": {...}} or {"ok": False, "error": "..."}
    """
    ext = os.path.splitext(file_path)[1].lower()
    content = _read_file_bytes(file_path)
    if content is None:
        return {"ok": False, "error": "cannot read file"}

    # QUICK fallback heuristics for Python-like files:
    try:
        text = content.decode('utf-8', errors='ignore')
    except Exception:
        text = ""

    symbols = []
    calls = []
    # naive python function/class regex extraction (fallback)
    import re
    func_pattern = re.compile(r'^\s*def\s+([A-Za-z0-9_]+)\s*\(', re.MULTILINE)
    class_pattern = re.compile(r'^\s*class\s+([A-Za-z0-9_]+)\s*[\(:]?', re.MULTILINE)
    for fm in func_pattern.finditer(text):
        symbols.append({"type": "function", "name": fm.group(1), "lineno": text[:fm.start()].count("\n")+1})
    for cm in class_pattern.finditer(text):
        symbols.append({"type": "class", "name": cm.group(1), "lineno": text[:cm.start()].count("\n")+1})

    # naive call extraction: find word(word... )
    call_pattern = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*\(', re.MULTILINE)
    for cm in call_pattern.finditer(text):
        calls.append({"call": cm.group(1), "lineno": text[:cm.start()].count("\n")+1})

    # produce a short summary
    summary = {
        "file": os.path.basename(file_path),
        "lang": ext.replace('.', '') or "txt",
        "num_symbols": len(symbols),
        "num_calls": len(calls),
        "top_symbols": symbols[:10]
    }
    return {"ok": True, "symbols": symbols, "calls": calls, "summary": summary}

def extract_code_snippet(file_path: str, lineno: int, context: int = 5):
    try:
        with open(file_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
        start = max(0, lineno - context - 1)
        end = min(len(lines), lineno + context)
        return "".join(lines[start:end])
    except Exception as e:
        return ""
