#!/usr/bin/env python3
"""Zero-dependency regression gate: exact source IDs retained from old Godot code."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

def extract(source: str, marker: str, opener: str):
    pos = source.index(marker)
    start = source.index(opener, pos)
    closer = "}" if opener == "{" else "]"
    level = 0
    quoted = False
    escaped = False
    for i in range(start, len(source)):
        ch = source[i]
        if escaped:
            escaped = False
            continue
        if ch == "\\" and quoted:
            escaped = True
            continue
        if ch == '"':
            quoted = not quoted
            continue
        if not quoted:
            if ch == opener:
                level += 1
            elif ch == closer:
                level -= 1
                if level == 0:
                    return json.loads(source[start:i+1])
    raise ValueError("Unclosed Godot constant: " + marker)

store = (ROOT / "scripts/store.gd").read_text()
shop = (ROOT / "scripts/shop_catalog.gd").read_text()
jobs = (ROOT / "scripts/job_catalog.gd").read_text()
skills = (ROOT / "scripts/skill_catalog.gd").read_text()
catalog = json.loads((ROOT / "unity/Assets/LEOM/Resources/LeomLegacyCatalog.json").read_text())
source_items = extract(store, "const DATA =", "{")
source_offers = extract(shop, "const OFFERS:", "[")
source_jobs = extract(jobs, "const JOBS =", "[")
source_novice = extract(skills, "const NOVICE:", "[")
first = extract(skills, "const FIRST_TIER_NAMES:", "{")
second = extract(skills, "const SECOND_TIER_NAMES:", "{")
passives = extract(skills, "const PASSIVE_BY_JOB:", "{")
buffs = extract(skills, "const TIMED_BUFF_BY_JOB:", "{")
assert catalog["schemaVersion"] == 1
items = {item["id"]:item for item in catalog["items"]}
offers = {offer["id"]:offer for offer in catalog["offers"]}
job_defs = {job["id"]:job for job in catalog["jobs"]}
skill_defs = {skill["id"]:skill for skill in catalog["skills"]}
assert len(items) == len(source_items) == 31
assert len(offers) == len(source_offers) == 21
assert len(job_defs) == len(source_jobs) == 13
assert len(skill_defs) == 171
for id, source in source_items.items():
    assert id in items, id
    for source_name, dest_name in (("name","name"),("kind","kind"),("slot","slot")):
        assert items[id][dest_name] == source.get(source_name, ""), (id, source_name)
for source in source_offers:
    assert offers[source["id"]] == source, source["id"]
for source in source_jobs:
    dest = job_defs[source["id"]]
    assert dest["nameTh"] == source["th"] and dest["nameEn"] == source["en"]
    assert dest["path"] == source["path"] and dest["tier"] == source["tier"]
for skill in source_novice:
    dest = skill_defs[skill["id"]]
    assert dest["nameTh"] == skill["th"] and dest["nameEn"] == skill["en"]
    assert dest["job"] == "Novice" and dest["kind"] == skill["kind"]
for id, names in {**first,**second}.items():
    assert len(names) == 14, id
    for i, names_pair in enumerate(names):
        key = f"{id}_{i+1:02d}"
        expected_kind = "passive" if i in (7,9,10,11) else "timed_buff" if i in (3,12) else "active"
        skill = skill_defs[key]
        assert skill["kind"] == expected_kind and skill["job"] == id, key
        if expected_kind == "passive":
            n = passives[id][(7,9,10,11).index(i)]
            assert (skill["nameTh"],skill["nameEn"],skill["statKey"],skill["statAmount"]) == tuple(n)
        elif expected_kind == "timed_buff":
            n = buffs[id][(3,12).index(i)]
            assert (skill["nameTh"],skill["nameEn"],skill["statKey"],skill["statAmount"],skill["durationSeconds"]) == tuple(n)
        else:
            assert (skill["nameTh"],skill["nameEn"]) == tuple(names_pair)
assert len(skill_defs) == 3+14*12

required = [
    "unity/Assets/LEOM/Scripts/Runtime/LeomRpgService.cs",
    "unity/Assets/LEOM/Scripts/Runtime/LeomAmount.cs",
    "unity/Assets/LEOM/Scripts/Runtime/LeomRpgSave.cs",
    "unity/Assets/LEOM/Scripts/Runtime/LeomGameHUD.cs",
    "unity/Assets/LEOM/Scripts/Runtime/LeomTouchGamepad.cs",
    "unity/Assets/LEOM/Scripts/Editor/LeomProceduralScene.cs",
    "unity/Assets/LEOM/Scripts/Editor/BuildPrototypeScene.cs",
]
assert all((ROOT / p).is_file() for p in required)
builder = (ROOT/"unity/Assets/LEOM/Scripts/Editor/BuildPrototypeScene.cs").read_text()
assert "LeomProceduralScene.Build()" in builder
assert "LeomProceduralScene.CreateHumanoid" in builder
assert "AddComponent<LeomRpgService>" in builder
assert "AddComponent<LeomGameHUD>" in builder
assert "AddComponent<LeomTouchGamepad>" in builder

# The user explicitly instructed that original character/map assets stay out.
for p in (ROOT/"unity/Assets/LEOM").rglob("*"):
    if p.is_file():
        assert p.suffix.lower() not in {".fbx", ".glb", ".gltf", ".blend"}, p

print("PASS: 31 item IDs, 21 offers, 13 jobs and all 171 skill IDs/names/kinds.")
print("PASS: temporary geometry, core service, UI and touch controls present; no original model/map imports.")
print("NOTE: This is a data/schema regression gate, NOT a Unity Editor compile or WebGL play test.")
