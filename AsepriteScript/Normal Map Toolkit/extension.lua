local NormalMirror = dofile("./NormalMirror.lua")
local NormalMapGenerator = dofile("./NormalMapGenerator.lua")

function init(plugin)

    plugin:newMenuGroup{
        id = "edit_normal_tools",
        title = "Normal Tools",
        group="edit_fx"
    }

    plugin:newCommand{
        id = "NormalMirror",
        title = "Mirror Normal Map",
        group = "edit_normal_tools",
        --onenabled = function()
        --    return app.activeSprite ~= nil and #app.range.cels > 0
        --end,
        onclick = function()        
            NormalMirror:showMain(plugin)          
        end
    }

    plugin:newCommand{
        id = "GenerateNormal",
        title = "Generate Normal Map",
        group = "edit_normal_tools",
        --onenabled = function()
        --    return app.activeSprite ~= nil and #app.range.cels > 0
        --end,
        onclick = function()        
            NormalMapGenerator:showMain(plugin)          
        end
    }
end