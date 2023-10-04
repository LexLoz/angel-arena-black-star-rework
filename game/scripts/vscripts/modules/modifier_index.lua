function PathTemplate(moduleName)
    return "modules/" .. moduleName .. "/modifier_index"
end

require(PathTemplate("custom_runes"))
require(PathTemplate("structures"))
require(PathTemplate("custom_talents"))
require(PathTemplate("hero_selection"))
require(PathTemplate("simpleai"))
require(PathTemplate("spawner"))
require(PathTemplate("weather"))
require(PathTemplate("dynamic_wearables"))
require(PathTemplate("weather"))