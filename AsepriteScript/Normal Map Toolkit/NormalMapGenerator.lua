local NormalMapGenerator = {}


function NormalMapGenerator:showMain(pl)

    NormalMapGenerator.pref = pl.preferences;
  
    NormalMapGenerator.dlg = Dialog{
      title="Generate Normal Map",
      onclose=function()
        NormalMapGenerator.pref.normalLayer = NormalMapGenerator.dlg.data.normalLayer
        NormalMapGenerator.pref.invert = NormalMapGenerator.dlg.data.invert
        NormalMapGenerator.pref.discrete = NormalMapGenerator.dlg.data.discrete
        NormalMapGenerator.pref.numColors = NormalMapGenerator.dlg.data.numColors
        NormalMapGenerator.pref.heightMapLayer = NormalMapGenerator.dlg.data.heightMapLayer
        NormalMapGenerator.pref.useSelectedLayer = NormalMapGenerator.dlg.data.useSelectedLayer
        NormalMapGenerator.pref.repeating = NormalMapGenerator.dlg.data.repeating
        NormalMapGenerator.pref.edgeIntensity = NormalMapGenerator.dlg.data.edgeIntensity
        NormalMapGenerator.pref.colorChannel = NormalMapGenerator.dlg.data.colorChannel
      end
    }

    NormalMapGenerator.dlg
    :separator {id="sep0", text ="Layers"}
    :check { id="useSelectedLayer", label="Use Selected Layer as Input", selected=NormalMapGenerator.pref.useSelectedLayer or true , onclick=function() NormalMapGenerator:ToggleHeightMapEntry() end}
    :entry { id="heightMapLayer", label="Height Map Layer (Input)", text=NormalMapGenerator.pref.heightMapLayer or "HeightMap", enabled = not NormalMapGenerator.dlg.data.useSelectedLayer or false}
    :entry { id="normalLayer", label="Normal Layer (Output)", text=NormalMapGenerator.pref.normalLayer or "Normal"}
    :check { id="invert", label="Invert Normal Layer", selected=NormalMapGenerator.pref.invert or false }
    :separator { id="sep1", text = "Settings" }
    :combobox { id="colorChannel", label="Color Channel", option=NormalMapGenerator.pref.colorChannel or "Red", options={ "red", "green", "blue", "gray","hue","value","lightness","hsvSaturation","hslSaturation"}}
    :check  { id="repeating", label="Repeating Texture", selected=NormalMapGenerator.pref.repeating or false}
    :entry { id="edgeIntensity", label="Edge Intensity", text=NormalMapGenerator.pref.edgeIntensity or "0.1"}
    :check { id="discrete", label="Use Discrete Colors", selected=NormalMapGenerator.pref.discrete or false, onclick=function() NormalMapGenerator:ToggleNumColors() end }
    :entry { id="numColors", label="# Colors per Direction", text=NormalMapGenerator.pref.numColors or "11", enabled = NormalMapGenerator.pref.discrete or false}
    :button{id="GenerateNormal", text="Generate",onclick=function() NormalMapGenerator:GenerateNormalMap() end }

    NormalMapGenerator.dlg:show{ wait=false, bounds=ColorShadingWindowBounds }
end

function NormalMapGenerator:ToggleHeightMapEntry() 
  if NormalMapGenerator.dlg.data.useSelectedLayer then
    NormalMapGenerator.dlg:modify{ id="heightMapLayer", enabled=false }
  else
    NormalMapGenerator.dlg:modify{ id="heightMapLayer", enabled=true }
  end
  NormalMapGenerator.dlg:repaint()
end

function NormalMapGenerator:ToggleNumColors()
  if NormalMapGenerator.dlg.data.discrete then
    NormalMapGenerator.dlg:modify{ id="numColors", enabled=true }
  else
    NormalMapGenerator.dlg:modify{ id="numColors", enabled=false }
  end
  NormalMapGenerator.dlg:repaint()
end

function NormalMapGenerator:GenerateNormalMap()

  -- get the input layer
  local inLayer = nil
  if NormalMapGenerator.dlg.data.useSelectedLayer then
    inLayer = app.layer
    if inLayer == nil then
      app.alert("No layer selected")
      return
    end
  else
    inLayer = NormalMapGenerator:FindLayer(NormalMapGenerator.dlg.data.heightMapLayer)

    if inLayer == nil then
      app.alert("Layer not found")
    return
    end
  end
  
  -- get the output layer
  local outLayerName = NormalMapGenerator.dlg.data.normalLayer	
  local outLayer = NormalMapGenerator:FindLayer(outLayerName)
  if outLayer == nil then
      outLayer = app.activeSprite:newLayer()
      outLayer.name = outLayerName
  end
  for i = 1,#app.activeSprite.frames do    
    local cel = inLayer:cel(i) 
    if cel ~= nil then
    local image = cel.image
    
      local outputImg = NormalMapGenerator:SobelOperator(image, NormalMapGenerator.dlg.data.invert, NormalMapGenerator.dlg.data.discrete, NormalMapGenerator.dlg.data.repeating)

      app.activeSprite:newCel(outLayer, i, outputImg, cel.position) 
      app.refresh()
    end
  end
end


