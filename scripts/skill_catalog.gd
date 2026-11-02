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

static func skills_for_job(job_id: String) -> Array:
 if job_id=="Novice":return NOVICE.duplicate(true)
 if not FIRST_TIER_NAMES.has(job_id):return []
 var result: Array=[]
 var names: Array=FIRST_TIER_NAMES[job_id]
 for i in range(names.size()):
  var label_pair: Array=names[i]
  var skill_id: String=job_id+"_%02d" % (i+1)
  result.append({
   "id":skill_id,
   "th":str(label_pair[0]),
   "en":str(label_pair[1]),
   "type_th":str(DISPLAY_TYPES_TH[i]),
   "type_en":str(DISPLAY_TYPES_EN[i]),
   "desc_th":"ไอคอนต้นแบบสกิล "+str(label_pair[0])+" · ยังไม่เปิดใช้ท่าต่อสู้",
   "desc_en":"Skill icon concept: "+str(label_pair[1])+" · combat not available yet",
   "cooldown":"-","stamina":"-",
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
