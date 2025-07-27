-- @description Low-Lag Smart Retake from Play or Edit Cursor
-- @version 1.3 (optimized playback punch-in)
-- @author You

local playState = reaper.GetPlayState()
local isPlaying = (playState & 1) == 1
local isRecording = (playState & 4) == 4

-- Load last position
local prevPos = tonumber(reaper.GetExtState("RECORD_LOOP", "PrevPos"))
local recordPos = nil

reaper.Undo_BeginBlock()

if isRecording then
  -- Delete and retry
  reaper.Main_OnCommand(1013, 0) -- Stop
  reaper.Main_OnCommand(40006, 0) -- Delete all recorded media
  if prevPos then
    reaper.SetEditCurPos(prevPos, true, false)
    recordPos = prevPos
  else
    recordPos = reaper.GetCursorPosition()
  end

  reaper.Main_OnCommand(1016, 0)
  reaper.Main_OnCommand(1013, 0)
  reaper.Main_OnCommand(1017, 0) -- Record

else
  if isPlaying then
    -- Jump and start record without double stop
    recordPos = reaper.GetPlayPosition()
    reaper.SetEditCurPos(recordPos, true, false)
    reaper.Main_OnCommand(1013, 0) -- quick stop
    reaper.Main_OnCommand(1017, 0) -- Record
  else
    -- Stopped: record from edit cursor
    recordPos = reaper.GetCursorPosition()
    reaper.SetEditCurPos(recordPos, true, false)
    reaper.Main_OnCommand(1016, 0)
    reaper.Main_OnCommand(1013, 0)
    reaper.Main_OnCommand(1017, 0) -- Record
  end
end

-- Save position for re-record
reaper.SetExtState("RECORD_LOOP", "PrevPos", tostring(recordPos), false)

reaper.Undo_EndBlock("Low-Lag Smart Retake", -1)
