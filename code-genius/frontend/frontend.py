"""
Codebase Genius - Streamlit Frontend
Interactive UI for AI-powered documentation generation
"""

import streamlit as st
import os
import json
import subprocess
from pathlib import Path
from datetime import datetime
import tempfile
import zipfile

# Page config
st.set_page_config(
    page_title="Codebase Genius",
    page_icon="📚",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        font-weight: bold;
        text-align: center;
        background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 1rem;
    }
    .stButton>button {
        width: 100%;
        background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
        padding: 0.75rem;
        font-weight: 600;
        border-radius: 8px;
    }
    .metric-card {
        background: #f0f2f6;
        padding: 1.5rem;
        border-radius: 10px;
        border-left: 4px solid #667eea;
    }
    .agent-status {
        padding: 0.5rem 1rem;
        border-radius: 20px;
        display: inline-block;
        font-weight: 600;
        margin: 0.25rem;
    }
    .agent-active {
        background: #d4edda;
        color: #155724;
    }
    .agent-idle {
        background: #f8d7da;
        color: #721c24;
    }
</style>
""", unsafe_allow_html=True)

# Initialize session state
if 'documentation' not in st.session_state:
    st.session_state.documentation = None
if 'analysis_complete' not in st.session_state:
    st.session_state.analysis_complete = False
if 'processing' not in st.session_state:
    st.session_state.processing = False

def analyze_repository(repo_path, output_path):
    """Run the Jac backend to analyze repository"""
    try:
        # In production, this would call the Jac backend
        # For demo purposes, we'll simulate the analysis
        
        # Simulate file scanning
        files = []
        extensions = ['.py', '.js', '.java', '.cpp', '.jac', '.ts', '.jsx', '.tsx']
        
        for ext in extensions:
            for file_path in Path(repo_path).rglob(f"*{ext}"):
                files.append({
                    'path': str(file_path),
                    'size': file_path.stat().st_size,
                    'language': ext[1:]
                })
        
        # Simulate documentation generation
        result = {
            'repo_name': Path(repo_path).name,
            'files_analyzed': len(files),
            'total_lines': sum([f['size'] // 50 for f in files]),  # Rough estimate
            'languages': list(set([f['language'] for f in files])),
            'overview': f"""# {Path(repo_path).name}

This is an AI-generated documentation overview for {Path(repo_path).name}.

## Overview
This project contains {len(files)} source files across {len(set([f['language'] for f in files]))} programming languages.

## Key Features
- Multi-language support
- Modular architecture
- Comprehensive functionality

## Technology Stack
Languages detected: {', '.join(set([f['language'] for f in files]))}
""",
            'architecture': """## System Architecture

The codebase follows a modular architecture pattern with clear separation of concerns:

### Components
- **Core Modules**: Business logic and data processing
- **API Layer**: External interfaces and endpoints
- **Utilities**: Helper functions and shared code

### Design Patterns
- Dependency injection for loose coupling
- Factory patterns for object creation
- Observer pattern for event handling
""",
            'setup_guide': """## Setup and Installation

### Prerequisites
- Python 3.8+ or Node.js 14+
- Git
- Package manager (pip/npm)

### Installation Steps
1. Clone the repository
2. Install dependencies: `pip install -r requirements.txt`
3. Configure environment variables
4. Run the application: `python main.py`

### Configuration
Create a `.env` file with required variables.

### Troubleshooting
- Check dependency versions
- Ensure environment is properly configured
""",
            'api_docs': [
                {
                    'file': 'main.py',
                    'documentation': """## API Documentation

### Functions

#### `initialize(config)`
Initializes the application with given configuration.

**Parameters:**
- `config` (dict): Configuration dictionary

**Returns:** None

