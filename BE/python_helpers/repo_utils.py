import os, tempfile, subprocess, shutil, json

def clone_repo(url: str, depth: int = 1):
    """
    Clone repo to a temp dir. Return dict:
    {"ok": True, "path": "/tmp/..", "name": "repo", "file_tree": [...], "readme": "..."} or {"ok":False, "error": "..."}
    """
    try:
        tmp = tempfile.mkdtemp(prefix="repo_")
        # prefer git from PATH: set timeout to avoid infinite waits
        proc = subprocess.run(["git", "clone", "--depth", str(depth), url, tmp],
                              capture_output=True, text=True, timeout=180)
        if proc.returncode != 0:
            shutil.rmtree(tmp, ignore_errors=True)
            return {"ok":False, "error": proc.stderr.strip()}
        
        name = os.path.basename(url.rstrip("/")).replace(".git", "")
        file_tree = generate_file_tree(tmp)
        readme = read_readme(tmp)
        return {"ok": True, "path": tmp, "name": name, "file_tree":file_tree, "readme": readme}
    except Exception as e :
        return {"ok": False, "error": str(e)}
    
def generate_file_tree(path: str):
    tree = []
    ignore = {'.git', 'node_modules', '__pycache__', '.venv', '.env'}
    for root, dirs, files in os.walk(path):
        # prune
        dirs[:] = [d for d in dirs if d not in ignore]
        rel_root = os.path.realpath(root, path)
        if rel_root == ".": rel_root = ""
        for f in files:
            if f.startswith('.'): continue
            rel_path = os.path.join(rel_root, f) if rel_root else f
            tree.append(rel_path)
    return sorted(tree)

def read_readme(path: str):
    candidate = ["README.md", "readme.md", "README.rst", "README"]
    for c in candidate:
        p = os.path.join(path, c)
        if os.path.exists(p):
            try:
                with open(p, "r", encoding="utf-8") as fh:
                    return fh.read()
            except Exception:
                return ""
    return ""