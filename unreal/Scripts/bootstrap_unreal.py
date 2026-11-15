"""Run inside Unreal Editor AFTER the project's C++ module has compiled.
No .umap or .uasset is fabricated outside the engine.
"""
import unreal
from pathlib import Path
root=Path(unreal.Paths.project_dir())
map_path='/Game/Paco/Maps/Main'
# Never replace an existing edited level automatically.
if unreal.EditorAssetLibrary.does_asset_exist(map_path):
 raise RuntimeError('Main existe déjà. Script arrêté pour préserver votre niveau.')
tasks=[]
for path in sorted((root/'SourceArt').glob('*.fbx')):
 task=unreal.AssetImportTask();task.filename=str(path);task.destination_path='/Game/Paco/Models';task.destination_name=path.stem;task.automated=True;task.save=True;task.replace_existing=False
 options=unreal.FbxImportUI();options.import_mesh=True;options.import_as_skeletal=False;options.import_animations=False;options.static_mesh_import_data.combine_meshes=True;options.static_mesh_import_data.convert_scene=True
 task.options=options;tasks.append(task)
task=unreal.AssetImportTask();task.filename=str(root/'SourceArt/paco-loading.png');task.destination_path='/Game/Paco/UI';task.destination_name='PacoLoading';task.automated=True;task.save=True;tasks.append(task)
unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tasks)
failed=[t.filename for t in tasks if not t.imported_object_paths]
if failed:raise RuntimeError('Import non validé : '+str(failed))
subsystem=unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
if not subsystem.new_level(map_path):raise RuntimeError('Création du niveau refusée')
world=unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).get_editor_world()
klass=unreal.load_class(None,'/Script/PacoUnreal.PacoGame')
if not klass:raise RuntimeError('Compiler PacoUnreal avant le bootstrap')
world.get_world_settings().set_editor_property('default_game_mode',klass)
if not subsystem.save_current_level():raise RuntimeError('Échec enregistrement niveau')
unreal.log('PACO : ressources importées et Main créé. Lancer Play pour validation manuelle.')
