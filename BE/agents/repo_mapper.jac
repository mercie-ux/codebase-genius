import from py_module import clone_repo, generate_file_tree, readme;

node RepoMapper {
    has repo_url: str = "";
    has local_path: str = "";
    has file_tree: str = "";
    has readme: str = "";
    has name: str = "";

    def clone_and_map(url: str) -> dict {
        res = clone_repo(url);
        return res; # returns {"ok": True, "path":...., "name":..., "file_tree:...,"}
    }

    can execute with repo_entry {
        print("[RepoMapper] clone_and_map:",);
        
    }
}