import streamlit as st
import websocket
import threading
import json
import time

st.set_page_config(page_title="Code Genius", page_icon="🧩", layout="centered")

st.title("🧩 Jac Code Genius")
st.markdown("Analyze any Github repository with real-time AI updates")

repo_url=st.text_input("Enter Github repository URL:")
analyze_btn = st.button("Start Analysis")

progress_placeholder = st.empty()
log_box = st.empty()

def stream_logs(repo_url):
    ws = websocket.WebSocket()
    try:
        ws.connect("ws://localhost:8000/jac/stream_repo_analysis")
        ws.send(json.dumps({"repo_url": repo_url}))
        logs = ""
        while True:
            msg = ws.recv()
            if not msg:
                break
            try: 
                logs += msg + "\n"
                log_box.text_area("Live Analysis Log", logs, height=300)

            except Exception:
                pass
    except Exception as e:
        log_box.error(f"Connection error: {e}")
    finally:
        ws.close()

if analyze_btn and repo_url:
    progress_placeholder.info(f"Starting analysis for {repo_url}...")
    threading.Thread(target=stream_logs, args=(repo_url,), daemon=True).start()