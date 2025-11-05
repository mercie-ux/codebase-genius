import from byllm.llm { Model };
glob llm = Model(model_name="gemini-flash-1.5");

node ReadmeSummariser {
    def summarise(readme_text: str) -> str by llm();
    can execute with summarise_entry {
        print("[ReadmeSummariser] summarising README...");
        sumry = self.summarise(visitor.readme_text);
        report {"ok": True, "summary": sumry};
    }
}