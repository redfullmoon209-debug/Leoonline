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
  "kind":"active","cooldown":"0.8s","stamina":"0","icon":"res://assets/ui/skills/novice_slash.png"},
 {"id":"novice_rush","th":"พุ่งจู่โจม","en":"Azure Rush",
  "type_th":"เคลื่อนที่","type_en":"Mobility","desc_th":"พุ่งเข้าหาเป้าหมายอย่างรวดเร็ว",
  "desc_en":"Rush quickly toward your target.",
  "kind":"active","cooldown":"3.0s","stamina":"20","icon":"res://assets/ui/skills/novice_rush.png"},
 {"id":"novice_guard","th":"เกราะคุ้มกัน","en":"Radiant Ward",
  "type_th":"ป้องกัน","type_en":"Defense","desc_th":"เสริมการป้องกันระยะสั้น",
  "desc_en":"Gain brief defensive protection.",
  "kind":"active","cooldown":"10.0s","stamina":"15","icon":"res://assets/ui/skills/novice_guard.png"}
]

# Real independent PNGs are generated for each named first-tier skill
# before Godot imports the project. These are authored UI catalog entries,
# NOT battle actions or completed animations.
const FIRST_TIER_NAMES: Dictionary = {
 "earth_1": [
  ["หมัดพิภพ","Earth Fist"],
  ["ถล่มผา","Rockbreaker"],
  ["กระแทกปฐพี","Terra Impact"],
  ["โล่หิน","Stoneguard"],
  ["พุ่งหมัด","Charging Fist"],
  ["แรงสะเทือน","Faultwave"],
  ["หมัดดาวตก","Meteor Fist"],
  ["ยืนหยัดภูผา","Mountain Stance"],
  ["หินผ่า","Stone Split"],
  ["กำปั้นเหล็ก","Iron Knuckle"],
  ["หมัดทลาย","Ruin Punch"],
  ["คลื่นแรงโน้มถ่วง","Gravity Pulse"],
  ["จิตพิภพ","Earth Spirit"],
  ["แผ่นดินสะท้าน","World Shaker"]
 ],
 "wind_1": [
  ["คมวายุ","Wind Edge"],
  ["ฟันลมคู่","Twin Gale"],
  ["ร่ายพายุ","Tempest Waltz"],
  ["พุ่งลม","Gale Dash"],
  ["วงจักรวายุ","Wind Cyclone"],
  ["ปัดป้องสายลม","Wind Parry"],
  ["เงาวายุ","Gale Shadow"],
  ["พายุดาบ","Blade Storm"],
  ["ลมเฉือน","Air Cutter"],
  ["คมดาบหมุน","Spinning Blades"],
  ["ซัดปีกลม","Wing Gust"],
  ["ก้าวพริบตา","Swift Step"],
  ["พันธนาการวายุ","Wind Snare"],
  ["แหวกฟ้า","Sky Splitter"]
 ],
 "water_1": [
  ["สายน้ำชำระ","Purifying Stream"],
  ["คลื่นวารี","Water Surge"],
  ["ลูกแก้วสมุทร","Ocean Orb"],
  ["ม่านน้ำ","Aqua Veil"],
  ["พุ่งธารา","Torrent Rush"],
  ["เกลียวน้ำ","Water Spiral"],
  ["หยาดรักษา","Healing Drop"],
  ["หอกน้ำแข็ง","Ice Spear"],
  ["น้ำวน","Maelstrom"],
  ["กำแพงวารี","Water Wall"],
  ["คลื่นลึก","Deep Tide"],
  ["จิตวารี","Water Spirit"],
  ["ธาราเยือกแข็ง","Frozen River"],
  ["พายุสมุทร","Ocean Tempest"]
 ],
 "fire_1": [
  ["ดาบเพลิง","Flame Blade"],
  ["ฟันอัคคี","Inferno Slash"],
  ["พุ่งไฟ","Flame Charge"],
  ["เกราะเพลิง","Flame Guard"],
  ["คลื่นลาวา","Lava Wave"],
  ["ระเบิดอัคคี","Fireburst"],
  ["เปลวสะบั้น","Blazing Sever"],
  ["อุกกาบาต","Meteor Crash"],
  ["ทางเพลิง","Fire Trail"],
  ["ดาบหลอม","Molten Sword"],
  ["ปีกอัคคี","Ember Wings"],
  ["พลังลุกโชน","Burning Spirit"],
  ["วงแหวนเพลิง","Firestorm Ring"],
  ["มหาวินาศ","Inferno Cataclysm"]
 ],
 "lightning_1": [
  ["ยิงสายฟ้า","Thunder Shot"],
  ["กระสุนคู่","Twin Sparks"],
  ["อัสนีต่อเนื่อง","Volt Barrage"],
  ["ทะลวงสายฟ้า","Lightning Pierce"],
  ["เคลื่อนพริบตา","Flashstep"],
  ["ฟ้าผ่า","Thunderstrike"],
  ["ระเบิดไฟฟ้า","Electric Burst"],
  ["เกราะกระแส","Volt Shield"],
  ["ยิงประจุ","Charged Shot"],
  ["โซ่สายฟ้า","Chain Lightning"],
  ["พายุปืนคู่","Twin Gun Storm"],
  ["ลำแสงอัสนี","Volt Beam"],
  ["สปีดสายฟ้า","Thunder Speed"],
  ["อสนีบาตบรรลัย","Thunder Ruin"]
 ],
 "wood_1": [
  ["เถาวัลย์พิฆาต","Vine Lash"],
  ["เมล็ดแห่งชีวิต","Life Seed"],
  ["ผนึกพฤกษา","Forest Seal"],
  ["ใบมีดไพร","Leaf Blade"],
  ["หนามราก","Root Thorns"],
  ["รักษาธรรมชาติ","Nature Heal"],
  ["ม่านป่า","Forest Veil"],
  ["พุ่งเถาวัลย์","Vine Rush"],
  ["เกราะไม้","Bark Guard"],
  ["สังเคราะห์ชีวิต","Life Bloom"],
  ["ต้นไม้พิทักษ์","Guardian Tree"],
  ["ละอองเกสร","Pollen Cloud"],
  ["ผืนป่าเรียกหา","Forest Call"],
  ["อวตารพฤกษา","Forest Avatar"]
 ]
}
const DISPLAY_TYPES_TH: Array = ["โจมตี","โจมตี","โจมตี","ป้องกัน","เคลื่อนที่","โจมตี","โจมตี","เสริมพลัง","โจมตี","โจมตี","สนับสนุน","เสริมพลัง","ควบคุม","ท่าไม้ตาย"]
const DISPLAY_TYPES_EN: Array = ["Attack","Attack","Attack","Defense","Mobility","Attack","Attack","Buff","Attack","Attack","Support","Buff","Control","Ultimate"]

