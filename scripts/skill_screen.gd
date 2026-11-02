extends Control
## Novice Skill screen uses original, independent PNGs for all skill cells.
## The large layout sections have FLAT burgundy fills and NO outlined
## NinePatch frames, nested gold lines, borders or screenshot crops.
## The preview anchor is intentionally empty until authored animations exist.
const ROOT = "res://assets/ui/red_matte/"
const INVENTORY = "res://assets/ui/inventory/"
const ButtonStyle = preload("res://scripts/ui_button_style.gd")
const JobCatalog = preload("res://scripts/job_catalog.gd")
const MAX_SLOTS := 14
const NOVICE_SLOTS := 3

var game_store: Node
var ui_font: Font
var locale: String = "th"
var preview_anchor: Control
var preview_buttons: Array[Button] = []
var skill_slots: Array[TextureButton] = []
var active_slots: Array[TextureButton] = []
var upgrade_button: Button
var next_job_tab: Button
var class_label: Label
var class_subtitle: Label
var future_label: Label
var current_skills_tab: Button
var exp_label: Label
var level_label: Label
var sp_label: Label
var gold_label: Label
var exp_bar: ProgressBar
var hint_label: Label
var slot_label: Label
var description_label: Label
var current_level_label: Label
var next_level_label: Label
var price_label: Label
var cost_label: Label
var page_label: Label
var slot_numbers: Array[Label] = []
var equipped_numbers: Array[Label] = []

func initialize(p_store: Node,p_font: Font,p_locale: String = "th") -> void:
 game_store=p_store
 ui_font=p_font
 locale="en" if p_locale=="en" else "th"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 _build()
 refresh()

func _tr(th: String,en: String) -> String:
 return en if locale=="en" else th

func _rect(node: Control,x: float,y: float,w: float,h: float) -> void:
 node.position=Vector2(x,y)
 node.size=Vector2(w,h)

func _png(folder: String,name: String) -> Texture2D:
 var path:String=folder+name+".png"
 return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _panel(name: String,parent: Node,x: float,y: float,w: float,h: float) -> ColorRect:
 # A visually clean, flat dark-maroon surface with ZERO painted lines.
 # The old inner_panel.png had TWO unwanted nested gold borders.
 # No NinePatch texture or additional decoration is used in Skill UI.
 var panel:=ColorRect.new()
 panel.name=name
 panel.color=Color(0.115,0.013,0.032,0.50) if name=="SkillPreviewFrame" else Color(0.10,0.008,0.024,0.20)
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(panel)
 _rect(panel,x,y,w,h)
 return panel

func _label(name: String,parent: Node,x: float,y: float,w: float,h: float,font_size: int = 18,gold: bool = true,align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var label:=Label.new()
 label.name=name
 label.horizontal_alignment=align
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.clip_text=true
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("#ffe1a1") if gold else Color("#f4e9df"))
 label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.75))
 label.add_theme_constant_override("shadow_offset_y",1)
 if ui_font!=null:label.add_theme_font_override("font",ui_font)
 parent.add_child(label)
 _rect(label,x,y,w,h)
 return label

func _image(name: String,parent: Node,x: float,y: float,w: float,h: float) -> TextureRect:
 var node:=TextureRect.new()
 node.name="Novice"+name
 node.texture=_png(INVENTORY,name)
 node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 _rect(node,x,y,w,h)
 return node

func _button(name: String,parent: Node,x:float,y:float,w:float,h:float,font_size:int=17) -> Button:
 var btn:=Button.new()
 btn.name=name
 btn.focus_mode=Control.FOCUS_NONE
 btn.mouse_filter=Control.MOUSE_FILTER_STOP
 ButtonStyle.apply(btn)
 btn.add_theme_font_size_override("font_size",font_size)
 if ui_font!=null:btn.add_theme_font_override("font",ui_font)
 parent.add_child(btn)
 _rect(btn,x,y,w,h)
 return btn

func _slot(parent: Node,name: String,x:float,y:float,size_px:float,locked:bool) -> TextureButton:
 var cell:=TextureButton.new()
 cell.name=name
 cell.mouse_filter=Control.MOUSE_FILTER_STOP
 cell.focus_mode=Control.FOCUS_NONE
 cell.ignore_texture_size=true
 cell.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 cell.texture_normal=_png(ROOT,"slot_locked" if locked else "slot_empty")
 cell.texture_hover=cell.texture_normal
 cell.texture_pressed=cell.texture_normal
 cell.texture_disabled=cell.texture_normal
 cell.disabled=locked
 cell.set_meta("reserved",locked)
 parent.add_child(cell)
 _rect(cell,x,y,size_px,size_px)
 cell.custom_minimum_size=Vector2(size_px,size_px)
 if not locked:
  ButtonStyle.image_overlay(cell)
  cell.pressed.connect(_empty_skill_selected.bind(name))
 return cell

