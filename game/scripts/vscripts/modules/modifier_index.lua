function PathTemplate(moduleName)
    return "modules/" .. moduleName .. "/modifier_index"
end

require(PathTemplate("kills"))
require(PathTemplate("weather"))
require(PathTemplate("custom_runes"))
require(PathTemplate("custom_talents"))
require(PathTemplate("bosses"))
require(PathTemplate("spawner"))
require(PathTemplate("structures"))
require(PathTemplate("simpleai"))
require(PathTemplate("dynamic_wearables"))
require(PathTemplate("hero_selection"))
