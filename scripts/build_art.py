"""Original beveled 3D assets shared by the Unity project and Blender previews.
Run: blender -b -t 2 --python scripts/build_art.py -- /path/to/project
No external models, generated images, or Township/Candy Crush game files.
"""
import bpy, math, json, sys, pathlib, random
from mathutils import Vector
root=pathlib.Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else pathlib.Path.cwd()
out=root/'Assets/Paco/Resources/Models';out.mkdir(parents=True,exist_ok=True)
preview=root/'docs/previews';preview.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
PALETTE={'cream':'FFF0D3','white':'FFF9EA','teal':'187B89','blue':'368BC6','navy':'234A60','roof':'DF744D','coral':'EC806D','mint':'8AD6B1','green':'67A842','leaf':'3C8E50','lime':'B5DC68','yellow':'FFC955','gold':'E5AD38','wood':'A97149','darkwood':'6D4F3A','glass':'87D8E7','road':'6C7E87','metal':'BAC6CD','water':'47BBCB','pink':'E994BC','purple':'9671C7','red':'D95452','skin':'9C6548','ink':'203D44'}
mats={}
for name,hexcode in PALETTE.items():
 m=bpy.data.materials.new(name);m.diffuse_color=tuple(((int(hexcode[i:i+2],16)/255+.055)/1.055)**2.4 if int(hexcode[i:i+2],16)/255>.04045 else int(hexcode[i:i+2],16)/255/12.92 for i in (0,2,4))+(1,);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=m.diffuse_color;p.inputs['Roughness'].default_value=.32 if name in ['glass','water','gold','metal'] else .54;p.inputs['Metallic'].default_value=.5 if name in ['gold','metal'] else .02
 mats[name]=m
(root/'Assets/Paco/Resources/Data/materials.json').write_text(json.dumps({'materials':[{'name':n,'hex':h,'metallic':.5 if n in ['gold','metal'] else .02,'smoothness':.68 if n in ['glass','water','gold','metal'] else .46} for n,h in PALETTE.items()]},indent=2))
models={};current=[];glazed=False
def finish(o,name,mat):
 if glazed:
  key='glaze_'+mat
  if key not in mats:
   m=mats[mat].copy();m.name=key;m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.19;m.node_tree.nodes.get('Principled BSDF').inputs['Coat Weight'].default_value=.5;m.node_tree.nodes.get('Principled BSDF').inputs['Coat Roughness'].default_value=.12;mats[key]=m
  mat=key
 o.name=name;o.data.materials.append(mats[mat]);current.append(o)
 return o
def cube(name,loc,size,mat,bevel=.05):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:mod=o.modifiers.new('Soft crafted edges','BEVEL');mod.width=bevel;mod.segments=3;o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return finish(o,name,mat)
def sphere(name,loc,size,mat):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32 if glazed else 16,ring_count=16 if glazed else 8,radius=1,location=loc);o=bpy.context.object;o.scale=size
 for p in o.data.polygons:p.use_smooth=True
 return finish(o,name,mat)
def cylinder(name,loc,radius,depth,mat,vertices=20):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc);o=bpy.context.object
 mod=o.modifiers.new('Rounded rim','BEVEL');mod.width=min(.045,radius/5);mod.segments=2;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return finish(o,name,mat)
def roof(loc,w,d,h,mat):
 x,y,z=loc;verts=[(x-w/2,y-d/2,z),(x+w/2,y-d/2,z),(x,y-d/2,z+h),(x-w/2,y+d/2,z),(x+w/2,y+d/2,z),(x,y+d/2,z+h)]
 mesh=bpy.data.meshes.new('GabledRoof');mesh.from_pydata(verts,[],[(0,3,4,1),(0,1,2),(3,5,4),(0,2,5,3),(1,4,5,2)]);mesh.update();o=bpy.data.objects.new('Roof',mesh);bpy.context.collection.objects.link(o);finish(o,'Roof',mat);mod=o.modifiers.new('Rounded eaves','BEVEL');mod.width=.045;mod.segments=3;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 # Dark ridges across the roof give small-screen detail.
 for sy in [-1,1]:
  for j in range(1,6):
   yy=y-d/2+j*d/6
   beam=cube('Roof seam',(x+sy*w*.25,yy,z+h*.5),(.024,d/35,math.sqrt((w/2)**2+h*h)),mat,.009);beam.rotation_euler[1]=-sy*math.atan2(w/2,h)