func _empty_skill_selected(_name: String) -> void:
 # This stage has deliberately NO skill icons, stats, or fake attack effects.
 hint_label.text=_tr("รอเพิ่มรูป PNG และข้อมูลสกิลจริง","Awaiting real skill PNGs and definitions")

func _empty_preview() -> void:
 hint_label.text=_tr("เพิ่มอนิเมชันท่าสกิลภายหลัง","Animations will be added after skill moves are authored")

func _build() -> void:
 # The parent Inventory draws the shared header, 5 tabs and close button.
 # Only the CONTENT from y=199 to y=780 belongs to this screen.
 _panel("SkillLeftPanel",self,54,205,644,576)
 _panel("SkillRightTopPanel",self,711,205,684,104)
 _panel("SkillRightSkillsPanel",self,711,318,684,298)
 _panel("SkillHotbarPanel",self,711,626,360,156)
 _panel("SkillUpgradePanel",self,1082,626,313,156)

 _image("icon_scroll",self,77,219,62,62)
 class_label=_label("SkillClassTitle",self,150,217,360,34,27)
 class_subtitle=_label("SkillClassSubtitle",self,151,254,420,22,14,false)
 future_label=_label("SkillFutureTitle",self,500,225,174,25,17)
 
 # Leave one LARGE, frameless animation viewport above all controls.
 # It expands from 232px to 318px high (+37%); no character cutout,
 # extra rings, nested frame PNG or decorative lines.
 _panel("SkillPreviewFrame",self,73,281,604,318)
 preview_anchor=Control.new()
 preview_anchor.name="SkillPreviewAnimationAnchor"
 preview_anchor.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(preview_anchor)
 _rect(preview_anchor,89,289,572,300)

 # Reserve only a short strip at the bottom for the selected skill,
 # its concise details and the three playback buttons.
 _slot(self,"SelectedSkillIcon",82,605,55,false).disabled=true
 slot_label=_label("SkillSelectedName",self,153,603,510,29,21)
 _label("SkillTypeCaption",self,153,633,132,20,14).text=_tr("ประเภท","Type")
 _label("SkillCooldownCaption",self,296,633,135,20,14).text=_tr("คูลดาวน์","Cooldown")
 _label("SkillStaminaCaption",self,441,633,219,20,14).text=_tr("ใช้สตามินา","Stamina")
 description_label=_label("SkillDescription",self,83,660,588,24,14,false)
 # Flat, compact detail strips sit ABOVE the bottom action row.
 # Their text is native Godot (translatable, no image cropping).
 _panel("SkillCurrentStatsFrame",self,83,687,283,37)
 _panel("SkillNextStatsFrame",self,380,687,290,37)
 current_level_label=_label("SkillCurrentStats",self,94,690,266,27,14)
 next_level_label=_label("SkillNextStats",self,391,690,272,27,14)
 # Single-line summaries avoid overflowing the compact strip at the bottom.
 current_level_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 next_level_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 current_level_label.add_theme_constant_override("line_spacing",0)
 next_level_label.add_theme_constant_override("line_spacing",0)

 # Controls rest almost against the lower edge of the left panel;
 # keep a small gap before the inventory footer notice at y=775.
 var pv_labels_th:=["ทดลองใช้","เล่นซ้ำ","หยุด"]
 var pv_labels_en:=["Preview","Replay","Stop"]
 for i in range(3):
  var btn:=_button("SkillPreviewAction"+str(i+1),self,85+float(i)*200,729,182,44,17)
  btn.text=pv_labels_en[i] if locale=="en" else pv_labels_th[i]
  btn.disabled=true
  btn.tooltip_text=_tr("จะเปิดหลังเพิ่มอนิเมชันท่าสกิล","Enabled when the skill animation is installed")
  preview_buttons.append(btn)

 level_label=_label("SkillLevel",self,737,218,116,31,24)
 exp_label=_label("SkillEXP",self,872,219,488,27,17,false)
 exp_bar=ProgressBar.new()
 exp_bar.name="SkillEXPGauge"
 exp_bar.show_percentage=false
 exp_bar.min_value=0
 exp_bar.max_value=100
 exp_bar.value=0
 exp_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var exp_back:=StyleBoxFlat.new()
 exp_back.bg_color=Color("#1e080d")
 exp_back.border_color=Color("#c49a60")
 exp_back.set_border_width_all(1)
 exp_back.set_corner_radius_all(2)
 var exp_fill:=StyleBoxFlat.new()
 exp_fill.bg_color=Color("#e9a44b")
 exp_fill.set_corner_radius_all(2)
 exp_bar.add_theme_stylebox_override("background",exp_back)
 exp_bar.add_theme_stylebox_override("fill",exp_fill)
 add_child(exp_bar)
 _rect(exp_bar,873,250,490,12)
 sp_label=_label("SkillAvailablePoints",self,739,270,294,27,18)
 gold_label=_label("SkillGoldAmount",self,1055,270,307,27,18)

 current_skills_tab=_button("NoviceSkillTab",self,733,328,312,42,19)
 current_skills_tab.disabled=true
 next_job_tab=_button("LockedNextJobTab",self,1056,328,315,42,17)
 next_job_tab.disabled=true

 # Reuse the EXACT slot_empty.png and slot_locked.png seen in the bag.
 # Novice has THREE skill positions. The other eleven blank cells are
 # reserved/locked, not 11 fabricated skills or selectable professions.
 for i in range(MAX_SLOTS):
  var col:int=i%7
  var row:int=int(i/7)
  var x:float=746.0+float(col)*91.0
  var y:float=404.0+float(row)*105.0
  var cell:=_slot(self,"NoviceSkillSlot%02d"%(i+1),x,y,70.0,i>=NOVICE_SLOTS)
  cell.set_meta("skill_index",i)
  skill_slots.append(cell)
  var number:=_label("SkillSlotNumber%02d"%(i+1),self,x,y-22.0,70,19,13,true,HORIZONTAL_ALIGNMENT_CENTER)
  slot_numbers.append(number)

 page_label=_label("SkillGridCaption",self,743,582,638,26,16,true,HORIZONTAL_ALIGNMENT_CENTER)
 _label("SkillHotbarTitle",self,733,640,320,26,18).text=_tr("ช่องติดตั้งสกิล (3 ช่อง)","Equipped skills (3 slots)")
 for i in range(3):
  var x:float=764.0+float(i)*103.0
  var n:=_label("SkillHotbarNumber"+str(i+1),self,x,675,71,18,14,true,HORIZONTAL_ALIGNMENT_CENTER)
  equipped_numbers.append(n)
  active_slots.append(_slot(self,"EquippedSkillSlot"+str(i+1),x,699,71,false))
 _label("SkillUpgradeTitle",self,1103,640,266,27,19).text=_tr("อัปเกรดสกิล","Skill upgrade")
 price_label=_label("SkillCostPoints",self,1112,681,258,24,16)
 cost_label=_label("SkillCostGold",self,1112,709,258,24,16)
 upgrade_button=_button("SkillUpgradeButton",self,1106,742,261,32,16)
 upgrade_button.disabled=true
 hint_label=_label("SkillPreviewNote",self,86,306,570,36,16,false,HORIZONTAL_ALIGNMENT_CENTER)
 hint_label.text=""
 # Static tutorial/help labels are native Godot text for easy translation.
 set_language(locale)

