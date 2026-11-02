extends RefCounted
## Stable profession catalog shared by the character view, Skill UI and GM
## local playtest. Tier 1 -> Tier 2 is ONE progression path, not 12 unrelated
## professions. These are labels and EMPTY skill slots, not implemented skills.
## NOTE: For local GM testing only; no client-side GM switch is server auth.
const JOBS = [
 {"id":"Novice","th":"อาชีพเริ่มต้น","en":"Novice","path":"Unchosen","path_th":"ยังไม่เลือกสาย","tier":0},
 {"id":"earth_1","th":"นักสู้พิภพ","en":"Earth Fighter","path":"earth","path_th":"สายหมัด","tier":1},
 {"id":"wind_1","th":"จอมวายุ","en":"Wind Master","path":"wind","path_th":"สายลม","tier":1},
 {"id":"water_1","th":"จอมวารี","en":"Water Master","path":"water","path_th":"สายน้ำ","tier":1},
 {"id":"fire_1","th":"จอมเพลิง","en":"Flame Master","path":"fire","path_th":"สายไฟ","tier":1},
 {"id":"lightning_1","th":"จอมอัสนี","en":"Thunder Master","path":"lightning","path_th":"สายสายฟ้า","tier":1},
 {"id":"wood_1","th":"จอมพฤกษา","en":"Forest Master","path":"wood","path_th":"สายพฤกษา","tier":1},
 {"id":"earth_2","th":"จอมหมัดภูผา","en":"Mountain Fist Master","path":"earth","path_th":"สายหมัด","tier":2},
 {"id":"wind_2","th":"จ้าวพายุ","en":"Storm Lord","path":"wind","path_th":"สายลม","tier":2},
 {"id":"water_2","th":"จ้าวสมุทร","en":"Ocean Lord","path":"water","path_th":"สายน้ำ","tier":2},
 {"id":"fire_2","th":"จ้าวอัคคี","en":"Inferno Lord","path":"fire","path_th":"สายไฟ","tier":2},
 {"id":"lightning_2","th":"จ้าวสายฟ้า","en":"Lightning Lord","path":"lightning","path_th":"สายสายฟ้า","tier":2},
 {"id":"wood_2","th":"จ้าวไพร","en":"Forest Lord","path":"wood","path_th":"สายพฤกษา","tier":2}
]

static func info(job_id: String) -> Dictionary:
 for item in JOBS:
  if str(item["id"])==job_id or str(item["th"])==job_id or str(item["en"])==job_id:
   return item.duplicate(true)
 return {}

static func tier_one(path: String) -> Dictionary:
 for item in JOBS:
  if int(item["tier"])==1 and str(item["path"])==path:
   return item.duplicate(true)
 return {}

static func translated(item: Dictionary,locale: String) -> String:
 return str(item.get("en" if locale=="en" else "th","Novice"))
