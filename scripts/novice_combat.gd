extends Node
## Real, deterministic LOCAL PvE combat for the three starter skills.
## Only Novice is supported here; all other professions retain their
## separately implemented passive and timed-buff systems.
signal changed

const SLASH_RANGE:float=3.6
# Normal melee attacks have their own short swing interval, never use
# a skill cooldown or stamina, and remain usable while skills recharge.
const BASIC_ATTACK_RANGE:float=3.6
const BASIC_ATTACK_INTERVAL:float=0.52
const RUSH_RANGE:float=12.0
const HIT_RANGE:float=2.55
const GUARD_DURATION:float=5.0
const GUARD_REDUCTION:float=0.65
const STAMINA_REGEN:float=14.0
const RUSH_SPEED:float=26.0
const RUSH_MAX_SECONDS:float=0.55
const ENEMY_ATTACK_INTERVAL:float=2.2
const RESPAWN_SECONDS:float=8.0
const SKILL_COOLDOWNS:Dictionary={
 "novice_slash":0.8,
 "novice_rush":3.0,
 "novice_guard":10.0
}
const SKILL_COSTS:Dictionary={
 "novice_slash":0.0,
 "novice_rush":20.0,
 "novice_guard":15.0
}

var game:Node3D
var game_store:Node
var health:float=150.0
var max_health:float=150.0
var stamina:float=100.0
var max_stamina:float=100.0
var guard_seconds:float=0.0
var cooldowns:Dictionary={}
var basic_attack_seconds:float=0.0
var rush_active:bool=false
var rush_target:StaticBody3D
var rush_remaining:float=0.0
var _enemy_attack_elapsed:float=0.0
var _ui_elapsed:float=0.0
var _defeated:Dictionary={}
var guard_visual:MeshInstance3D
var floating_status:Label3D

func initialize(p_game:Node3D,p_store:Node) -> void:
 game=p_game
 game_store=p_store
 max_health=_max_health()
 health=max_health
 _install_player_feedback()
 _update_feedback()

func _max_health() -> float:
 var attrs:Dictionary=game_store.effective_attributes() if is_instance_valid(game_store) else {}
 return 100.0+float(attrs.get("vitality",10))*5.0

func cooldown_left(skill_id:String) -> float:
 return maxf(0.0,float(cooldowns.get(skill_id,0.0)))

func guard_active() -> bool:
 return guard_seconds>0.0

func basic_attack_left() -> float:
 return maxf(0.0,basic_attack_seconds)

func basic_attack() -> bool:
 # This is NOT a fourth equippable skill: it never uses skill hotbar
 # slots, cooldowns or skill points and has zero stamina cost.
 if str(game_store.effective_job_info().get("id","Novice"))!="Novice":return false
 if rush_active:return false
 if basic_attack_left()>0.0:return false
 var target:StaticBody3D=_locked_target()
 if target==null:
  game_store.notice.emit("ล็อกเป้าหมายที่มี HP ก่อนกด ATK")
  return false
 if _distance_to(target)>BASIC_ATTACK_RANGE:
  game_store.notice.emit("เป้าหมายไกลเกินระยะตีธรรมดา")
  return false
 basic_attack_seconds=BASIC_ATTACK_INTERVAL
 _attack_visual()
 _damage_target(target,_basic_damage())
 changed.emit()
 return true

func _basic_damage() -> float:
 var attrs:Dictionary=game_store.effective_attributes()
 var strength:float=float(attrs.get("strength",10))
 var dex:float=float(attrs.get("dexterity",10))
 # Weaker than Slash, but uses the same character's real stats.
 return float(maxi(1,roundi(10.0+strength*1.15+dex*0.18)))

func _target_is_valid(target:Node3D) -> bool:
 return is_instance_valid(target) and game.test_targets.has(target) and not target.is_queued_for_deletion() and float(target.get_meta("max_hp",0.0))>0.0 and float(target.get_meta("hp",0.0))>0.0

func _locked_target() -> StaticBody3D:
 if not is_instance_valid(game) or not is_instance_valid(game.hud_menu):return null
 var target:StaticBody3D=game.hud_menu.top_status.current_target as StaticBody3D
 return target if _target_is_valid(target) else null

func _distance_to(target:Node3D) -> float:
 if not is_instance_valid(target) or not is_instance_valid(game.character):return INF
 var delta:Vector3=target.global_position-game.character.global_position
 delta.y=0.0
 return delta.length()

func _attack_visual() -> void:
 var female:Node3D=game.character.get_node_or_null("FemalePlayerVisual") as Node3D
 if female!=null and female.visible and female.has_method("play_basic_attack"):
  female.call("play_basic_attack")

