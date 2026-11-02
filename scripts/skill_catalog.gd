extends RefCounted
## Skill art/data registry. Separate from JobCatalog so all 6 elemental
## career paths and both stages can later receive their OWN approved icons.
## Novice and six first-tier paths have approved standalone PNGs; tier-2 art pending.
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
# Tier-2 names and rules are test-ready; independent approved PNGs for them
# have NOT been created, so the existing empty icon slots remain blank.
const SECOND_TIER_NAMES:Dictionary={
 "earth_2":[
  ["หมัดราชันภูผา","Mountain Sovereign Fist"],
  ["หมัดแยกแผ่นดิน","Continental Rupture"],
  ["หมัดหินดาวตก","Meteor Knuckle"],
  ["คุ้มครองภูผา","Mountain Ward"],
  ["พุ่งกระแทกขุนเขา","Mountain Charge"],
  ["คลื่นหมัดสั่นสะเทือน","Seismic Fist"],
  ["หัตถ์ทลายปราการ","Fortress Breaker"],
  ["จิตภูผา","Mountain Spirit"],
  ["หมัดสะเทือนจักรวาล","Cosmic Impact"],
  ["แก่นศิลากำลัง","Stone Strength"],
  ["เลือดนักสู้","Fighter Vitality"],
  ["กายาเหล็กไหล","Iron Body"],
  ["ลมหายใจภูผา","Mountain Breath"],
  ["หมัดทลายโลก","Worldbreaker Fist"]
 ],
 "wind_2":[
  ["พัดวายุจันทรา","Moonwind Fan"],
  ["ใบพัดพิฆาต","Fan Cutter"],
  ["พายุทมิฬ","Dark Tempest"],
  ["ม่านสายลม","Wind Shield"],
  ["ปีกลมทะยาน","Skyward Gust"],
  ["พัดเวียนสังหาร","Cyclone Fan"],
  ["แหวกอากาศ","Air Split"],
  ["จิตแห่งพายุ","Storm Soul"],
  ["พัดจักรวาล","Celestial Fan"],
  ["กระดูกวายุ","Windbone"],
  ["ก้าวสายลม","Gale Reflex"],
  ["เนตรพายุ","Storm Eyes"],
  ["ลมเสริมกำลัง","Blessing Breeze"],
  ["มหาพายุดารา","Celestial Typhoon"]
 ],
 "water_2":[
  ["หอกสมุทรพิฆาต","Ocean Spear"],
  ["หอกคลื่นลึก","Deep Wave Spear"],
  ["แทงวารีสะบั้น","Tidal Pierce"],
  ["ม่านสมุทร","Ocean Ward"],
  ["พุ่งหอกสายน้ำ","Torrent Lance"],
  ["เกลียวหอกน้ำวน","Maelstrom Lance"],
  ["คลื่นพิโรธ","Wrath of Tides"],
  ["จิตมหาสมุทร","Ocean Spirit"],
  ["หอกน้ำแข็งแหลม","Glacial Spear"],
  ["สติธารา","Flowing Focus"],
  ["ชีพจรสมุทร","Ocean Vitality"],
  ["มือหอกคมกริบ","Spear Mastery"],
  ["พรเจ้าสมุทร","Ocean Blessing"],
  ["มหาสมุทรกลืนฟ้า","Ocean Devour"]
 ],
 "fire_2":[
  ["ดาบอัคคีราชัน","Inferno King's Blade"],
  ["ดาบผ่าภูเขาไฟ","Volcano Cleave"],
  ["คมเพลิงสังหาร","Firestorm Sever"],
  ["เกราะเทพอัคคี","Fire Lord Guard"],
  ["พุ่งดาบทะลวง","Infernal Charge"],
  ["ดาบลาวากัมปนาท","Lava Tremor"],
  ["ฟาดดาบสุริยัน","Solar Greatsword"],
  ["จิตจ้าวอัคคี","Inferno Soul"],
  ["เพลิงกัลป์","Apocalyptic Flame"],
  ["กำลังสุริยา","Solar Might"],
  ["โลหิตเพลิง","Blazing Vitality"],
  ["ความไวอัคคี","Flame Reflex"],
  ["พรเปลวเพลิง","Fire Blessing"],
  ["ดาบวันสิ้นโลก","Doomsday Greatsword"]
 ],
 "lightning_2":[
  ["กระสุนเทพสายฟ้า","Lightning Lord Shot"],
  ["ปืนอัสนีพิฆาต","Golden Thunder Gun"],
  ["ลำแสงอัสนี","Volt Beam"],
  ["เกราะอัสนี","Lightning Guard"],
  ["กระสุนพายุ","Storm Bullet"],
  ["ยิงทะลวงฟ้า","Heaven Pierce"],
  ["ปืนสะบั้นประจุ","Volt Discharge"],
  ["จิตเทพอัสนี","Thunder Spirit"],
  ["ยิงสายฟ้าสองชั้น","Twin Volt Burst"],
  ["เนตรกระสุน","Marksman's Eye"],
  ["ฝีเท้าสายฟ้า","Lightning Reflex"],
  ["โชคแห่งอัสนี","Thunder Fortune"],
  ["พรเทพสายฟ้า","Divine Thunder Blessing"],
  ["อัสนีบาตราชัน","King's Thunderbolt"]
 ],
 "wood_2":[
  ["แส้พฤกษาพิฆาต","Forest Whip"],
  ["แส้เถาวัลย์สังหาร","Vine Judgment"],
  ["รากไม้กลืนดิน","Root Devour"],
  ["ม่านป่าโบราณ","Ancient Forest Guard"],
  ["แส้หนามทะลวง","Thorn Lash"],
  ["พฤกษาร้อยสาย","Hundred Vines"],
  ["ดอกไม้มรณะ","Death Blossom"],
  ["จิตเจ้าป่า","Forest Spirit"],
  ["แส้พันธนาการ","Entangling Whip"],
  ["ปัญญาไพร","Forest Wisdom"],
  ["กายาไม้พฤกษา","Wooden Body"],
  ["มือแส้พริ้วไหว","Whip Agility"],
  ["พรพิทักษ์ไพร","Guardian Grove"],
  ["มหาพฤกษาโลกา","World Tree's Wrath"]
 ]
}