func set_language(p_locale: String) -> void:
 locale="en" if p_locale=="en" else "th"
 if not is_instance_valid(current_skills_tab):return
 current_skills_tab.text=_tr("สกิลพื้นฐาน (3 ช่อง)","Novice skills (3 slots)")
 next_job_tab.text=_tr("สกิลขั้นต่อไป (ล็อก)","Next job skills (locked)")
 slot_label.text=_tr("ยังไม่ได้เลือกสกิล","No skill selected")
 description_label.text=_tr("ช่องสกิลยังว่าง รอสร้าง PNG และข้อมูลสกิลจริง","Empty skill cells — waiting for genuine skill art and data")
 current_level_label.text=_tr("ปัจจุบัน Lv.-  ·  พลัง -","Current Lv.-  ·  Power -")
 next_level_label.text=_tr("ถัดไป Lv.-  ·  พลัง -","Next Lv.-  ·  Power -")
 for i in range(3):
  preview_buttons[i].text=(_tr("ทดลองใช้","Preview") if i==0 else (_tr("เล่นซ้ำ","Replay") if i==1 else _tr("หยุด","Stop")))
 for label in slot_numbers:
  label.text=str(slot_numbers.find(label)+1)
 for label in equipped_numbers:
  label.text=str(equipped_numbers.find(label)+1)
 var all_labels:Dictionary={
  "SkillTypeCaption":[_tr("ประเภท","Type")," : -"],
  "SkillCooldownCaption":[_tr("คูลดาวน์","Cooldown")," : -"],
  "SkillStaminaCaption":[_tr("ใช้สตามินา","Stamina")," : -"],
  "SkillHotbarTitle":[_tr("ช่องติดตั้งสกิล (3 ช่อง)","Equipped skills (3 slots)"),""],
  "SkillUpgradeTitle":[_tr("อัปเกรดสกิล","Skill upgrade"),""]
 }
 for key in all_labels:
  var label:Label=get_node_or_null(str(key)) as Label
  if label!=null:
   label.text=str(all_labels[key][0])+str(all_labels[key][1])
 upgrade_button.text=_tr("ยังไม่เปิดให้อัปสกิล","Upgrade unavailable")
 hint_label.text=""
 refresh()

