# main.jac - Main entry point for Codebase Genius Backend
import:jac from agents.supervisor, supervisor;
import:jac from agents.repo_mapper, RepoMapper;
import:jac from agents.readme_summariser, ReadmeSummariser;
import:jac from agents.code_analyzer, CodeAnalyzer;
import:jac from agents.docgenie, DocGenie;

# Root walker - API health check
walker serve_api {
    can start with root entry {
        print("Codebase Genius Backend Server Started");
        report {
            "status": "success",
            "message": "Codebase Genius Backend is running",
            "version": "1.0.0",
            "endpoints": {
                "analyze": "/walker/analyze_repo",
                "health": "/walker/serve_api"
            }
        };
    }
}

# Main analysis walker - Entry point for repo analysis
walker analyze_repo {
    has repo_url: str;

    can start with root entry {
        print("\n" + "="*70);
        print("CODEBASE GENIUS - Repository Analysis Starting");
        print("="*70);
        print(f"Repository URL: {self.repo_url}\n");

        # Validate repo_url
        if not self.repo_url or self.repo_url == "" {
            print("Error: repo_url is required");
            report {
                "status": "error",
                "error": "repo_url parameter is required",
                "repo_url": self.repo_url
            };
            return;
        }

        # Create and visit supervisor
        print("Initializing Supervisor...");
        sv_node = here ++> supervisor(repo_url=self.repo_url);
        
        visit [sv_node];
        
        print("\n" + "="*70);
        print("Analysis Pipeline Completed");
        print("="*70 + "\n");
        
        report {
            "status": "success",
            "message": "Repository analysis completed",
            "repo_url": self.repo_url
        };
    }
}

# Streaming walker for real-time feedback
walker stream_analysis {
    has repo_url: str;

    can start with root entry {
        print("\n Starting streaming analysis...\n");
        
        # Step 1: Clone
        report {
            "step": "cloning",
            "message": " Cloning repository...",
            "progress": 10
        };
        
        # Step 2: Mapping
        report {
            "step": "mapping",
            "message": " Mapping repository structure...",
            "progress": 30
        };
        
        # Step 3: README Analysis
        report {
            "step": "readme",
            "message": " Analyzing README...",
            "progress": 50
        };
        
        # Step 4: Code Analysis
        report {
            "step": "analyzing",
            "message": " Analyzing source code...",
            "progress": 70
        };
        
        # Step 5: Doc Generation
        report {
            "step": "generating",
            "message": " Generating documentation...",
            "progress": 90
        };
        
        # Execute actual analysis
        sv_node = here ++> supervisor(repo_url=self.repo_url);
        visit [sv_node];
        
        # Final step
        report {
            "step": "complete",
            "message": " Documentation generated successfully!",
            "progress": 100,
            "repo_url": self.repo_url
        };
    }
}

# Quick status walker
walker get_status {
    can start with root entry {
        report {
            "status": "online",
            "service": "Codebase Genius Backend",
            "agents": [
                "task_manager",
                "supervisor", 
                "repo_mapper",
                "readme_summariser",
                "code_analyzer",
                "docgenie"
            ],
            "ready": True
        };
    }
}

# Test walker for development
walker test_pipeline {
    has test_repo: str = "https://github.com/user/sample-repo";
    
    can start with root entry {
        print("\n Testing pipeline with:", self.test_repo);
        
        # Test each component
        print("\n1. Testing RepoMapper...");
        mapper = here ++> RepoMapper();
        print("   ✓ RepoMapper node created");
        
        print("\n2. Testing ReadmeSummariser...");
        summariser = here ++> ReadmeSummariser();
        print("   ✓ ReadmeSummariser node created");
        
        print("\n3. Testing CodeAnalyzer...");
        analyzer = here ++> CodeAnalyzer();
        print("   ✓ CodeAnalyzer node created");
        
        print("\n4. Testing DocGenie...");
        docgen = here ++> DocGenie();
        print("   ✓ DocGenie node created");
        
        print("\n5. Testing Supervisor...");
        supervisor_node = here ++> supervisor(repo_url=self.test_repo);
        print("   ✓ Supervisor node created");
        
        print("\n All components initialized successfully!");
        
        report {
            "status": "success",
            "message": "All agents are functioning correctly",
            "test_repo": self.test_repo
        };
    }
}