def pot(x,y,z=.16):
 cylinder('Terracotta pot',(x,y,z),.13,.25,'roof');sphere('Clipped shrub',(x,y,z+.24),(.22,.22,.23),'leaf')
def window(x,y,z,w=.34,h=.48):
 cube('Window surround',(x,y,z),(w+.1,.08,h+.1),'white',.025);cube('Blue glazing',(x,y-.05,z),(w,.035,h),'glass',.015)
 cube('Window mullion',(x,y-.075,z),(.028,.02,h),'cream',.006);cube('Sill',(x,y-.09,z-h/2),(w+.14,.18,.07),'cream',.015)
def awning(x,y,z,w=1.5):
 for i in range(6):
  o=cube('Striped awning',(x-w/2+(i+.5)*w/6,y,z),(w/6,.65,.09),'roof' if i%2 else 'white',.035);o.rotation_euler[0]=.15
  cylinder('Scallop',(x-w/2+(i+.5)*w/6,y-.33,z-.06),w/12,.1,'roof' if i%2 else 'white').rotation_euler[0]=math.pi/2
 for xx in [x-w/2,x+w/2]:cylinder('Awning support',(xx,y-.3,z-.55),.025,1.05,'darkwood')
def building(kind,wall='cream',roofmat='teal',stories=1):
 cube('Raised garden plot',(0,0,.07),(3.1,2.8,.2),'green',.16)
 cube('Paved foundation',(0,-.1,.18),(2.65,2.3,.16),'cream',.1)
 h=1.2+stories*.58
 cube('Plaster facade',(0,0,.3+h/2),(2.2,1.7,h),wall,.09)
 for x in [-1.04,1.04]:cube('Corner trim',(x,-.89,.35+h/2),(.12,.12,h),'white',.025)
 cube('Cornice',(0,0,.32+h),(2.38,1.88,.15),'white',.04)
 roof((0,0,.39+h),2.5,2.0,.8,roofmat)
 cube('Door frame',(0,-.91,.76),(.5,.12,1.02),'white',.03);cube('Entrance',(0,-.99,.73),(.36,.045,.88),'teal',.03);sphere('Door handle',(.13,-1.03,.76),(.028,.025,.028),'gold')
 for x in [-.72,.72]:window(x,-.91,1.05)
 for floor in range(stories):
  for x in [-.65,0,.65]:window(x,-.91,1.73+floor*.5,.3,.34)
 for side in [-1,1]:
  for y in [-.4,.35]:cube('Side window',(side*1.11,y,1.1),(.05,.39,.57),'glass',.02)
 cube('Entrance step',(0,-1.13,.2),(.9,.38,.15),'white',.025)
 pot(-1.18,-1.0);pot(1.18,-1.0)
 if kind in ['shop','services']:awning(0,-1.12,1.65,1.75)
 if kind=='farm':
  # barn double doors and crates; cacao pods as crop details
  cube('Barn door',(0,-1.02,.83),(.92,.08,1.2),'wood',.025)
  for sy in [-1,1]:
   beam=cube('Barn cross brace',(sy*.21,-1.08,.8),(.06,.035,.95),'white',.008);beam.rotation_euler[1]=sy*.47
  for i in range(3):cube('Produce crate',(1.1,-.7+i*.45,.42),(.38,.36,.4),'wood',.025)
  for i in range(4):sphere('Cacao harvest',(-1.15,-.6+i*.4,.46),(.13,.17,.24),'yellow')
 if kind=='bank':
  for x in [-.85,-.42,.42,.85]:cylinder('Classical column',(x,-1.02,1.0),.09,1.5,'white')
  cylinder('Medallion',(0,-.99,2.02),.26,.07,'gold').rotation_euler[0]=math.pi/2
 if kind=='telecom':
  cylinder('Radio mast',(.4,.1,h+1.55),.055,1.65,'metal')
  for z in [h+1.1,h+1.5,h+1.9]:cube('Antenna panel',(.4,.1,z),(.7,.13,.1),'white',.03)
 if kind=='factory':
  for x in [-.7,.7]:
   cylinder('Vent stack',(x,.4,h+.95),.16,1.1,'metal');cylinder('Chimney cap',(x,.4,h+1.5),.2,.08,'navy')
  cylinder('Cooling tank',(1.1,.4,.95),.32,1.3,'glass')
 if kind=='energy':
  for i in range(4):
   o=cube('Photovoltaic array',(-.75+i*.5,0,h+1.0),(.43,1.3,.08),'navy',.025);o.rotation_euler[1]=-.4
   for j in range(4):cube('Solar cells',(-.75+i*.5,-.45+j*.3,h+1.06),(.38,.015,.02),'glass',.003)
 if kind=='services':
  cube('Community sign',(0,-1.01,2.3),(1.05,.12,.38),'blue',.04)
  cube('Sign cross vertical',(0,-1.09,2.3),(.07,.04,.24),'white',.01);cube('Sign cross horizontal',(0,-1.1,2.3),(.24,.04,.07),'white',.01)
