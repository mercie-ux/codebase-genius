
import from byllm.llm { Model };
import time;
import pathlib;

# Global LLM binding (adjust model name as needed)
glob llm = Model(model_name="gemini-flash-1.5");

# Node to store file information
node CodeFile {
    has filepath: str = "";
    has filename: str = "";
    has content: str = "";
    has language: str = "";
    has summary: str = "";
    has functions: list = [];
}

# Node to store documentation artifacts
node Documentation {
    has doc_type: str = ""; # e.g. "summary", "architecture"
    has content: str = "";
    has generated_at: str = "";
}

# Main analyzer node
node CodebaseAnalyzer {
    has root_path: str = "";
    has supported_extensions: list = [".py", ".jac", ".js", ".java", ".cpp", ".c", ".go", ".rs", ".ts", ".tsx"];

    # Scan directory and collect code files
    def scan_directory(directory_path: str) -> list {
        files: list = [];
        try {
            path_obj = pathlib.Path(directory_path);
            for file_path in path_obj.rglob("*") {
                if file_path.is_file() and (file_path.suffix in self.supported_extensions) {
                    # Read file content
                    content = "";
                    try {
                        with open(str(file_path), "r", encoding="utf-8") as f {
                            content = f.read();
                        }
                        files.append({
                            "filepath": str(file_path),
                            "filename": file_path.name,
                            "content": content,
                            "language": file_path.suffix[1:]
                        });
                    } except err {
                        print_s("Error reading " + str(file_path) + ": " + str(err));
                    }
                }
            }
        } except err {
            print_s("Error scanning directory: " + str(err));
        }
        return files;
    }

    # Analyze a single code file using the LLM. Limit content length before calling.
    def analyze_code_file(filepath: str, content: str, language: str) -> dict by llm(
        reason=true,
        incl_info=(
            "Analyze this " + language + " code file and provide: "
            + "1. A concise summary (2-3 sentences). "
            + "2. List of main functions/methods with brief descriptions. "
            + "3. Key dependencies or imports. "
            + "4. Overall purpose and design patterns used."
        )
    );

    # Generate an architecture overview from file summaries
    def generate_architecture_overview(files_summary: str) -> str by llm(
        reason=true,
        incl_info=(
            "Based on the code files analyzed, generate a comprehensive architecture overview including: "
            + "1. High-level system architecture. "
            + "2. Key components and their relationships. "
            + "3. Data flow and interactions. "
            + "4. Design patterns identified. "
            + "5. Potential improvements or concerns."
        )
    );

    # Generate detailed function documentation
    def generate_function_documentation(function_code: str, language: str) -> str by llm(
        reason=true,
        incl_info=(
            "Generate detailed documentation for this function including: "
            + "1. Purpose and functionality. "
            + "2. Parameters and return values. "
            + "3. Example usage. "
            + "4. Time/space complexity if applicable. "
            + "5. Edge cases and error handling."
        )
    );

    # Answer questions about the codebase given context
    def answer_codebase_question(question: str, context: str) -> str by llm(
        reason=true,
        incl_info=(
            "Answer the question about the codebase using the provided context. "
            + "Be specific, reference actual code when possible, and provide examples."
        )
    );

    # Execution entry triggered by documentation_walker
    can execute with documentation_walker entry {
        print_s("\n[CodebaseAnalyzer Activated]");
        print_s("Analyzing codebase at: " + visitor.target_directory + "\n");

        code_files = self.scan_directory(visitor.target_directory);
        print_s("Found " + str(len(code_files)) + " code files\n");

        files_data: list = [];

        for file_info in code_files {
            print_s("Analyzing: " + file_info["filename"] + "...");

            # Create a CodeFile node and populate it
            code_file_node = CodeFile(
                filepath=file_info["filepath"],
                filename=file_info["filename"],
                content=file_info["content"],
                language=file_info["language"]
            );

            #Run LLM analysis on a truncated preview of the file (to avoid huge prompts)
            preview = file_info["content"];
            if len(preview) > 3000 {
                preview = preview[:3000];
            }

            analysis = self.analyze_code_file(file_info["filepath"], preview, file_info["language"]);
            code_file_node.summary = str(analysis);

            #Attach the node to the graph/store
            self ++> code_file_node;

            files_data.append({
                "filename": file_info["filename"],
                "summary": str(analysis)
            });

            print_s(file_info["filename"] + " analyzed\n");
        }

        # Generate architecture overview using aggregated summaries
        print_s("Generating architecture overview...");
        arch_overview = self.generate_architecture_overview(str(files_data));

        arch_doc = Documentation(
            doc_type="architecture",
            content=arch_overview,
            generated_at=str(time.strftime("%Y-%m-%d %H:%M:%S"))
        );
        self ++> arch_doc;

        print_s("\n" + "="*60);
        print_s("ARCHITECTURE OVERVIEW");
        print_s("="*60);
        print_s(arch_overview);
        print_s("="*60 + "\n");

        report {
            "status": "complete",
            "files_analyzed": len(code_files),
            "architecture_overview": arch_overview,
            "files": files_data
        };
    }
}