func refresh() -> void:
 if not is_instance_valid(level_label) or game_store==null:return
 var profile:Dictionary=game_store.profile
 var profession:Dictionary=game_store.effective_job_info()
 var tier:int=int(profession.get("tier",0))
 var novice:bool=tier==0
 var label_key:String="en" if locale=="en" else "th"
 var previous:Dictionary=JobCatalog.tier_one(str(profession.get("path","Unchosen")))
 var level:int=clampi(int(profile.get("level",1)),1,999)
 var experience:int=maxi(0,int(profile.get("experience",0)))
 var required:int=maxi(1,int(game_store.experience_required(level)))
 var pct:float=100.0*float(experience)/float(required)
 class_label.text=_tr("อาชีพเริ่มต้น","Novice") if novice else str(profession.get(label_key,""))
 if novice:
  class_subtitle.text=_tr("ผู้ฝึกหัด · ยังไม่เลือกอาชีพ","Trainee · Job not selected")
  future_label.text=_tr("ขั้นถัดไป : ล็อก","Next tier: locked")
 elif tier==1:
  class_subtitle.text=_tr("อาชีพขั้น 1 · ","Tier 1 · ")+str(profession.get("path_th",""))
  future_label.text=_tr("ขั้น 1 / 2","Tier 1 / 2")
 else:
  class_subtitle.text=_tr("อาชีพขั้น 2 · ต่อจาก ","Tier 2 · Advanced from ")+str(previous.get(label_key,profession.get(label_key,"")))
  future_label.text=_tr("ขั้น 2 / 2","Tier 2 / 2")
 level_label.text="Lv. "+str(level)
 exp_label.text="EXP  "+str(experience)+" / "+str(required)+" ("+str(snappedf(pct,0.1))+"%)"
 exp_bar.max_value=required
 exp_bar.value=mini(experience,required)
 sp_label.text=_tr("แต้มสกิล : ","Skill points: ")+str(int(profile.get("skill_points",0)))
 gold_label.text=_tr("เงิน : ","Gold: ")+game_store.pretty(str(game_store.currency.get("gold","0")))
 if novice:
  current_skills_tab.text=_tr("สกิลพื้นฐาน (3 ช่อง)","Novice skills (3 slots)")
  next_job_tab.text=_tr("สกิลขั้นต่อไป (ล็อก)","Next job skills (locked)")
  page_label.text=_tr("ช่อง 1–3 สำหรับสกิลเริ่มต้น · อีก 11 ช่องรออาชีพ","Slots 1–3 for Novice · 11 reserved for later jobs")
 elif tier==1:
  current_skills_tab.text=_tr("สกิลอาชีพขั้น 1 (14 ช่อง)","Tier 1 skills (14 slots)")
  next_job_tab.text=_tr("อาชีพขั้น 2 (ยังไม่ปลดล็อก)","Tier 2 (not unlocked)")
  page_label.text=_tr("ช่องว่าง 14 ช่องสำหรับสกิลอาชีพนี้ · ยังไม่มี PNG","14 empty slots for this job · PNGs not yet added")
 else:
  current_skills_tab.text=_tr("สกิลอาชีพขั้น 2 (14 ช่อง)","Tier 2 skills (14 slots)")
  next_job_tab.text=_tr("อาชีพขั้น 2 · เปิดแล้ว","Tier 2 · Available")
  page_label.text=_tr("สกิลต่อยอดจากขั้น 1 · 14 ช่องรอ PNG","Advanced from Tier 1 · 14 slots awaiting PNGs")
 for i in range(skill_slots.size()):
  var locked:bool=novice and i>=NOVICE_SLOTS
  var slot:TextureButton=skill_slots[i]
  slot.disabled=locked
  slot.texture_normal=_png(ROOT,"slot_locked" if locked else "slot_empty")
  slot.texture_hover=slot.texture_normal
  slot.texture_pressed=slot.texture_normal
  slot.set_meta("reserved",locked)
 price_label.text=_tr("ใช้แต้มสกิล : -","Skill points required: -")
 cost_label.text=_tr("ใช้เงิน : -","Gold cost: -")