def export(name,fn):
 global current
 current=[];fn();objects=current[:];models[name]=objects
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.fbx(filepath=str(out/(name+'.fbx')),use_selection=True,object_types={'MESH'},add_leaf_bones=False,apply_unit_scale=True,apply_scale_options='FBX_SCALE_ALL',axis_forward='-Z',axis_up='Y',bake_space_transform=True,use_mesh_modifiers=True)
 for o in objects:o.hide_render=True;o.hide_set(True)
export('house',lambda:building('house','cream','teal',1))
export('farm',lambda:building('farm','coral','teal',0))
export('shop',lambda:building('shop','cream','roof',1))
export('telecom',lambda:building('telecom','blue','navy',1))
export('bank',lambda:building('bank','cream','teal',1))
export('factory',lambda:building('factory','mint','roof',0))
export('energy',lambda:building('energy','yellow','navy',0))
export('services',lambda:building('services','pink','teal',1))
def tree():
 cylinder('Trunk',(0,0,.48),.11,.95,'wood')
 for x,y,z,r in [(0,0,1.15,.52),(-.25,0,1.0,.35),(.2,.2,1.2,.34)]:sphere('Rounded canopy',(x,y,z),(r,r,r*1.1),'leaf' if x==0 else 'green')
export('tree',tree)
def palm():
 o=cylinder('Palm trunk',(0,0,.82),.1,1.65,'wood');o.rotation_euler[1]=.07
 for i in range(7):
  a=i*math.tau/7;o=sphere('Palm frond',(.46*math.cos(a),.46*math.sin(a),1.72),(.7,.14,.075),'leaf');o.rotation_euler[2]=a;o.rotation_euler[1]=-.2
 for a in [0,2,4]:sphere('Coconut',(.13*math.cos(a),.13*math.sin(a),1.6),(.12,.12,.12),'darkwood')
export('palm',palm)
def car():
 cube('Body',(0,0,.36),(.73,1.3,.35),'coral',.14);cube('Cabin',(0,.1,.63),(.62,.7,.37),'blue',.12)
 cube('Windscreen',(0,-.265,.66),(.51,.025,.25),'glass',.035)
 for x in [-.36,.36]:
  for y in [-.4,.4]:cylinder('Wheel',(x,y,.2),.18,.11,'ink').rotation_euler[1]=math.pi/2
 for x in [-.23,.23]:sphere('Headlight',(x,-.65,.38),(.09,.035,.055),'yellow')
export('car',car)
def person():
 sphere('Body',(0,0,.48),(.14,.11,.23),'yellow');sphere('Head',(0,0,.78),(.14,.13,.15),'skin');sphere('Hair',(0,.025,.86),(.15,.125,.09),'darkwood')
 for x in [-.07,.07]:
  cylinder('Leg_L' if x<0 else 'Leg_R',(x,0,.2),.047,.35,'navy');sphere('Shoe',(x,-.035,.055),(.06,.1,.05),'ink')
 for x in [-.18,.18]:cylinder('Arm',(x,0,.47),.038,.3,'skin')
export('person',person)
def fountain():
 cylinder('Fountain base',(0,0,.15),.95,.22,'cream',32);cylinder('Water',(0,0,.28),.79,.055,'water',32)
 cylinder('Pedestal',(0,0,.56),.17,.6,'white');cylinder('Upper basin',(0,0,.85),.46,.1,'cream');sphere('Water jet',(0,0,1.12),(.07,.07,.27),'glass')
