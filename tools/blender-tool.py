from pathlib import Path
import bpy

from bpy.props import StringProperty, BoolProperty
from bpy_extras.io_utils import ImportHelper
from bpy.types import Operator

__author__   = "Dr Robot - Frédéric Delaunay"       ## original author
__email__    = "delaunay.fr@gmail.com"              ##
__version__  = "0.1.0"                              ## bare as it gets

## Sapiens Modding tool to import material.lua as Blender materials
## 

mats_importer = None

def new_FileBrowserClass(
        name, 
        title, 
        file_patt, 
        cb_execute,
        allow_override : bool = False,
    ):
    class Any_OT_FileBrowser(Operator, ImportHelper):
        
        bl_idname = name
        bl_label = title
        
        filter_glob: StringProperty(
            default=file_patt,
            options={'HIDDEN'}
        )

        if allow_override:
            override: BoolProperty(
                name='Override scene',
                description="Imported objects can override current scene's.",
                default=True,
            )

        def execute(self, context):
            msg = cb_execute(self)
            if msg:
                self.report({'ERROR'}, msg, icon='ERROR')

            return {'FINISHED'}
        
    return Any_OT_FileBrowser


def console_get():
    for area in bpy.context.screen.areas:
        if area.type == 'CONSOLE':
            for space in area.spaces:
                if space.type == 'CONSOLE':
                    return area, space
    return None, None

def console_write(text):
    area, space = console_get()
    if space is None:
        return

    context = bpy.context.copy()
    context.update(dict(
        space=space,
        area=area,
    ))
    for line in text.split("\n"):
        bpy.ops.console.scrollback_append(context, text=line, type='OUTPUT')


def show_msg(msg, title='Sapien Mat importer', icon='INFO', also_log=True):
    bpy.context.window_manager.popup_menu(lambda s, c:
        s.layout.label(text=msg),
        title=title, 
        icon=icon
    )
    also_log and console_write(msg)


def load_module(path : Path):
    global mats_importer
    try:
        ## import an unknown module name 
        from importlib import util
        spec = util.spec_from_file_location(
            'sapiens_modding.importer', path )
        mats_importer = util.module_from_spec(spec)
        spec.loader.exec_module(mats_importer)
    except ImportError as e:
        return f"could not import {self.filepath} : {e}"


def import_util(fb_operator):
    bpy.ops.sapiens.open_filebrowsermaterial('INVOKE_DEFAULT')
    return load_module(fb_operator.filepath)

def import_mats(fb_operator):
    global mats_importer
    ## 
    mats_lua = Path(fb_operator.filepath).read_text()
    mats_importer.set_cwd()
    materials = mats_importer.get_lua_materials(mats_lua)
    bMat_type = type(bpy.data.materials.new('delete_me'))

    ## now create the mats
    result = {'OK': 0, 'NOP': 0}
    failed_mats = []
    for mat_name, mat_def in materials.items():
        if mat_name in bpy.data.materials:
            if not fb_operator.override:
                result['NOP'] += 1
                continue
            else:
                mat = bpy.data.materials[mat_name]
        else:
            mat = bpy.data.materials.new(mat_name)
        # edit material
        edited = False
        if hasattr(mat, 'diffuse_color')    and 'color' in mat_def:
            for i, c in enumerate(mat_def['color']):
                mat.diffuse_color[i] = c
                edited = True
        if hasattr(mat, 'metallic')         and 'metal' in mat_def:
            mat.metallic = mat_def['metal']
            edited = True
        if hasattr(mat, 'roughness')        and 'roughness' in mat_def:
            mat.roughness = mat_def['roughness']
            edited = True

        if edited:
            result['OK'] += 1
        else:
            failed_mats.append(mat_name)
            console_write(f"\tmat: {dir(mat)}\n\tmat_def: {dir(mat_def)}")
    failed_str = f" for {', '.join(failed_mats)}." if len(failed_mats) > 0 else None
    show_msg(f"import done. Result: {result['OK']} imported, {result['NOP']} ignored, "
        f"and {len(failed_mats)} failed{failed_str if failed_str else ''}.")


## Create 2 FileBrowser operators to locate our files   #TDL: find a more elegant way to do this?
Sapiens_OT_Open_FilebrowserImport = new_FileBrowserClass(
    "sapiens.open_filebrowserimport",
    "Locate script utility",
    "*_importer.py",
    import_util
)
Sapiens_OT_Open_FilebrowserMaterial = new_FileBrowserClass(
    "sapiens.open_filebrowsermaterial",
    "Locate material.lua",
    "*material.lua",
    import_mats,
    True
)

if __name__ == "__main__":
    ## file browser for material.lua is used unconditionally
    bpy.utils.register_class(Sapiens_OT_Open_FilebrowserMaterial)

    path_this_script = Path(bpy.context.space_data.text.filepath)
    path_util_script = path_this_script.with_name('material_lib_importer.py')
    if path_util_script.exists():
        load_module(path_util_script)
        ## open material.lua and import materials
        bpy.ops.sapiens.open_filebrowsermaterial('INVOKE_DEFAULT')
    else:
        # register for one-shot
        bpy.utils.register_class(Sapiens_OT_Open_FilebrowserImport)
        ## open python script, then material.lua and import materials
        bpy.ops.sapiens.open_filebrowserimport('INVOKE_DEFAULT')