const DISPLAY_TYPES_TH: Array = ["โจมตี","โจมตี","โจมตี","ป้องกัน","เคลื่อนที่","โจมตี","โจมตี","เสริมพลัง","โจมตี","โจมตี","สนับสนุน","เสริมพลัง","ควบคุม","ท่าไม้ตาย"]
const DISPLAY_TYPES_EN: Array = ["Attack","Attack","Attack","Defense","Mobility","Attack","Attack","Buff","Attack","Attack","Support","Buff","Control","Ultimate"]

# Explicit, server-independent skill categories. Passive upgrades NEVER occupy
# a castable slot. Timed buffs are castable, expire after 1 to 3 minutes.
const PASSIVE_LEVEL_CAP:int=10
const PASSIVE_INDICES:Array=[7,9,10,11] # existing 8 and 12 remain passives
const TIMED_BUFF_INDICES:Array=[3,12] # existing 13 remains a timed buff
const PASSIVE_BY_JOB:Dictionary={
 "earth_1":[["กำลังพิภพ","Earth Might","strength",2],["กายาหินผา","Stone Body","vitality",2],["ก้าวย่างพิภพ","Earth Agility","agility",2],["หมัดแม่นยำ","Knuckle Precision","dexterity",2]],
 "wind_1":[["ความคล่องวายุ","Wind Agility","agility",2],["สายตาวายุ","Wind Precision","dexterity",2],["แรงดาบวายุ","Gale Might","strength",2],["พรลมโชคดี","Fortunate Wind","luck",2]],
 "water_1":[["จิตวารี","Water Wisdom","intelligence",2],["ชีพจรธารา","Flowing Vitality","vitality",2],["สัมผัสสายน้ำ","Tide Dexterity","dexterity",2],["โชคแห่งวารี","Tide Fortune","luck",2]],
 "fire_1":[["พลังอัคคี","Flame Strength","strength",2],["กายาเพลิง","Flame Body","vitality",2],["ก้าวเพลิง","Ember Agility","agility",2],["ดาบเพลิงชำนาญ","Flame Dexterity","dexterity",2]],
 "lightning_1":[["เนตรอัสนี","Thunder Precision","dexterity",2],["กายาสายฟ้า","Lightning Agility","agility",2],["แรงกระสุนอัสนี","Thunder Strength","strength",2],["ลาภสายฟ้า","Spark Fortune","luck",2]],
 "wood_1":[["ปัญญาพฤกษา","Forest Wisdom","intelligence",2],["ชีวาพฤกษา","Forest Vitality","vitality",2],["ก้าวแห่งไพร","Forest Agility","agility",2],["โชคแห่งพฤกษา","Forest Luck","luck",2]],
 "earth_2":[["จิตภูผา","Mountain Spirit","strength",2],["กายาเหล็กไหล","Iron Body","vitality",2],["แก่นหมัดภูผา","Mountain Precision","dexterity",2],["ก้าวขุนเขา","Mountain Agility","agility",2]],
 "wind_2":[["จิตแห่งพายุ","Storm Soul","intelligence",2],["เนตรพายุ","Storm Eyes","dexterity",2],["ก้าวสายลม","Gale Reflex","agility",2],["โชคจ้าวพายุ","Storm Fortune","luck",2]],
 "water_2":[["จิตมหาสมุทร","Ocean Spirit","intelligence",2],["ชีพจรสมุทร","Ocean Vitality","vitality",2],["มือหอกสมุทร","Ocean Spearmanship","dexterity",2],["เมตตาวารี","Water Luck","luck",2]],
 "fire_2":[["จิตจ้าวอัคคี","Inferno Soul","strength",2],["โลหิตเพลิง","Blazing Vitality","vitality",2],["ความไวอัคคี","Flame Reflex","agility",2],["ดาบอัคคีชำนาญ","Inferno Dexterity","dexterity",2]],
 "lightning_2":[["จิตเทพอัสนี","Thunder Spirit","strength",2],["เนตรกระสุน","Marksman's Eye","dexterity",2],["ฝีเท้าสายฟ้า","Lightning Reflex","agility",2],["โชคแห่งอัสนี","Thunder Fortune","luck",2]],
 "wood_2":[["จิตเจ้าป่า","Forest Spirit","intelligence",2],["กายาไม้พฤกษา","Wooden Body","vitality",2],["มือแส้พริ้วไหว","Whip Agility","agility",2],["โชคแห่งไพร","Forest Fortune","luck",2]]
}
const TIMED_BUFF_BY_JOB:Dictionary={
 "earth_1":[["โล่หิน","Stoneguard","vitality",5,120],["จิตพิภพ","Spirit of Earth","strength",5,180]],
 "wind_1":[["วายุคุ้มกาย","Wind Veil","dexterity",5,120],["พรแห่งวายุ","Blessing of Wind","agility",5,120]],
 "water_1":[["ม่านน้ำ","Aqua Veil","vitality",5,120],["พรแห่งวารี","Blessing of Water","intelligence",5,180]],
 "fire_1":[["เกราะเพลิง","Flame Guard","vitality",5,120],["เปลวอัคคี","Flame Power","strength",5,120]],
 "lightning_1":[["เกราะกระแส","Volt Shield","vitality",5,120],["สปีดสายฟ้า","Thunder Speed","agility",5,60]],
 "wood_1":[["ม่านพฤกษา","Bark Ward","vitality",5,120],["พรแห่งพฤกษา","Nature's Blessing","intelligence",5,180]],
 "earth_2":[["คุ้มครองภูผา","Mountain Ward","vitality",7,120],["ลมหายใจภูผา","Mountain Breath","strength",7,180]],
 "wind_2":[["ม่านสายลม","Wind Shield","vitality",7,120],["ลมเสริมกำลัง","Blessing Breeze","agility",7,180]],
 "water_2":[["ม่านสมุทร","Ocean Ward","vitality",7,120],["พรเจ้าสมุทร","Ocean Blessing","intelligence",7,180]],
 "fire_2":[["เกราะเทพอัคคี","Fire Lord Guard","vitality",7,120],["พรเปลวเพลิง","Fire Blessing","strength",7,180]],
 "lightning_2":[["เกราะอัสนี","Lightning Guard","vitality",7,120],["พรเทพสายฟ้า","Divine Thunder Blessing","dexterity",7,180]],
 "wood_2":[["ม่านป่าโบราณ","Ancient Forest Guard","vitality",7,120],["พรพิทักษ์ไพร","Guardian Grove","intelligence",7,180]]
}
const STAT_LABEL:Dictionary={"strength":"STR","vitality":"VIT","agility":"AGI","intelligence":"INT","dexterity":"DEX","luck":"LUK"}