func cast(skill_id:String) -> bool:
 if not SKILL_COOLDOWNS.has(skill_id):return false
 # Temporary GM job switches cannot make a different profession cast Novice.
 if str(game_store.effective_job_info().get("id","Novice"))!="Novice":return false
 if cooldown_left(skill_id)>0.0:
  game_store.notice.emit("สกิลคูลดาวน์: %.1f วินาที" % cooldown_left(skill_id))
  return false
 var cost:float=float(SKILL_COSTS[skill_id])
 if stamina+0.001<cost:
  game_store.notice.emit("สตามินาไม่พอสำหรับสกิลนี้")
  return false
 var target:StaticBody3D=null
 if skill_id!="novice_guard":
  target=_locked_target()
  if target==null:
   game_store.notice.emit("เลือกเป้าหมายที่ยังมี HP ก่อนกดสกิล")
   return false
  var distance:float=_distance_to(target)
  var allowed:float=RUSH_RANGE if skill_id=="novice_rush" else SLASH_RANGE
  if distance>allowed:
   game_store.notice.emit("เป้าหมายอยู่นอกระยะสกิล")
   return false
 # No stamina or cooldown is spent on a failed range/target check.
 stamina=maxf(0.0,stamina-cost)
 cooldowns[skill_id]=float(SKILL_COOLDOWNS[skill_id])
 if skill_id=="novice_slash":
  _attack_visual()
  _damage_target(target,_attack_damage(false))
 elif skill_id=="novice_rush":
  rush_target=target
  rush_active=true
  rush_remaining=RUSH_MAX_SECONDS
  if _distance_to(target)<=HIT_RANGE:
   _finish_rush(true)
 else:
  guard_seconds=GUARD_DURATION
  if guard_visual!=null:guard_visual.visible=true
  _float_text(game.character.global_position+Vector3(0,1.75,0),"GUARD 65%",Color("#8bdcfb"))
  game_store.notice.emit("เกราะคุ้มกันลดความเสียหาย 65% นาน 5 วินาที")
 changed.emit()
 _update_feedback()
 return true

func _attack_damage(is_rush:bool) -> float:
 var attrs:Dictionary=game_store.effective_attributes()
 var strength:float=float(attrs.get("strength",10))
 var dex:float=float(attrs.get("dexterity",10))
 # Permanent passives and expiring buffs affect actual damage calculation.
 return float(maxi(1,roundi((25.0 if is_rush else 18.0)+strength*(2.8 if is_rush else 2.2)+dex*0.35)))

func _damage_target(target:StaticBody3D,raw_damage:float) -> float:
 if not _target_is_valid(target):return 0.0
 var hp:float=float(target.get_meta("hp",0.0))
 var damage:float=minf(hp,maxf(1.0,raw_damage))
 target.set_meta("hp",maxf(0.0,hp-damage))
 _float_text(target.global_position+Vector3(0,1.6,0),"-"+str(int(damage)),Color("#ffb45a"))
 if float(target.get_meta("hp",0.0))<=0.0:
  _defeated[target]=RESPAWN_SECONDS
  game_store.notice.emit(str(target.get_meta("target_name","ศัตรู"))+" ล้มแล้ว · ฟื้นใน 8 วินาที")
 if is_instance_valid(game.hud_menu):
  game.hud_menu.top_status._refresh_target()
 changed.emit()
 return damage

func _finish_rush(try_hit:bool) -> void:
 var target:StaticBody3D=rush_target
 rush_active=false
 rush_remaining=0.0
 rush_target=null
 if try_hit and _target_is_valid(target) and _distance_to(target)<=3.1:
  _attack_visual()
  _damage_target(target,_attack_damage(true))
 elif try_hit:
  game_store.notice.emit("พุ่งไม่ถึงเป้าหมาย")

func advance_rush(delta:float) -> void:
 if not rush_active:return
 if not is_instance_valid(game.character) or not _target_is_valid(rush_target):
  _finish_rush(false)
  return
 var delta_target:Vector3=rush_target.global_position-game.character.global_position
 delta_target.y=0.0
 var dist:float=delta_target.length()
 if dist<=HIT_RANGE:
  _finish_rush(true)
  return
 if dist<0.01:
  _finish_rush(true)
  return
 rush_remaining=maxf(0.0,rush_remaining-delta)
 var travel:float=minf(RUSH_SPEED*delta,maxf(0.0,dist-2.15))
 var collision:KinematicCollision3D=game.character.move_and_collide(delta_target.normalized()*travel)
 if _distance_to(rush_target)<=HIT_RANGE:
  _finish_rush(true)
 elif collision!=null or rush_remaining<=0.0:
  _finish_rush(_distance_to(rush_target)<=3.1)

func receive_damage(raw:float) -> float:
 if raw<=0.0 or health<=0.0:return 0.0
 var attrs:Dictionary=game_store.effective_attributes()
 var vit:float=float(attrs.get("vitality",10))
 var natural_reduction:float=clampf(maxf(0.0,vit-10.0)*0.012,0.0,0.40)
 var multiplier:float=(1.0-natural_reduction)*(1.0-GUARD_REDUCTION if guard_active() else 1.0)
 var dealt:float=maxf(1.0,roundf(raw*multiplier))
 health=maxf(0.0,health-dealt)
 _float_text(game.character.global_position+Vector3(0,1.7,0),"-"+str(int(dealt))+" HP",Color("#ff7783"))
 if health<=0.0:
  _player_defeated()
 changed.emit()
 _update_feedback()
 return dealt

