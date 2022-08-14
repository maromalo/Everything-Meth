import "base/native/DB_001" for DBManager, DBForeignFile
import "base/native" for Logger, IO
import "base/native/Environment_001" for Environment

class Material_Config_Loader {
    construct new(filename) {
        _custom_file = Environment.mod_directory + "/wren/material_configs/contour/" + filename
        _default_file = Environment.mod_directory + "/wren/material_configs/default/" + filename
    }
    load_file(name, ext) {
        if (IO.info("mods/saves/everythingmeth_contours.txt") == "file") {
            if (IO.read("mods/saves/everythingmeth_contours.txt") == "true") {
                Logger.log("Loading custom material_config: " + _custom_file)
                return DBForeignFile.of_file(_custom_file)
            }
        } else {
            Logger.log("Could not find Everything Meth's contours savefile.")
        }
        //not exactly ideal, however until i figure out how the fuck contours in lua work, this will have to do
        return DBForeignFile.of_file(_default_file)
    }
}

var mu_hook = DBManager.register_asset_hook("units/payday2/pickups/gen_pku_methlab_muriatic_acid/gen_pku_methlab_muriatic_acid", "material_config")
mu_hook.wren_loader = Material_Config_Loader.new("gen_pku_methlab_muriatic_acid.material_config")

var cs_hook = DBManager.register_asset_hook("units/payday2/pickups/gen_pku_methlab_caustic_soda/gen_pku_methlab_caustic_soda", "material_config")
cs_hook.wren_loader = Material_Config_Loader.new("gen_pku_methlab_caustic_soda.material_config")

var hcl_hook = DBManager.register_asset_hook("units/payday2/pickups/gen_pku_methlab_hydrogen_cloride/gen_pku_methlab_hydrogen_cloride", "material_config")
hcl_hook.wren_loader = Material_Config_Loader.new("gen_pku_methlab_hydrogen_cloride.material_config")