static func skills_for_job(job_id: String) -> Array:
 if job_id=="Novice":return NOVICE.duplicate(true)
 if not FIRST_TIER_NAMES.has(job_id) and not SECOND_TIER_NAMES.has(job_id):return []
 var result: Array=[]
 var names: Array=FIRST_TIER_NAMES[job_id] if FIRST_TIER_NAMES.has(job_id) else SECOND_TIER_NAMES[job_id]
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
  if PASSIVE_INDICES.has(i):
   kind="passive"
   var passive_info:Array=PASSIVE_BY_JOB[job_id][PASSIVE_INDICES.find(i)]
   name_th=str(passive_info[0])
   name_en=str(passive_info[1])
   attr=str(passive_info[2])
   stat_amount=int(passive_info[3])
   type_th="สกิลติดตัว (Passive)"
   type_en="Permanent passive"
   desc_th="อัปเกรดแล้วเพิ่ม "+str(STAT_LABEL[attr])+" +"+str(stat_amount)+" ต่อระดับ · ไม่ต้องกดใช้"
   desc_en="Upgrading grants "+str(STAT_LABEL[attr])+" +"+str(stat_amount)+" per level permanently; cannot be cast"
  elif TIMED_BUFF_INDICES.has(i):
   kind="timed_buff"
   var buff_info:Array=TIMED_BUFF_BY_JOB[job_id][TIMED_BUFF_INDICES.find(i)]
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
   # A blank Tier-2 icon is intentional until independent approved art exists.
   "icon":"res://assets/ui/skills/"+skill_id+".png" if FIRST_TIER_NAMES.has(job_id) else ""
  })
 return result

static func info(skill_id: String) -> Dictionary:
 for item in NOVICE:
  if str(item.get("id",""))==skill_id:return item.duplicate(true)
 for job_id in FIRST_TIER_NAMES.keys()+SECOND_TIER_NAMES.keys():
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