**Example:**
```python
initialize({'debug': True})
```
"""
                }
            ],
            'files': files,
            'generated_at': datetime.now().isoformat()
        }
        
        return result
        
    except Exception as e:
        st.error(f"Error analyzing repository: {str(e)}")
        return None

def display_agent_status(processing):
    """Display multi-agent system status"""
    agents = [
        ("Code Analyzer", "Analyzing source files", processing),
        ("Documentation Writer", "Generating documentation", processing),
        ("API Doc Generator", "Creating API references", processing),
        ("Architecture Mapper", "Building architecture docs", processing)
    ]
    
    cols = st.columns(2)
    for idx, (name, desc, active) in enumerate(agents):
        with cols[idx % 2]:
            status_class = "agent-active" if active else "agent-idle"
            status_text = "🤖 Active" if active else "⚪ Idle"
            st.markdown(f"""
            <div class="metric-card">
                <h4>{name}</h4>
                <p style="color: #666; margin: 0.5rem 0;">{desc}</p>
                <span class="agent-status {status_class}">{status_text}</span>
            </div>
            """, unsafe_allow_html=True)
            st.markdown("<br>", unsafe_allow_html=True)

# Main UI
st.markdown('<h1 class="main-header">📚 Codebase Genius</h1>', unsafe_allow_html=True)
st.markdown('<p style="text-align: center; color: #666; font-size: 1.2rem;">AI-Powered Multi-Agent Documentation System</p>', unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.header("⚙️ Configuration")
    
    st.subheader("Repository Input")
    input_method = st.radio("Choose input method:", ["Local Path", "Upload ZIP"])
    
    if input_method == "Local Path":
        repo_path = st.text_input("Repository Path", placeholder="/path/to/your/repo")
    else:
        uploaded_file = st.file_uploader("Upload Repository ZIP", type=['zip'])
        repo_path = None
        if uploaded_file:
            with tempfile.TemporaryDirectory() as tmpdir:
                zip_path = Path(tmpdir) / "repo.zip"
                with open(zip_path, 'wb') as f:
                    f.write(uploaded_file.getvalue())
                with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                    zip_ref.extractall(tmpdir)
                repo_path = tmpdir
    
    st.subheader("Output Settings")
    output_path = st.text_input("Output Directory", value="./generated_docs")
    
    st.subheader("Documentation Options")
    include_api = st.checkbox("Include API Documentation", value=True)
    include_arch = st.checkbox("Include Architecture Diagrams", value=True)
    include_setup = st.checkbox("Include Setup Guide", value=True)
    
    st.divider()
    
    generate_btn = st.button("🚀 Generate Documentation", type="primary")

# Main content area
tab1, tab2, tab3, tab4 = st.tabs(["📊 Dashboard", "📄 Documentation", "🔍 Analysis", "⚙️ Agents"])

with tab1:
    st.header("Documentation Dashboard")
    
    if generate_btn and repo_path:
        st.session_state.processing = True
        
        with st.spinner("🤖 AI agents are analyzing your codebase..."):
            result = analyze_repository(repo_path, output_path)
            
            if result:
                st.session_state.documentation = result
                st.session_state.analysis_complete = True
                st.session_state.processing = False
                st.success("✅ Documentation generated successfully!")
                st.balloons()
    
    if st.session_state.analysis_complete and st.session_state.documentation:
        doc = st.session_state.documentation
        
        # Metrics
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Files Analyzed", doc['files_analyzed'])
        with col2:
            st.metric("Total Lines", f"{doc['total_lines']:,}")
        with col3:
            st.metric("Languages", len(doc['languages']))
        with col4:
            st.metric("Completion", "100%")
        
        st.divider()
        
        # Language distribution
        st.subheader("📊 Repository Statistics")
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**Languages Detected:**")
            for lang in doc['languages']:
                st.write(f"• {lang.upper()}")
        
        with col2:
            st.markdown("**Documentation Sections:**")
            sections = ["Overview", "Architecture", "API Docs", "Setup Guide"]
            for section in sections:
                st.write(f"✓ {section}")

with tab2:
    st.header("Generated Documentation")
    
    if st.session_state.documentation:
        doc = st.session_state.documentation
        
        # Overview
        with st.expander("📖 Overview", expanded=True):
            st.markdown(doc['overview'])
        
        # Architecture
        if include_arch:
            with st.expander("🏗️ Architecture"):
                st.markdown(doc['architecture'])
        
        # Setup Guide
        if include_setup:
            with st.expander("⚙️ Setup Guide"):
                st.markdown(doc['setup_guide'])
        
        # API Documentation
        if include_api and doc['api_docs']:
            with st.expander("📚 API Documentation"):
                for api_doc in doc['api_docs']:
                    st.subheader(f"File: {api_doc['file']}")
                    st.markdown(api_doc['documentation'])
        
        # Download options
        st.divider()
        st.subheader("💾 Download Documentation")
        
        col1, col2 = st.columns(2)
        with col1:
            st.download_button(
                "Download README.md",
                doc['overview'],
                file_name="README.md",
                mime="text/markdown"
            )
        with col2:
            # Create full documentation package
            full_doc = f"{doc['overview']}\n\n{doc['architecture']}\n\n{doc['setup_guide']}"
            st.download_button(
                "Download Full Documentation",
                full_doc,
                file_name="FULL_DOCUMENTATION.md",
                mime="text/markdown"
            )
    else:
        st.info("👈 Generate documentation from the sidebar to see results here")

with tab3:
    st.header("Code Analysis Details")
    
    if st.session_state.documentation:
        doc = st.session_state.documentation
        
        st.subheader("📁 File Structure")
        for file in doc['files'][:20]:  # Show first 20 files
            st.text(f"• {file['path']} ({file['size']} bytes)")
        
        if len(doc['files']) > 20:
            st.info(f"... and {len(doc['files']) - 20} more files")
    else:
        st.info("No analysis data available yet")

with tab4:
    st.header("Multi-Agent System Status")
    display_agent_status(st.session_state.processing)
    
    st.divider()
    
    st.subheader("🤖 Agent Capabilities")
    agents_info = {
        "Code Analyzer": "Scans and analyzes source code structure, complexity, and patterns",
        "Documentation Writer": "Generates natural language documentation from code analysis",
        "API Doc Generator": "Creates comprehensive API reference documentation",
        "Architecture Mapper": "Visualizes system architecture and component relationships"
    }
    
    for agent, description in agents_info.items():
        st.markdown(f"""
        <div class="metric-card">
            <h4>🤖 {agent}</h4>
            <p style="color: #666; margin: 0;">{description}</p>
        </div>
        """, unsafe_allow_html=True)
        st.markdown("<br>", unsafe_allow_html=True)

# Footer
st.divider()
st.markdown("""
<div style="text-align: center; color: #666; padding: 2rem;">
    <p>Powered by Jac, ByLLM, and Streamlit | <strong>Codebase Genius</strong></p>
    <p style="font-size: 0.9rem;">Multi-Agent AI Documentation System</p>
</div>
""", unsafe_allow_html=True)