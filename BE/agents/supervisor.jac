# supervisor.jac
import from byllm.llm { Model };
glob llm = Model(model_name="gemini-flash-1.5");

walker supervisor {
    has repo_url: str = "";
    has repo_name: str = "";
    has repo_path: str = "";
    has file_tree: str = "";
    has readme_summary: str = "";
    has targets: list = [];

    # LLM-driven planner to choose next targets (file paths)
    def plan_next_targets(file_tree: str, readme_summary: str) -> list by llm();

    can execute with start_entry {
        print("[Supervisor] Starting pipeline for", self.repo_url);

        # 1) Clone & map
        mapper = [here ++> RepoMapper()];
        visit mapper[0] with repo_entry { "repo_url": self.repo_url };
        mapper_report = mapper[0].report;  # we will expect python helpers to return report via 'report' field
        if not mapper_report or not mapper_report["ok"] {
            err = mapper_report["error"] if mapper_report else "unknown error";
            print("[Supervisor] RepoMapper failed:", err);
            report {"ok": False, "error": err};
            return;
        }
        self.repo_path = mapper_report["path"];
        self.repo_name = mapper_report.get("name", "repo");
        self.file_tree = mapper_report["file_tree"];
        readme_text = mapper_report.get("readme", "");

        # 2) Summarise README
        rs = [here ++> ReadmeSummariser()];
        visit rs[0] with summarise_entry { "readme_text": readme_text };
        rs_report = rs[0].report;
        self.readme_summary = rs_report.get("summary", "");

        # 3) Planning: determine initial target list
        try {
            self.targets = self.plan_next_targets(self.file_tree, self.readme_summary);
        } catch(e) {
            print("[Supervisor] LLM planning failed, falling back to heuristics");
            # simple heuristic fallback: top-level python files and main.py/app.py
            self.targets = [];
            for f in self.file_tree {
                if f.endswith("main.py") or f.endswith("app.py") or f.endswith("index.js") {
                    self.targets.append(f);
                }
            }
            # take first 5 files if still empty
            if not self.targets {
                n = 0;
                for f in self.file_tree {
                    self.targets.append(f);
                    n = n + 1;
                    if n >= 5 { break; }
                }
            }
        }

        print("[Supervisor] initial targets:", self.targets);

        # 4) Iterative analysis for prioritized files
        ccg_meta = [];
        for t in self.targets {
            analyzer = [here ++> CodeAnalyzer()];
            visit analyzer[0] with analyze_entry { "file_path": t, "repo_path": self.repo_path };
            a_report = analyzer[0].report;
            if a_report and a_report["ok"] {
                ccg_meta.append(a_report["summary"]);
            } else {
                print("[Supervisor] Analyzer skipped or failed for", t);
            }
        }

        # 5) Doc generation
        docgen = [here ++> DocGenie()];
        visit docgen[0] with docgen_entry {
            "repo_name": self.repo_name,
            "summary": self.readme_summary,
            "ccg_meta": ccg_meta,
            "file_tree": self.file_tree,
            "repo_path": self.repo_path
        };
        doc_report = docgen[0].report;
        if not doc_report or not doc_report["ok"] {
            print("[Supervisor] DocGenie failed:", doc_report.get("error", "unknown"));
            report {"ok": False, "error": doc_report.get("error", "unknown")};
            return;
        }

        print("[Supervisor] Completed. Docs at:", doc_report["path"]);
        report {"ok": True, "docs_path": doc_report["path"], "outputs": doc_report.get("outputs", {})};
    }
}
