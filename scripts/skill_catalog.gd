extends RefCounted
## Skill art/data registry. Separate from JobCatalog so all 6 elemental
## career paths and both stages can later receive their OWN approved icons.
## Stage 1 includes only Novice's three genuine independent PNGs.
## Presentation values here are design data; gameplay casting/animations
## must be implemented and validated separately.
const NOVICE: Array = [
 {"id":"novice_slash","th":"คมศาสตรา","en":"First Strike",
  "type_th":"โจมตี","type_en":"Attack","desc_th":"โจมตีเป้าหมายด้านหน้าด้วยอาวุธ",
  "desc_en":"Strike a target in front with your weapon.",
  "cooldown":"0.8s","stamina":"0","icon":"res://assets/ui/skills/novice_slash.png"},
 {"id":"novice_rush","th":"พุ่งจู่โจม","en":"Azure Rush",
  "type_th":"เคลื่อนที่","type_en":"Mobility","desc_th":"พุ่งเข้าหาเป้าหมายอย่างรวดเร็ว",
  "desc_en":"Rush quickly toward your target.",
  "cooldown":"3.0s","stamina":"20","icon":"res://assets/ui/skills/novice_rush.png"},
 {"id":"novice_guard","th":"เกราะคุ้มกัน","en":"Radiant Ward",
  "type_th":"ป้องกัน","type_en":"Defense","desc_th":"เสริมการป้องกันระยะสั้น",
  "desc_en":"Gain brief defensive protection.",
  "cooldown":"10.0s","stamina":"15","icon":"res://assets/ui/skills/novice_guard.png"}
]

static func skills_for_job(job_id: String) -> Array:
 if job_id=="Novice":return NOVICE.duplicate(true)
 # Other professions remain staged; do not reuse Novice icons or invent
 # icons/abilities in the 14-slot grids for unapproved professions.
 return []

static func info(skill_id: String) -> Dictionary:
 for item in NOVICE:
  if str(item.get("id",""))==skill_id:return item.duplicate(true)
 return {}

static func belongs_to_job(job_id: String,skill_id: String) -> bool:
 for item in skills_for_job(job_id):
  if str(item.get("id",""))==skill_id:return true
 return false