export('fountain',fountain)
# Puzzle pieces: unique silhouettes plus embossed sector symbols, not flat sprites.
glazed=True
def candy_base(color):sphere('Glazed body',(0,0,0),(.41,.34,.22),color)
def cacao():
 candy_base('yellow')
 o=sphere('Cacao pod',(0,0,.22),(.18,.3,.15),'roof');o.rotation_euler[2]=-.4
 for x in [-.075,0,.075]:sphere('Pod ridge',(x,0,.32),(.016,.22,.018),'gold')
 o=sphere('Leaf',(.16,.2,.25),(.15,.06,.035),'leaf');o.rotation_euler[2]=.7
export('tile_cacao',cacao)
def phone():
 cube('Phone',(0,0,0),(.52,.72,.35),'blue',.12);cube('Screen',(0,.055,.2),(.38,.43,.04),'glass',.07);cylinder('Home',(0,-.25,.21),.055,.035,'cream')
export('tile_phone',phone)
def cash():
 for z in [-.1,0,.1]:cube('Banknote',(0,0,z),(.75,.45,.1),'green',.075)
 cylinder('Seal',(0,0,.18),.13,.055,'lime');cube('Security band',(-.2,0,.18),(.06,.34,.025),'cream',.015)
export('tile_cash',cash)
def fuel():
 cube('Fuel can',(0,0,0),(.58,.66,.32),'coral',.12);cube('Handle',(0,.37,0),(.26,.14,.14),'roof',.05);cylinder('Cap',(-.22,.28,.02),.07,.12,'ink')
 for a in [-.65,.65]:o=cube('Embossed brace',(0,0,.18),(.055,.47,.035),'roof',.025);o.rotation_euler[2]=a
export('tile_fuel',fuel)
def bulb():
 candy_base('yellow');sphere('Glass light',(0,.07,.19),(.24,.27,.16),'yellow')
 for y in [-.21,-.29,-.36]:cube('Screw socket',(0,y,.14),(.27,.08,.16),'metal',.035)
 cube('Filament',(0,.07,.36),(.055,.22,.02),'white',.015)
export('tile_bulb',bulb)
def gear():
 cylinder('Gear rim',(0,0,0),.31,.3,'purple',32)
 for i in range(8):
  a=i*math.tau/8;o=cube('Tooth',(.3*math.cos(a),.3*math.sin(a),0),(.2,.2,.28),'purple',.055);o.rotation_euler[2]=a
 cylinder('Hub',(0,0,.19),.2,.14,'pink',24);cylinder('Dark bore',(0,0,.27),.105,.015,'purple',24)
export('tile_gear',gear)
glazed=False
def title(text,mat):
 bpy.ops.object.text_add(location=(0,0,0));o=bpy.context.object;o.data.body=text;o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=1.5;o.data.extrude=.07;o.data.bevel_depth=.025;o.data.bevel_resolution=3
 try:o.data.font=bpy.data.fonts.load(str(root/'Assets/Paco/Resources/Fonts/Nunito.ttf'))
 except RuntimeError:pass
 bpy.ops.object.convert(target='MESH');finish(bpy.context.object,'Extruded clay lettering',mat)
export('title_win',lambda:title('GAGNE','gold'))
export('title_lose',lambda:title('PAS DE CHANCE','coral'))
# Layout is the exact ground-plane data consumed by Unity CityView.
layout=[]
def place(model,x,y,rotation=0,scale=1,kind='decor',id=''):
 layout.append(dict(model=model,x=x,z=y,rotation=rotation,scale=scale,kind=kind,id=id))
