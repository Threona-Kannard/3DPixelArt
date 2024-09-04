local NormalMirror = {}

-- Show the main dialog
function NormalMirror:showMain(pl)

    NormalMirror.pref = pl.preferences;
  
    NormalMirror.dlg = Dialog{
      title="Mirror Normal Map",
      onclose=function()
        NormalMirror.pref.vertAxis = NormalMirror.dlg.data.vertAxis
        NormalMirror.pref.horiAxis = NormalMirror.dlg.data.horiAxis
        NormalMirror.pref.useSelection = NormalMirror.dlg.data.useSelection
        NormalMirror.pref.mirrorNormalLayer = NormalMirror.dlg.data.mirrorNormalLayer
        NormalMirror.pref.mirrorLayerSuffix = NormalMirror.dlg.data.mirrorLayerSuffix

      end
    }

    --NormalMirror.dlg.bounds = Rectangle(0,0, 300, 300)

    NormalMirror.dlg
    :separator {id="sep0", label="Layers"}
    :check { id="useSelection", label="Use Selected Layer as Input", selected=NormalMirror.pref.useSelection or false , onclick=function() NormalMirror:ToggleNormalLayer() end}
    :entry { id="mirrorNormalLayer", label="Normal Map Layer (Input)", text=NormalMirror.pref.mirrorNormalLayer or "Normal", enabled = not NormalMirror.pref.useSelection or true}
    :entry { id="mirrorLayerSuffix", label="Mirror Layer Suffix", text=NormalMirror.pref.mirrorLayerSuffix or "_Mirror"}
    :separator {id="sep1", text="Mirror Axes"}
    :entry{ id="vertAxis", label="Pos X (Vertical Axis)", text=NormalMirror.pref.vertAxis or "0" }
    :button{id="btnMirrorVertical", text="Mirror Horizontal (Left - Right)",onclick=function() NormalMirror:MirrorSprite(true) end }
    :entry{ id="horiAxis", label="Pos Y (Horizontal Axis)", text=NormalMirror.pref.horiAxis or "0" }
    :button{id="btnMirrorHorizontal", text="Mirror Vertical (Up - Down)",onclick=function() NormalMirror:MirrorSprite(false) end }

    NormalMirror.dlg:show{ wait=false, bounds=ColorShadingWindowBounds }
end

function NormalMirror:ToggleNormalLayer() 
  if NormalMirror.dlg.data.useSelection then
    NormalMirror.dlg:modify{ id="mirrorNormalLayer", enabled=false }
  else
    NormalMirror.dlg:modify{ id="mirrorNormalLayer", enabled=true }
  end
  NormalMirror.dlg:repaint()
end

-- Mirror the normal map
function NormalMirror:MirrorSprite(vertical)
--iterate through each pixel of the sprite and mirror each pixel along  a variable mirror
 local cel = nil
 local outLayerName = nil
 local inLayer = nil
  if NormalMirror.dlg.data.useSelection then
    inLayer = app.layer
    outLayerName = app.layer.name
  else
    outLayerName = NormalMirror.dlg.data.mirrorNormalLayer
    inLayer = NormalMirror:FindLayer(outLayerName)
    
    if inLayer == nil then
      app.alert("Layer not found")
    return
    end    
  end

 outLayerName = outLayerName .. NormalMirror.dlg.data.mirrorLayerSuffix

 local outLayer = NormalMirror:FindLayer(outLayerName)
  if outLayer == nil then
      outLayer = app.activeSprite:newLayer()
      outLayer.name = outLayerName
  end


  for i = 1,#app.activeSprite.frames do  
    cel = inLayer:cel(i)
    if cel ~= nil then
      local image = cel.image
      local outputImg = Image(app.activeSprite.width, app.activeSprite.height, image.colorMode)
      if vertical then
        NormalMirror:MirrorVertical(image, cel, outputImg)
      else
        NormalMirror:MirrorHorizontal(image, cel, outputImg)
      end

      app.activeSprite:newCel(outLayer, i, outputImg)
      app.refresh() 
    end
  end
end

-- Mirror along a vertical edge
function NormalMirror:MirrorVertical(image, cel,  outputImg)
  local vertAxis = tonumber(NormalMirror.dlg.data.vertAxis)
  for it in image:pixels()  do
      local realX = it.x + cel.position.x
      local distance = vertAxis - realX
      local mirroredX = realX -1 + distance*2

      local color = Color(it())

      if color.alpha == 255 then
        --local mirrorColor = NormalMirror:InvertNormalColor(color)
        color.red = -1 * color.red  + 256
        outputImg:drawPixel(mirroredX, it.y + cel.position.y, color)
      end

  end

end

-- Mirror along a horizontal edge
function NormalMirror:MirrorHorizontal(image, cel, outputImg)
  local horiAxis = tonumber(NormalMirror.dlg.data.horiAxis)
  for it in image:pixels()  do
      local realY = it.y + cel.position.y
      local distance = horiAxis - realY
      local mirroredY = realY -1 + distance*2

      local color = Color(it())

      if color.alpha == 255 then
        --local mirrorColor = NormalMirror:InvertNormalColor(color)
        color.green = -1 * color.green  + 256
        outputImg:drawPixel(it.x + cel.position.x, mirroredY, color)
      end

  end

end

function NormalMirror:InvertNormalColor(color)

    local red = -1 * color.red  + 256
    local green = color.green
    local blue = color.blue
    return Color{red=red, green=green, blue=blue}
end

-- Find a layer
function NormalMirror:FindLayer(layerName)
  local sprite = app.activeSprite
  for i = 1,#sprite.layers do    
    if sprite.layers[i].name == layerName then
      return sprite.layers[i]
    end
  end
  return nil
end


return NormalMirror