# Q&A Node for codebase questions
node CodebaseQA {
    def get_codebase_context() -> str {
        parts: list = [];
        code_files = [self <-- (`?CodeFile)];

        for cf in code_files {
            parts.append(
                "File: " + cf.filename + "\n"
                + "Language: " + cf.language + "\n"
                + "Summary: " + cf.summary + "\n"
            );
        }
        return "\n".join(parts);
    }

    def answer_question(question: str, context: str) -> str by llm(
        reason=true,
        incl_info=(
            "You are a code documentation expert. Answer questions about the codebase "
            + "using the provided context. Be specific and reference actual files/functions."
        )
    );

    can execute with qa_walker entry {
        print_s("\n[CodebaseQA Activated]");
        print_s("Question: " + visitor.question + "\n");

        context = self.get_codebase_context();

        answer = self.answer_question(visitor.question, context);

        print_s("Answer:");
        print_s("-" * 60);
        print_s(answer);
        print_s("-" * 60 + "\n");

        report {
            "question": visitor.question,
            "answer": answer
        };
    }
}

# Documentation generator node
node DocumentationGenerator {
    def generate_markdown_docs(files_data: list, architecture: str) -> str by llm(
        reason=true,
        incl_info=(
            "Generate comprehensive markdown documentation including: "
            + "1. Table of contents. "
            + "2. Project overview. "
            + "3. Architecture section. "
            + "4. File-by-file documentation. "
            + "5. Getting started guide. "
            + "Use proper markdown formatting with headers, code blocks, and lists."
        )
    );

    can execute with doc_generator_walker entry {
        print_s("\n[DocumentationGenerator Activated]");

        code_files = [self <-- (`?CodeFile)];
        files_data: list = [];

        for cf in code_files {
            files_data.append({
                "filename": cf.filename,
                "language": cf.language,
                "summary": cf.summary,
                "filepath": cf.filepath
            });
        }

        arch_docs = [self <-- (`?Documentation)];
        architecture = "";
        for doc in arch_docs {
            if doc.doc_type == "architecture" {
                architecture = doc.content;
                break;
            }
        }

        print_s("Generating markdown documentation...");
        markdown_content = self.generate_markdown_docs(files_data, architecture);

        output_path = visitor.output_path or "DOCUMENTATION.md";
        try {
            with open(output_path, "w", encoding="utf-8") as f {
                f.write(markdown_content);
            }
            print_s("Documentation saved to: " + output_path + "\n");
        } catch err {
            print_s("Error saving documentation: " + str(err));
        }

        report {
            "status": "complete",
            "output_path": output_path,
            "content": markdown_content
        };
    }
}

# Routing enum
enum RoutingNodes {
    ANALYZE_CODEBASE,
    ASK_QUESTION,
    GENERATE_DOCS
}

# Main walker for documentation
walker documentation_walker {
    has target_directory: str = ".";
    has action: str = "analyze";
    has question: str = "";
    has output_path: str = "DOCUMENTATION.md";

    def route_action(action: str) -> RoutingNodes by llm(
        reason=true,
        incl_info=(
            "Route based on action: 'analyze' -> ANALYZE_CODEBASE; 'qa' or 'question' -> ASK_QUESTION; 'generate' or 'docs' -> GENERATE_DOCS"
        )
    );

    can execute with `root entry {
        print_s("\n" + "="*60);
        print_s("CODEBASE GENIUS - AI Documentation System");
        print_s("="*60);

        if self.action == "analyze" {
            route_name = RoutingNodes.ANALYZE_CODEBASE;
        } elif self.action in ["qa", "question"] {
            route_name = RoutingNodes.ASK_QUESTION;
        } else {
            route_name = RoutingNodes.GENERATE_DOCS;
        }

        node_map = {
            RoutingNodes.ANALYZE_CODEBASE: CodebaseAnalyzer,
            RoutingNodes.ASK_QUESTION: CodebaseQA,
            RoutingNodes.GENERATE_DOCS: DocumentationGenerator
        };

        node_type = node_map[route_name];
        target_node = [-->(`?node_type)];

        if not target_node {
            target_node = [here ++> node_type()];
        }

        visit target_node[0];
    }
}

# Q&A walker
walker qa_walker {
    has question: str = "";

    can execute with `root entry {
        print_s("\n" + "="*60);
        print_s("CODEBASE GENIUS - Q&A Mode");
        print_s("="*60);

        qa_node = [-->(`?CodebaseQA)];
        if not qa_node {
            qa_node = [here ++> CodebaseQA()];
        }

        visit qa_node[0];
    }
}

# Documentation generator walker
walker doc_generator_walker {
    has output_path: str = "DOCUMENTATION.md";

    can execute with `root entry {
        print_s("\n" + "="*60);
        print_s("CODEBASE GENIUS - Documentation Generator");
        print_s("="*60);

        gen_node = [-->(`?DocumentationGenerator)];
        if not gen_node {
            gen_node = [here ++> DocumentationGenerator()];
        }
        visit gen_node[0];
    }
}


