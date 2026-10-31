#!/usr/bin/env python3
"""911 agent: GitHub Models free-tier attempt. Creates a reviewed PR, never merges."""
import json, os, pathlib, re, subprocess, sys, urllib.request, urllib.error
ROOT=pathlib.Path(__file__).resolve().parents[1]
def out(msg): print("911:",msg,flush=True)
def git(*args): return subprocess.check_output(["git",*args],cwd=ROOT,text=True).strip()
def main():
 token=os.environ.get("GH_TOKEN","")
 if not token: raise RuntimeError("Missing GITHUB_TOKEN")
 task=os.environ.get("TASK_PATH","911/tasks/002-premium-inventory.md")
 event=os.environ.get("GITHUB_EVENT_NAME","workflow_dispatch")
 issue_number=""
 if event=="issues":
  payload=json.loads(pathlib.Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
  issue=payload["issue"]
  if issue["user"]["login"].lower()!=os.environ["GITHUB_REPOSITORY"].split("/")[0].lower():
   raise RuntimeError("Only repository owner can dispatch 911 issues")
  if not issue["title"].startswith("[911]"): raise RuntimeError("Issue title must start [911]")
  task=issue["title"]+"\n"+issue.get("body","")
  issue_number=str(issue["number"])
 else:
  path=(ROOT/task).resolve()
  if not path.is_relative_to(ROOT/"911"/"tasks") or not path.is_file(): raise RuntimeError("Invalid task path")
  task=path.read_text(encoding="utf-8")
 files={}
 for p in ["scripts/main.gd","scripts/store.gd","scripts/ui911.gd","project.godot"]:
  f=ROOT/p
  if f.is_file(): files[p]=f.read_text(encoding="utf-8")[:24000]
 system=("You are a senior Godot 4.4.1 game developer. Return ONLY a JSON object with "
         "a files array of objects {path,content} and a summary string. "
         "Implement a small, coherent, functional improvement toward the user's task. "
         "Only modify existing .gd files under scripts/ or add .gd files under scripts/. "
         "Never output binary assets, workflows, tokens, or markdown. Preserve current functionality. "
         "At most 3 files, each <= 35000 characters. If request needs art assets, implement only code-side "
         "improvements and state asset limitations in summary.")
 payload={"model":os.getenv("MODEL_NAME","openai/gpt-4.1-mini"),"messages":[
  {"role":"system","content":system},
  {"role":"user","content":"TASK:\n"+task[:10000]+"\nEXISTING FILES:\n"+json.dumps(files,ensure_ascii=False)}],
  "temperature":0.2,"max_tokens":7000}
 req=urllib.request.Request("https://models.github.ai/inference/chat/completions",
  data=json.dumps(payload).encode(),headers={"Authorization":"Bearer "+token,"Content-Type":"application/json","Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"})
 try:
  with urllib.request.urlopen(req,timeout=150) as res: data=json.load(res)
 except urllib.error.HTTPError as e:
  raise RuntimeError("GitHub Models request failed HTTP "+str(e.code)+": "+e.read().decode()[:500]) from e
 content=data["choices"][0]["message"]["content"].strip()
 if content.startswith("```"): content=re.sub(r"^\x60{3}(?:json)?\s*|\s*\x60{3}$","",content)
 result=json.loads(content)
 edits=result.get("files",[])
 if not isinstance(edits,list) or not 1<=len(edits)<=3: raise RuntimeError("AI returned invalid file count")
 checked=[]
 for edit in edits:
  path=edit.get("path",""); code=edit.get("content","")
  if not re.fullmatch(r"scripts/[a-zA-Z0-9_/-]+\.gd",path) or ".." in path: raise RuntimeError("Unsafe file path")
  if not isinstance(code,str) or len(code)>35000 or not code.strip(): raise RuntimeError("Invalid code")
  checked.append((path,code))
 branch="911/agent-"+os.environ.get("GITHUB_RUN_ID","manual")
 git("config","user.name","github-actions[bot]")
 git("config","user.email","41898282+github-actions[bot]@users.noreply.github.com")
 git("checkout","-b",branch)
 for path,code in checked:
  target=ROOT/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(code,encoding="utf-8")
  git("add",path)
 git("diff","--cached","--check")
 git("commit","-m","911 agent: implement task (review required)")
 git("push","-u","origin",branch)
 summary=str(result.get("summary","Automated code proposal"))[:1000]
 body="911 AI-generated proposal. **Requires human review and successful Godot CI before merge.**\n\n"+summary
 if issue_number: body+="\n\nCloses #"+issue_number
 subprocess.run(["gh","pr","create","--base","main","--head",branch,"--title","911: AI proposal for inventory/UI task","--body",body],cwd=ROOT,check=True)
 out("PR created; not merged.")
if __name__=="__main__": main()
