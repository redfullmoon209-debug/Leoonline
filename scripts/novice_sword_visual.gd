extends Node3D
## Lightweight original 3D training sword. There is no weapon FBX in the
## repository yet, so this is a real mesh attached to RightHand (not a UI
## icon cropped onto the avatar). Replace this test prop with weapon FBX later.
var mesh_ready:bool=false

func _metal(color:Color,metalness:float=0.85) -> StandardMaterial3D:
 var mat:=StandardMaterial3D.new()
 mat.albedo_color=color
 mat.metallic=metalness
 mat.roughness=0.26
 return mat

func _part(name_value:String,mesh_value:Mesh,center:Vector3,material:Material) -> MeshInstance3D:
 var node:=MeshInstance3D.new()
 node.name=name_value
 node.mesh=mesh_value
 node.position=center
 node.material_override=material
 add_child(node)
 return node

func _triple(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3) -> void:
 tool.add_vertex(a)
 tool.add_vertex(b)
 tool.add_vertex(c)

func _blade() -> ArrayMesh:
 # A tapered, four-faceted double-edged steel blade with an actual tip.
 var ring1:Array=[
  Vector3(-0.075,0.16,0),
  Vector3(0,0.16,-0.031),
  Vector3(0.075,0.16,0),
  Vector3(0,0.16,0.031)
 ]
 var ring2:Array=[
  Vector3(-0.045,0.85,0),
  Vector3(0,0.85,-0.024),
  Vector3(0.045,0.85,0),
  Vector3(0,0.85,0.024)
 ]
 var tip:=Vector3(0,1.05,0)
 var surface:=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(4):
  var next_i:int=(i+1)%4
  _triple(surface,ring1[i],ring2[i],ring1[next_i])
  _triple(surface,ring1[next_i],ring2[i],ring2[next_i])
  _triple(surface,ring2[i],tip,ring2[next_i])
 surface.generate_normals()
 return surface.commit()

func _ready() -> void:
 var blade:=_part("SwordBlade",_blade(),Vector3.ZERO,_metal(Color("#d5e1f0")))
 blade.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 var fuller:=BoxMesh.new()
 fuller.size=Vector3(0.015,0.52,0.034)
 _part("BladeCenterRidge",fuller,Vector3(0,0.49,-0.002),_metal(Color("#f7fbff"),0.63))
 var guard:=BoxMesh.new()
 guard.size=Vector3(0.35,0.065,0.115)
 _part("GoldenCrossguard",guard,Vector3(0,0.105,0),_metal(Color("#d5ad51")))
 var grip:=CylinderMesh.new()
 grip.top_radius=0.050
 grip.bottom_radius=0.046
 grip.height=0.32
 _part("LeatherSwordGrip",grip,Vector3(0,-0.09,0),_metal(Color("#4a2731"),0.05))
 var collar:=CylinderMesh.new()
 collar.top_radius=0.067
 collar.bottom_radius=0.067
 collar.height=0.055
 _part("GripCollar",collar,Vector3(0,-0.25,0),_metal(Color("#d5ad51")))
 var pommel:=SphereMesh.new()
 pommel.radius=0.079
 pommel.height=0.142
 _part("SwordPommel",pommel,Vector3(0,-0.29,0),_metal(Color("#bd9343")))
 mesh_ready=true
