local Speedrun = {}

-- Includes
local g = require("racing_plus/globals")

-- The challenge table maps challenge names to abbreviations and
-- the number of elements in the "character order" table
Speedrun.challengeTable = {
  [Isaac.GetChallengeIdByName("R+9 (Season 1)")]  = {"R9S1",  9},
  [Isaac.GetChallengeIdByName("R+14 (Season 1)")] = {"R14S1", 14},
  [Isaac.GetChallengeIdByName("R+7 (Season 2)")]  = {"R7S2",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 3)")]  = {"R7S3",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 4)")]  = {"R7S4",  14}, -- (7 characters + 7 starting items)
  [Isaac.GetChallengeIdByName("R+7 (Season 5)")]  = {"R7S5",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 6)")]  = {"R7S6",  11}, -- (7 characters + 3 item bans + 1 big 4 item ban)
  [Isaac.GetChallengeIdByName("R+7 (Season 7)")]  = {"R7S7",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 8)")]  = {"R7S8",  7},
  [Isaac.GetChallengeIdByName("R+15 (Vanilla)")]  = {"R15V",  15},
}

-- Variables
Speedrun.sprites = {} -- Reset at the beginning of a new run (in the PostGameStarted callback)
Speedrun.charNum = 1 -- Reset expliticly from a long-reset and on the first reset after a finish
Speedrun.startedTime = 0 -- Reset expliticly if we are on the first character
Speedrun.startedFrame = 0 -- Reset expliticly if we are on the first character
Speedrun.startedCharTime = 0 -- Reset expliticly if we are on the first character and when we touch a Checkpoint
Speedrun.charRunTimes = {} -- Reset expliticly if we are on the first character
Speedrun.finished = false -- Reset at the beginning of every run
Speedrun.finishedTime = 0 -- Reset at the beginning of every run
Speedrun.finishedFrames = 0 -- Reset at the beginning of every run
Speedrun.fastReset = false -- Reset expliticly when we detect a fast reset
Speedrun.spawnedCheckpoint = false -- Reset after we touch the checkpoint and at the beginning of a new run
Speedrun.fadeFrame = 0 -- Reset after we touch the checkpoint and at the beginning of a new run
Speedrun.resetFrame = 0 -- Reset after we execute the "restart" command and at the beginning of a new run
Speedrun.liveSplitReset = false

-- Season 5, 6, & 7 variables
Speedrun.remainingItemStarts = {} -- Reset at the beginning of a new run on the first character
Speedrun.selectedItemStarts = {} -- Reset at the beginning of a new run on the first character

-- Called from the PostUpdate callback (the "CheckEntities:NonGrid()" function)
function Speedrun:Finish()
  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)

  -- Record how long this run took
  local elapsedTime = Isaac.GetTime() - Speedrun.startedCharTime
  Speedrun.charRunTimes[#Speedrun.charRunTimes + 1] = elapsedTime

  -- Show the run summary (including the average time per character)
  g.run.endOfRunText = true

  -- Finish the speedrun
  Speedrun.finished = true
  Speedrun.finishedTime = Isaac.GetTime() - Speedrun.startedTime
  Speedrun.finishedFrames = Isaac.GetFrameCount() - Speedrun.startedFrame

  -- Play a sound effect
  g.sfx:Play(SoundEffect.SOUND_SPEEDRUN_FINISH, 1.5, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch

  -- Fireworks will play on the next frame (from the PostUpdate callback)
end

-- Don't move to the first character of the speedrun if we die
function Speedrun:PostGameEnd(gameOver)
  if not gameOver then
    return
  end

  if not Speedrun:InSpeedrun() then
    return
  end

  Speedrun.fastReset = true
  Isaac.DebugString("Game over detected.")
end

function Speedrun:InSpeedrun()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 8)") or
     challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then

    return true
  else
    return false
  end
end

function Speedrun:CheckValidCharOrder()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- There is no character order for season 5
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    return true
  end

  -- Otherwise, we get the character order from the Racing+ Data mod's "save#.dat" file
  if RacingPlusData == nil then
    return false
  end
  local abbreviation = Speedrun.challengeTable[challenge][1]
  local numElements = Speedrun.challengeTable[challenge][2]
  if abbreviation == nil then
    Isaac.DebugString("Error: Failed to find challenge \"" .. challenge .. "\" in the challengeTable.")
    return false
  end
  local charOrder = RacingPlusData:Get("charOrder-" .. abbreviation)
  if charOrder == nil then
    return false
  end
  if type(charOrder) ~= "table" then
    return false
  end
  if #charOrder ~= numElements then
    return false
  end

  return true
end

function Speedrun:GetCurrentChar()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- In season 5, we always return the character ID of "Random Baby"
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    local randomBabyType = Isaac.GetPlayerTypeByName("Random Baby")
    if randomBabyType == -1 then
      return 0
    end
    return randomBabyType
  end

  -- Otherwise, we get the value from the Racing+ Data mod's "save#.dat" file
  if RacingPlusData == nil then
    return 0
  end
  local abbreviation = Speedrun.challengeTable[challenge][1]
  if abbreviation == nil then
    Isaac.DebugString("Error: Failed to find challenge \"" .. challenge .. "\" in the challengeTable.")
    return false
  end
  local charOrder = RacingPlusData:Get("charOrder-" .. abbreviation)
  if charOrder == nil then
    return 0
  end
  if type(charOrder) ~= "table" then
    return 0
  end
  local charNum = charOrder[Speedrun.charNum]
  if charNum == nil then
    return 0
  end
  return charNum
end

function Speedrun:IsOnFinalCharacter()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    return Speedrun.charNum == 15
  elseif challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    return Speedrun.charNum == 9
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    return Speedrun.charNum == 14
  end
  return Speedrun.charNum == 7
end

function Speedrun:GetAverageTimePerCharacter()
  local totalMilliseconds = 0
  for _, milliseconds in ipairs(Speedrun.charRunTimes) do
    totalMilliseconds = totalMilliseconds + milliseconds
  end
  local averageMilliseconds = totalMilliseconds / #Speedrun.charRunTimes
  local averageSeconds = averageMilliseconds / 1000
  local timeTable = g:ConvertTimeToString(averageSeconds)

  -- e.g. [minute1][minute2]:[second1][second2]
  return tostring(timeTable[2]) .. tostring(timeTable[3]) .. ":" .. tostring(timeTable[4]) .. tostring(timeTable[5])
end

return Speedrun
