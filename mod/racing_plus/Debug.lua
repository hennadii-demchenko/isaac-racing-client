local Debug = {}

-- Includes
local g         = require("racing_plus/globals")
local Sprites   = require("racing_plus/sprites")
local FastClear = require("racing_plus/fastclear")
local Speedrun  = require("racing_plus/speedrun")
local Season8   = require("racing_plus/season8")

-- ModCallbacks.MC_USE_ITEM (3)
function Debug:Main()
  -- Enable debug mode
  g.debug = true

  -- Print out various debug information to Isaac's log.txt
  Isaac.DebugString("+-------------------------+")
  Isaac.DebugString("| Entering test callback. |")
  Isaac.DebugString("+-------------------------+")

  local globalsToPrint = {
    "run",
    "race",
    "raceVars",
  }

  for _, var in ipairs(globalsToPrint) do
    Isaac.DebugString(var .. ":")
    for k, v in pairs(g[var]) do
      if type(v) == "table" then
        Isaac.DebugString("  " .. k .. ': ')
        for k2, v2 in pairs(v) do
          if type(v2) == "table" then
            Isaac.DebugString("    " .. k2 .. ': ')
            for k3, v3 in pairs(v2) do
              Isaac.DebugString("      " .. k3 .. ': ' .. tostring(v3))
            end
          else
            Isaac.DebugString("    " .. k2 .. ': ' .. tostring(v2))
          end
        end
      else
        Isaac.DebugString("  " .. k .. ': ' .. tostring(v))
      end
    end
  end

  Isaac.DebugString("speedrun:")
  for k, v in pairs(Speedrun) do
    if type(v) == "string" or
       type(v) == "number" or
       type(v) == "boolean" then

      Isaac.DebugString("  " .. k .. ": " .. tostring(v))
    end
  end

  Isaac.DebugString("sprites:")
  for k, v in pairs(Sprites.sprites) do
    for k2, v2 in pairs(v) do
      if k2 == "spriteName" and v2 ~= 0 then
        Isaac.DebugString("  " .. k .. ":")
        Isaac.DebugString("    " .. k2 .. ": " .. tostring(v2))
      end
    end
  end

  Isaac.DebugString("FastClear.aliveEnemies:")
  for k, v in pairs(FastClear.aliveEnemies) do
    Isaac.DebugString("  " .. k .. ": " .. tostring(v))
  end

  --
  -- Test stuff
  --

  --g.raceVars.finished = true
  --Sprites:Init("place", 1)

  -- New Booster Pack item images testing
  --[[
  Sprites:Init("diversity-item1", 519) -- Active Item
  Sprites:Init("diversity-item2", 531) -- Passive Item
  Sprites:Init("diversity-item3", 532) -- Passive Item
  Sprites:Init("diversity-item4", 534) -- Passive Item
  Sprites:Init("diversity-item5", 125) -- Trinket
  --]]

  for i = 1, 100 do
    Season8.touchedItems[#Season8.touchedItems + 1] = 1
  end

  --
  -- End test stuff
  --

  Isaac.DebugString("+------------------------+")
  Isaac.DebugString("| Exiting test callback. |")
  Isaac.DebugString("+------------------------+")

  -- Display the "use" animation
  return true
end

return Debug