# Explicit, server-independent skill categories. Passive upgrades NEVER occupy
# a castable slot. Timed buffs are castable, expire after 1 to 3 minutes.
const PASSIVE_LEVEL_CAP:int=10
const PASSIVE_BY_JOB:Dictionary={
 "earth_1":[["กำลังพิภพ","Earth Might","strength",2],["กายาหินผา","Stone Body","vitality",2]],
 "wind_1":[["ความคล่องวายุ","Wind Agility","agility",2],["สายตาวายุ","Wind Precision","dexterity",2]],
 "water_1":[["จิตวารี","Water Wisdom","intelligence",2],["ชีพจรธารา","Flowing Vitality","vitality",2]],
 "fire_1":[["พลังอัคคี","Flame Strength","strength",2],["กายาเพลิง","Flame Body","vitality",2]],
 "lightning_1":[["เนตรอัสนี","Thunder Precision","dexterity",2],["กายาสายฟ้า","Lightning Agility","agility",2]],
 "wood_1":[["ปัญญาพฤกษา","Forest Wisdom","intelligence",2],["ชีวาพฤกษา","Forest Vitality","vitality",2]]
}
const TIMED_BUFF_BY_JOB:Dictionary={
 "earth_1":["จิตพิภพ","Spirit of Earth","vitality",5,180],
 "wind_1":["พรแห่งวายุ","Blessing of Wind","agility",5,120],
 "water_1":["พรแห่งวารี","Blessing of Water","intelligence",5,180],
 "fire_1":["เปลวอัคคี","Flame Power","strength",5,120],
 "lightning_1":["สปีดสายฟ้า","Thunder Speed","agility",5,60],
 "wood_1":["พรแห่งพฤกษา","Nature's Blessing","vitality",5,180]
}
const STAT_LABEL:Dictionary={"strength":"STR","vitality":"VIT","agility":"AGI","intelligence":"INT","dexterity":"DEX","luck":"LUK"}

