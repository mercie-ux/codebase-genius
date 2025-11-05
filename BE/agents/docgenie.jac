
import:py from generative ai
walker DocGenie {
    has repo_name: str;
    has api_key: str;
    has out_dir: str = "";


    can generate_docs with entry {
        print("[DocGenie] generating documantaion...");
    }
}