function NormalMapGenerator:SobelOperator(image, inverted, discrete, repeating)
  -- Define the Sobel kernels for horizontal and vertical edges
  
    -- Initialize the output image with zeros
    local output = Image(image.spec)
   -- local kernel_x = {
   --   {-1, 0, 1},
   --   {-2, 0, 2},
   --   {-1, 0, 1}
   -- }
   -- local kernel_y = {
   --   {-1, -2, -1},
   --   {0, 0, 0},
   --   {1, 2, 1}
   -- }
    -- Compute the Sobel gradients for each pixel in the input image
  for x = 0, image.width-1 do
    for y = 0, image.height-1 do

      local centerPixel = Color(image:getPixel(x, y))

      if centerPixel.alpha == 0 then goto continue end --skip transparent pixels
      
      local fallbackColor = Color{red= (1- NormalMapGenerator.dlg.data.edgeIntensity) *centerPixel.red, green=(1- NormalMapGenerator.dlg.data.edgeIntensity) *centerPixel.red, blue=(1- NormalMapGenerator.dlg.data.edgeIntensity) *centerPixel.red} -- this fallback color is used for pixels outside the image or transparent pixels. It allows the user to control the intensity of the edge pixels of the normal map
      --local fallbackColor = centerPixel
      local grid = {}
      
    -- go through the surrounding pixels and get the color values
      for i = 1, 3 do
        grid[i] = {}
        for j = 1, 3 do
          local xCoord = (x -2 + i) --get the coords of the surrounding pixel, from -1 to 1
          local yCoord = (y -2 + j) 

          local c = nil
          if repeating then -- if repeating is enabled, wrap the coords around the image
            xCoord = xCoord % image.width
            yCoord = yCoord % image.height
            c = Color(image:getPixel(xCoord, yCoord))
          else -- if repeating is disabled, use the fallback color if the coords are outside the image
            if xCoord < 0 or xCoord >= image.width or yCoord < 0 or yCoord >= image.height then 
              c = fallbackColor
            else
              c = Color(image:getPixel(xCoord, yCoord))
            end
          end        
          
          if c.alpha == 0 then -- if the pixel is transparent, use the fallback color
            c = fallbackColor
          end
          grid[i][j] = c
        end
      end

     local colorField = NormalMapGenerator.dlg.data.colorChannel
     --local dfdx = (grid[1][1].red + 2 * grid[1][2].red + grid[1][3].red) - (grid[3][1].red + 2 * grid[3][2].red + grid[3][3].red)
     --local dfdy = (grid[1][1].red + 2 * grid[2][1].red + grid[3][1].red) - (grid[1][3].red + 2 * grid[2][3].red + grid[3][3].red)

     local dfdx = (grid[1][1][colorField] + 2 * grid[1][2][colorField] + grid[1][3][colorField]) - (grid[3][1][colorField] + 2 * grid[3][2][colorField] + grid[3][3][colorField])
     local dfdy = (grid[1][1][colorField] + 2 * grid[2][1][colorField] + grid[3][1][colorField]) - (grid[1][3][colorField] + 2 * grid[2][3][colorField] + grid[3][3][colorField])

     --app.alert(grid[2][2][colorField])
      -- Calculate the normal vector using the partial derivatives
     local normal_x = dfdx
     local normal_y = -dfdy

     if colorField == "red" or colorField == "green" or colorField == "blue" or colorField =="gray" then
      normal_x = dfdx / 255.0
      normal_y = -dfdy / 255.0
     elseif colorField == "hue" then
      normal_x = dfdx / 360.0
      normal_y = -dfdy / 360.0
     end -- else assume the color field is a value between 0 and 1 (value, lightness, saturation)
     if inverted then
        normal_y = -normal_y
        normal_x = -normal_x
     end

      local normal_z = 1.0 / math.sqrt(normal_x^2 + normal_y^2 + 1)


      -- Normalize the normal vector
      normal_x = normal_x * normal_z
      normal_y = normal_y * normal_z

      -- Convert the normal vector to a color
      local r = (normal_x + 1) / 2 * 255
      local g = (normal_y + 1) / 2 * 255
      local b = normal_z * 255

      if discrete then
          local numColors = tonumber(NormalMapGenerator.dlg.data.numColors)
          r = math.floor((normal_x * 0.5 + 0.5) * numColors) * (255 / (numColors - 1))
          g = math.floor((normal_y * 0.5 + 0.5) * numColors) * (255 / (numColors - 1)) 
      end



      local a = 255
      output:drawPixel(x, y, Color{red=r, green=g, blue=b, alpha=a})
      ::continue::
    end
  end
  
  return output
end


function NormalMapGenerator:GetColorFromPixel(image, x, y, centerColor)
  local pixel = Color(image:getPixel(x, y))
  if pixel.alpha == 0 then
    return Color{red= (1-0.1) *centerColor.red, green=0, blue=0, alpha=255}
  end
  return pixel
end


function NormalMapGenerator:FindLayer(layerName)
  local sprite = app.activeSprite
  for i = 1,#sprite.layers do    
    if sprite.layers[i].name == layerName then
      return sprite.layers[i]
    end
  end
  return nil
end

return NormalMapGenerator