static func skills_for_job(job_id: String) -> Array:
 if job_id=="Novice":return NOVICE.duplicate(true)
 if not FIRST_TIER_NAMES.has(job_id):return []
 var result: Array=[]
 var names: Array=FIRST_TIER_NAMES[job_id]
 for i in range(names.size()):
  var label_pair: Array=names[i]
  var skill_id: String=job_id+"_%02d" % (i+1)
  var kind:String="active"
  var name_th:String=str(label_pair[0])
  var name_en:String=str(label_pair[1])
  var type_th:String=str(DISPLAY_TYPES_TH[i])
  var type_en:String=str(DISPLAY_TYPES_EN[i])
  var desc_th:String="โจมตี/ความสามารถกดใช้ · ระบบต่อสู้ยังไม่พร้อม"
  var desc_en:String="Activated ability · gameplay combat is not available yet"
  var attr:String=""
  var stat_amount:int=0
  var duration:int=0
  if i==7 or i==11:
   kind="passive"
   var passive_info:Array=PASSIVE_BY_JOB[job_id][0 if i==7 else 1]
   name_th=str(passive_info[0])
   name_en=str(passive_info[1])
   attr=str(passive_info[2])
   stat_amount=int(passive_info[3])
   type_th="สกิลติดตัว (Passive)"
   type_en="Permanent passive"
   desc_th="อัปเกรดแล้วเพิ่ม "+str(STAT_LABEL[attr])+" +"+str(stat_amount)+" ต่อระดับ · ไม่ต้องกดใช้"
   desc_en="Upgrading grants "+str(STAT_LABEL[attr])+" +"+str(stat_amount)+" per level permanently; cannot be cast"
  elif i==12:
   kind="timed_buff"
   var buff_info:Array=TIMED_BUFF_BY_JOB[job_id]
   name_th=str(buff_info[0])
   name_en=str(buff_info[1])
   attr=str(buff_info[2])
   stat_amount=int(buff_info[3])
   duration=int(buff_info[4])
   type_th="บัฟกดใช้ มีระยะเวลา"
   type_en="Timed active buff"
   desc_th="กดใช้เพิ่ม "+str(STAT_LABEL[attr])+" +"+str(stat_amount)+" นาน "+str(duration/60)+" นาที"
   desc_en="Cast to gain "+str(STAT_LABEL[attr])+" +"+str(stat_amount)+" for "+str(duration/60)+" minute(s)"
  result.append({
   "id":skill_id,"th":name_th,"en":name_en,
   "kind":kind,"type_th":type_th,"type_en":type_en,
   "desc_th":desc_th,"desc_en":desc_en,
   "stat_key":attr,"stat_amount":stat_amount,
   "duration_seconds":duration,"max_level":PASSIVE_LEVEL_CAP if kind=="passive" else 1,
   "cooldown":"ไม่ใช้" if kind=="passive" else ("ตามระยะเวลาบัฟ" if kind=="timed_buff" else "-"),
   "stamina":"0" if kind=="passive" else "-",
   "icon":"res://assets/ui/skills/"+skill_id+".png"
  })
 return result

static func info(skill_id: String) -> Dictionary:
 for item in NOVICE:
  if str(item.get("id",""))==skill_id:return item.duplicate(true)
 for job_id in FIRST_TIER_NAMES.keys():
  if skill_id.begins_with(str(job_id)+"_"):
   for skill in skills_for_job(str(job_id)):
    if str(skill["id"])==skill_id:return skill
 return {}

static func belongs_to_job(job_id: String,skill_id: String) -> bool:
 for item in skills_for_job(job_id):
  if str(item.get("id",""))==skill_id:return true
 return false

static func skill_kind(skill_id:String) -> String:
 var item:Dictionary=info(skill_id)
 return str(item.get("kind","")) if not item.is_empty() else ""

static func is_equippable(job_id:String,skill_id:String) -> bool:
 if not belongs_to_job(job_id,skill_id):return false
 var kind:String=skill_kind(skill_id)
 return kind=="active" or kind=="timed_buff"

static func is_passive(job_id:String,skill_id:String) -> bool:
 return belongs_to_job(job_id,skill_id) and skill_kind(skill_id)=="passive"

