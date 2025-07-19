-- Close Video Window silently
-- ReaScript Name: Close Video Window (Silent)
-- Author: Nirmal Dev
-- Description: Silently closes the Video window if open.
-- Version: 1.1

local videoWindowCmdID = 50125 -- View: Video window

if reaper.GetToggleCommandState(videoWindowCmdID) == 1 then
  reaper.Main_OnCommand(videoWindowCmdID, 0)
end
