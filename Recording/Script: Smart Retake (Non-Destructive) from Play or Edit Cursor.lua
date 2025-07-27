-- Smart Retake (Non-Destructive) from Play or Edit Cursor
-- Author: soun-dev
-- Description: Performs a smart retake from the play or edit cursor with minimal delay, 
-- without deleting previous takes. Ideal for fast, non-destructive punch-ins.
-- Version: 1.0

local playState = reaper.GetPlayState()
local isPlaying = (playState & 1) == 1
local isRecording = (playState & 4) == 4

-- Load last position
local prevPos = tonumber(reaper.GetExtState("RECORD_LOOP", "PrevPos"))
local recordPos = nil

reaper.Undo_BeginBlock()

if isRecording then
  -- Stop recording and return to previous retake point
  reaper.Main_OnCommand(1013, 0) -- Stop
  if prevPos then
    reaper.SetEditCurPos(prevPos, true, false)
    recordPos = prevPos
  else
    recordPos = reaper.GetCursorPosition()
  end

  reaper.Main_OnCommand(1016, 0) -- Prepare for recording
  reaper.Main_OnCommand(1013, 0) -- Stop again just in case
  reaper.Main_OnCommand(1017, 0) -- Start recording

else
  if isPlaying then
    -- Jump to play position and start recording
    recordPos = reaper.GetPlayPosition()
    reaper.SetEditCurPos(recordPos, true, false)
    reaper.Main_OnCommand(1013, 0) -- Stop
    reaper.Main_OnCommand(1017, 0) -- Record
  else
    -- Stopped: record from edit cursor
    recordPos = reaper.GetCursorPosition()
    reaper.SetEditCurPos(recordPos, true, false)
    reaper.Main_OnCommand(1016, 0) -- Prepare recording
    reaper.Main_OnCommand(1013, 0)
    reaper.Main_OnCommand(1017, 0) -- Record
  end
end

-- Save position for next re-record
reaper.SetExtState("RECORD_LOOP", "PrevPos", tostring(recordPos), false)

reaper.Undo_EndBlock("Low-Lag Smart Retake (Non-Destructive)", -1)