for x,y,model in [(-7,-5,'house'),(-3,-5,'shop'),(1,-5,'bank'),(5,-5,'telecom'),(-7,0,'farm'),(-3,0,'factory'),(1,0,'services'),(5,0,'energy'),(-7,5,'house'),(-3,5,'house'),(1,5,'shop')]:place(model,x,y)
place('fountain',5,5)
for x in range(-10,10,2):place('tree',x,8,scale=.85);place('tree',x,-8,scale=.8)
for y in range(-6,8,2):place('palm',-10,y);place('palm',8,y)
for i,l in enumerate(['rive','verger','marche','atelier','lumiere','jardin']):place('tree',11+(i%2)*4,-5+(i//2)*5,kind='land',id=l)
(root/'Assets/Paco/Resources/Data/world.json').write_text(json.dumps({'objects':layout},indent=2))
# Save models for future editing; make visible duplicates for a genuine geometry preview.
current=[]
for item in layout:
 if item['kind']=='land':continue
 for original in models[item['model']]:
  o=original.copy();o.data=original.data;bpy.context.collection.objects.link(o);o.hide_render=False;o.hide_set(False);o.location+=Vector((item['x'],item['z'],0));o.scale*=item['scale']
cube('Floating island',(0,0,-.7),(23,20,1.3),'cream',.5);cube('Grass lawn',(0,0,-.07),(22.8,19.8,.28),'lime',.4)
for y in [-2.5,2.5]:
 cube('Road',(0,y,.1),(21.5,1.5,.08),'road',.05)
 for x in range(-10,11,2):cube('Road markings',(x,y,.15),(.7,.055,.012),'white',.006)
for x in [-5,3]:
 cube('Cross street',(x,0,.1),(1.4,17.9,.08),'road',.05)
 for y in range(-8,9,2):cube('Lane dash',(x,y,.15),(.055,.7,.012),'white',.006)
 for y in [-3.5,1.5]:
  for j in range(5):cube('Zebra crossing',(x-.5+j*.25,y,.16),(.14,.6,.012),'white',.004)
for x,y in [(-5,-5),(3,5),(3,-5),(-5,5)]:
 for original in models['car']:
  o=original.copy();o.data=original.data;bpy.context.collection.objects.link(o);o.hide_render=False;o.hide_set(False);o.location+=Vector((x,y,.1))
for i in range(16):
 x=-8+(i%8)*2;y=-1.5+(i//8)*5
 for original in models['person']:
  o=original.copy();o.data=original.data;bpy.context.collection.objects.link(o);o.hide_render=False;o.hide_set(False);o.location+=Vector((x,y,.1))
# Water canal, banks, bridge, planters.
cube('Lagoon',(10.3,0,-.01),(1.2,18,.22),'water',.15)
for y in [-2.5,2.5]:cube('Footbridge',(10.3,y,.24),(1.6,1.4,.25),'wood',.08)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=96;scene.cycles.use_denoising=False
scene.render.resolution_x=1400;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.55,.75,.8,1);scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
bpy.ops.object.light_add(type='AREA',location=(-10,-12,22));bpy.context.object.data.energy=2300;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=14
bpy.ops.object.light_add(type='SUN',location=(0,0,10));bpy.context.object.rotation_euler=(.5,-.4,-.4);bpy.context.object.data.energy=2;bpy.context.object.data.angle=.2
bpy.ops.object.camera_add(location=(24,-31,28));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=33;scene.camera=camera
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(preview/'city-geometry-blender.png');scene.render.film_transparent=False
bpy.ops.wm.save_as_mainfile(filepath=str(root/'Builds/art-source.blend'))
bpy.ops.render.render(write_still=True)
# Separate puzzle-piece material and silhouette preview, same exported meshes.
for o in scene.objects:
 if o.type=='MESH':o.hide_render=True
current=[]
cube('Puzzle velvet tray',(0,0,-.6),(7.8,8.8,.5),'purple',.4)
rng=random.Random(44);names=['tile_cacao','tile_phone','tile_cash','tile_fuel','tile_bulb','tile_gear']
for row in range(7):
 for col in range(7):
  x=(col-3)*1.0;y=(3-row)*1.0
  cube('Recessed tile',(x,y,-.3),(.92,.92,.1),'navy',.16)
  for original in models[names[rng.randrange(6)]]:
   o=original.copy();o.data=original.data;bpy.context.collection.objects.link(o);o.hide_render=False;o.hide_set(False);o.location+=Vector((x,y,0))
camera.location=(0,-4,17);camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=10.5
scene.render.resolution_x=1000;scene.render.resolution_y=1100;scene.render.filepath=str(preview/'puzzle-geometry-blender.png');bpy.ops.render.render(write_still=True)
(root/'docs/art-manifest.json').write_text(json.dumps({'models':{n:len(objs) for n,objs in models.items()},'previewRenderer':'Blender Cycles; NOT Unity runtime screenshots','originalGeometry':True},indent=2))
print('PACO_ART_READY',len(models),len(layout))
