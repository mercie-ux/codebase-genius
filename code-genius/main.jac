"""
Codebase Genius - Multi-Agent Documentation System
Backend implementation using Jac and ByLLM
"""

import from mtllm.llms {OpenAI}
import os;
import json;
import from pathlib {Path}
import from datetime {datetime}

glob llm = OpenAI(model_name="gpt-4");

# Data models
obj FileAnalysis {
    has file_path: str;
    has language: str;
    has summary: str;
    has functions: list;
    has classes: list;
    has dependencies: list;
    has complexity_score: float;
}

obj DocumentationResult {
    has repo_name: str;
    has overview: str;
    has architecture: str;
    has api_docs: list;
    has setup_guide: str;
    has file_analyses: list;
    has generated_at: str;
}

# Agent: Code Analyzer
node CodeAnalyzer {
    has name: str = "Code Analyzer";
    
    can analyze_file(file_path: str, content: str) -> FileAnalysis {
        prompt = f"""Analyze this code file and provide structured information:
        
        File: {file_path}
        Content:
        ```
        {content[:3000]}
        ```

        Provide a JSON response with:
        - language: programming language
        - summary: brief description
        - functions: list of function names and purposes
        - classes: list of class names and purposes
        - dependencies: list of imports/dependencies
        - complexity_score: 0-10 rating of code complexity
        """;
        
        response = llm.generate(prompt);
        
        # Parse LLM response
        try {
            data = json.loads(response);
            result = FileAnalysis(
                file_path=file_path,
                language=data.get("language", "unknown"),
                summary=data.get("summary", ""),
                functions=data.get("functions", []),
                classes=data.get("classes", []),
                dependencies=data.get("dependencies", []),
                complexity_score=float(data.get("complexity_score", 5.0))
            );
            return result;
        } except Exception as e {
            result = FileAnalysis(
                file_path=file_path,
                language="unknown",
                summary="Analysis failed",
                functions=[],
                classes=[],
                dependencies=[],
                complexity_score=0.0
            );
            return result;
        }
    }
}

# Agent: Documentation Writer
node DocumentationWriter {
    has name: str = "Documentation Writer";
    
    can generate_overview(repo_name: str, file_analyses: list) -> str {
        files_summary = "\n".join([
            f"- {fa.file_path}: {fa.summary}" 
            for fa in file_analyses[:10]
        ]);
        
        prompt = f"""Create a comprehensive README overview for the repository '{repo_name}'.
        
        Key files analyzed:
        {files_summary}

        Write a clear, engaging overview that includes:
        1. Project purpose and goals
        2. Key features
        3. Technology stack
        4. High-level architecture
        """;
        
        return llm.generate(prompt);
    }
    
    can generate_architecture(file_analyses: list) -> str {
        structure = "\n".join([
            f"- {fa.file_path} ({fa.language})" 
            for fa in file_analyses
        ]);
        
        prompt = f"""Describe the software architecture based on this file structure:

        {structure}

        Provide:
        1. Overall architecture pattern (MVC, microservices, etc.)
        2. Component relationships
        3. Data flow
        4. Key design decisions
        """;
        
        return llm.generate(prompt);
    }
    
    can generate_setup_guide(file_analyses: list) -> str {
        dependencies = set();
        for fa in file_analyses {
            for dep in fa.dependencies {
                dependencies.add(dep);
            }
        }
        
        deps_list = "\n".join([f"- {dep}" for dep in list(dependencies)[:20]]);
        
        prompt = f"""Create a setup and installation guide for this project.

        Key dependencies detected:
        {deps_list}

        Include:
        1. Prerequisites
        2. Installation steps
        3. Configuration
        4. Running the application
        5. Common troubleshooting
        """;
        
        return llm.generate(prompt);
    }
}

# Agent: API Documentation Generator
node APIDocGenerator {
    has name: str = "API Doc Generator";
    
    can generate_api_docs(file_analyses: list) -> list {
        api_docs = [];
        
        for fa in file_analyses {
            if len(fa.functions) > 0 or len(fa.classes) > 0 {
                prompt = f"""Generate API documentation for {fa.file_path}:

                Functions: {json.dumps(fa.functions)}
                Classes: {json.dumps(fa.classes)}

                For each function/class, provide:
                - Name
                - Parameters
                - Return type
                - Description
                - Example usage

                Format as markdown.
                """;
                
                doc = llm.generate(prompt);
                api_docs.append({
                    "file": fa.file_path,
                    "documentation": doc
                });
            }
        }
        
        return api_docs;
    }
}

# Orchestrator Walker
walker DocumentationOrchestrator {
    has repo_path: str;
    has output_path: str = "./docs";
    
    can process with `root entry {
        print(f"Starting documentation generation for: {self.repo_path}");
        
        # Initialize agents
        analyzer = CodeAnalyzer();
        writer = DocumentationWriter();
        api_gen = APIDocGenerator();
        
        # Analyze codebase
        file_analyses = [];
        repo_path_obj = Path(self.repo_path);
        
        # Scan for code files
        extensions = ['.py', '.js', '.java', '.cpp', '.jac', '.ts'];
        
        for ext in extensions {
            try {
                files = list(repo_path_obj.rglob(f"*{ext}"));
                for file_path in files {
                    try {
                        content = file_path.read_text(encoding='utf-8');
                        analysis = analyzer.analyze_file(str(file_path), content);
                        file_analyses.append(analysis);
                        print(f"Analyzed: {file_path}");
                    } except Exception as e {
                        print(f"Error analyzing {file_path}: {e}");
                    }
                }
            } except Exception as e {
                print(f"Error scanning for {ext} files: {e}");
            }
        }
        
        print(f"Analyzed {len(file_analyses)} files");
        
        # Generate documentation components
        repo_name = repo_path_obj.name;
        
        print("Generating overview...");
        overview = writer.generate_overview(repo_name, file_analyses);
        
        print("Generating architecture documentation...");
        architecture = writer.generate_architecture(file_analyses);
        
        print("Generating API documentation...");
        api_docs = api_gen.generate_api_docs(file_analyses);
        
        print("Generating setup guide...");
        setup_guide = writer.generate_setup_guide(file_analyses);
        
        # Create result
        result = DocumentationResult(
            repo_name=repo_name,
            overview=overview,
            architecture=architecture,
            api_docs=api_docs,
            setup_guide=setup_guide,
            file_analyses=file_analyses,
            generated_at=str(datetime.now())
        );
        
        # Save documentation
        output_dir = Path(self.output_path);
        output_dir.mkdir(exist_ok=True);
        
        # Save README
        readme_path = output_dir / "README.md";
        readme_content = f"""# {repo_name}

        {overview}

        ## Architecture

        {architecture}

        ## Setup and Installation

        {setup_guide}

        ---
        *Documentation generated by Codebase Genius*
        """;
        readme_path.write_text(readme_content);
        
        # Save API docs
        api_dir = output_dir / "api";
        api_dir.mkdir(exist_ok=True);
        
        for api_doc in api_docs {
            file_name = Path(api_doc['file']).name;
            doc_path = api_dir / f"{file_name}.md";
            doc_path.write_text(api_doc['documentation']);
        }
        
        print(f"Documentation generated successfully in: {output_dir}");
        
        return result;
    }
}

# Entry point
with entry {
    # Example usage
    walker_instance = DocumentationOrchestrator(
        repo_path="./sample_repo",
        output_path="./generated_docs"
    );
    root spawn walker_instance;
}