func reset_training_targets() -> void:
 # GM reset also cancels any pending auto-respawn from previous defeats.
 _defeated.clear()
 rush_active=false
 rush_target=null
 rush_remaining=0.0

func _player_defeated() -> void:
 # Local training respawn, no deletion or mutation of saved progression.
 rush_active=false
 rush_target=null
 guard_seconds=0.0
 cooldowns.clear()
 basic_attack_seconds=0.0
 game.character.velocity=Vector3.ZERO
 game.character.global_position=Vector3(0,1.1,5)
 health=_max_health()
 stamina=max_stamina
 if guard_visual!=null:guard_visual.visible=false
 if is_instance_valid(game.hud_menu):game.hud_menu.clear_target()
 game_store.notice.emit("HP หมด · กลับจุดเริ่มต้นพร้อม HP และสตามินาเต็ม")

func _enemy_attack() -> void:
 if not is_instance_valid(game) or not is_instance_valid(game.character):return
 var nearest:StaticBody3D=null
 var nearest_distance:float=2.8
 for candidate in game.test_targets:
  if not _target_is_valid(candidate):continue
  if str(candidate.get_meta("target_type",""))!="Monster":continue
  var distance:float=_distance_to(candidate)
  if distance<nearest_distance:
   nearest=candidate
   nearest_distance=distance
 if nearest==null:return
 var level:int=int(nearest.get_meta("level",1))
 receive_damage(6.0+float(level)*1.25)

func _process(delta:float) -> void:
 if not is_instance_valid(game_store) or not is_instance_valid(game):return
 var old_max:float=max_health
 max_health=_max_health()
 if not is_equal_approx(max_health,old_max):
  health=clampf(health+max_health-old_max,0.0,max_health)
 var old_guard:float=guard_seconds
 guard_seconds=maxf(0.0,guard_seconds-delta)
 basic_attack_seconds=maxf(0.0,basic_attack_seconds-delta)
 if guard_visual!=null:guard_visual.visible=guard_seconds>0.0
 var old_stamina:float=stamina
 stamina=minf(max_stamina,stamina+delta*STAMINA_REGEN)
 for id in cooldowns.keys():
  cooldowns[id]=maxf(0.0,float(cooldowns[id])-delta)
 for target in _defeated.keys():
  if not is_instance_valid(target):
   _defeated.erase(target)
   continue
  var seconds:float=float(_defeated[target])-delta
  if seconds<=0.0:
   target.set_meta("hp",target.get_meta("max_hp",1.0))
   _defeated.erase(target)
   if is_instance_valid(game.hud_menu):game.hud_menu.top_status._refresh_target()
  else:
   _defeated[target]=seconds
 _enemy_attack_elapsed+=delta
 if _enemy_attack_elapsed>=ENEMY_ATTACK_INTERVAL:
  _enemy_attack_elapsed=fposmod(_enemy_attack_elapsed,ENEMY_ATTACK_INTERVAL)
  _enemy_attack()
 _ui_elapsed+=delta
 if _ui_elapsed>=0.20 or (old_guard>0.0 and guard_seconds<=0.0):
  _ui_elapsed=0.0
  if not is_equal_approx(old_stamina,stamina) or old_guard>0.0 or not cooldowns.is_empty():
   changed.emit()
  _update_feedback()

func _install_player_feedback() -> void:
 if not is_instance_valid(game) or not is_instance_valid(game.character):return
 guard_visual=MeshInstance3D.new()
 guard_visual.name="NoviceGuardEffect"
 var bubble:=SphereMesh.new()
 bubble.radius=1.18
 bubble.height=2.36
 guard_visual.mesh=bubble
 guard_visual.position=Vector3(0,0.05,0)
 var shield_material:=StandardMaterial3D.new()
 shield_material.albedo_color=Color(0.20,0.66,1.0,0.18)
 shield_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 shield_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 guard_visual.material_override=shield_material
 guard_visual.visible=false
 game.character.add_child(guard_visual)
 floating_status=Label3D.new()
 floating_status.name="NoviceVitals"
 floating_status.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 floating_status.position=Vector3(0,1.85,0)
 floating_status.font_size=25
 floating_status.pixel_size=0.006
 floating_status.modulate=Color("#faf1dd")
 game.character.add_child(floating_status)

func _update_feedback() -> void:
 if floating_status!=null:
  floating_status.text="HP "+str(roundi(health))+"/"+str(roundi(max_health))+"   ST "+str(roundi(stamina))+"/"+str(roundi(max_stamina))

func _float_text(location:Vector3,caption:String,color:Color) -> void:
 if not is_instance_valid(game):return
 var label:=Label3D.new()
 label.text=caption
 label.font_size=42
 label.pixel_size=0.008
 label.modulate=color
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 game.add_child(label)
 label.global_position=location
 var tween:=game.create_tween()
 tween.set_parallel(true)
 tween.tween_property(label,"position",label.position+Vector3(0,0.85,0),0.65)
 tween.tween_property(label,"modulate:a",0.0,0.65)
 tween.set_parallel(false)
 tween.tween_callback(label.queue_free)
