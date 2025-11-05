# CodeBase Genius

Codebase Genius is an autonomous, multi-agent documentation generator that produces high-quality markdown documentation for any public GitHub repository.
Optimized for Python and Jac, it automatically clones a repo, maps its structure, analyzes its source code, and synthesizes elegant, human-readable documentation — complete with summaries, code relationships, and diagrams.

## overview task
Codebase Genius leverages multi-agent collaboration to understand and explain complex repositories.
Given a GitHub URL, it performs the following:

1.Clones and maps the repository.

2.Summarizes the project’s README and main modules.

3.Builds a Code Context Graph (CCG) to capture relationships between functions, classes, and modules.

4.Generates structured, professional-grade markdown documentation.

Each agent in the system specializes in a part of this workflow and reports to the **Code Genius(Supervisor)**, which orchestrates the entire process.

## System Architecture
Codebase Genius is implemented as a multi-agent pipeline, inspired by the byLLM architecture.
Each agent plays a unique role in transforming raw source code into polished documentation.

1.Code Genius (Supervisor)
- Receives the Github URL and manages workflow execution.
- Prioritizes files based on repository structure and importance.
- Delegates tasks to subordinate agents: 
    - Repo Mapper
    - Code Analyzer
    - DocGenie
- Aggregate intermediate results and compiles the final documentation.

2. RepoMapper
Responsible for repository structure analysis.
- Clones the provided Github repo to a local workspace.
- Recursively traverses the repository, building a structured map of files and directories while ignoring irrelevant paths (.git, __pycache__, node__modules).
Reads and summarizes `README.md` or equivalent entry files into a concise overview whic then guides the supervisor in planning deeper analysis steps.

3. Code Analyzer
performs detailed structural and semantic analysis.

- parses code using Tree-sitter
- Builds a code context graph to model:
    - Function calls and dependencies.
    - Class hierarchies and inheritance.
    - Module composition and cross-references.
- provides a queryable API for higher agents:

4. DocGenie
Synthesizes all gathered information into well-structures, readable Markdown.
- Combines structured data from Repo Mapper and Code Analyzer.
- Produces documentation sections such as:
    - Project Overview
    - Installation
    - Usage
    - API Reference
    - Class & Function Graphs
- Enhances readability with **headings, tables, bullet points, and diagrams**

# Future enhancements
- Language-agnostic plugin system
- Incremental updates via git diff tracking
- Github Actions integration for auto-generated docs on PRs

# how to run the project
1.clone the main repo
git clone <repo>

2.install the requirements
`pip install -r requirements.txt`

3.start the serve with
cd BE
`jac serve main.jac`

Run the user interface
cd FE
`streamlit run app.py`

## *Note* you must have jac installed.

# License
MIT License © 2025 - Developed as part of the Codebase Genius Autonomous Documentation Framework.

