# task_manager.jac
# HTTP-facing walker: accepts repo_url and runs the supervisor (synchronous by default)
import from byllm.lib { Model }
glob llm = Model(model_name="gemini-flash-1.5");

walker task_manager {
    has repo_url: str = "";
    has sync: bool = true;

    can execute with root entry {
        send("Task manager starting for: " + self.repo_url);
        sv = [here ++> supervisor()];
        # start supervisor walker synchronously
        visit sv[0];
         with entry { "repo_url": self.repo_url};

        # The supervisor will report status via report at end
        
        send("Supervisor execution complete!");
    }
}
