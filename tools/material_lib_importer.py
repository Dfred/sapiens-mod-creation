from os import chdir
from pathlib import Path


import lupa.luajit21 as lupa
lua = lupa.LuaRuntime()


def get_lua_materials(lua_source : str):
    ## this requires simplifyied common/*.lua, otherwise (mj)require
    ## dependencies will eventually try loading game binary objects.
    lua_result = lua.execute('mj = require "common/mj"\n'+lua_source)
    print("LUA FUNCTION RESULT:", dict(zip(lua_result, lua_result.values())))

    lua_materials = lua_result['materials']()
    print(f"LUA MATERIALS: {len(list(lua_materials))}")

    lua_materials_named = dict((k,lua_materials[k]) for k in list(lua_materials) if type(k) != type(1))
    materials = {}
    for mn_k, mn_v in sorted(lua_materials_named.items()):
        mat = dict((k, mn_v[k]) for k in list(mn_v) if k not in ['index', 'key'])
        # get rid of lua type
        mat['color'] = [mat['color'].x, mat['color'].y, mat['color'].z]
        materials[mn_k] = mat
    return materials


def set_cwd():
    ## move current working directory to this script directory so our overrides are found
    cwd = Path(__file__).parent
    print("changing cwd to", cwd)
    chdir(cwd)

    
if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        raise ArgumentError("missing path to material.lua")
    path_materials = Path(sys.argv[1])
    if not path_materials.exists():
        raise ArgumentError(f"file {path_materials} does not exist" )

    set_cwd()

    ## do the work now
    print(f"using {lua.lua_implementation} (compiled with {lupa.LUA_VERSION})")    
    lua_materials = get_lua_materials(path_materials.read_text())
    print(lua_materials)
    print("done")
