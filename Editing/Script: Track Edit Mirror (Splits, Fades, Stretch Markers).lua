-- Track Edit Mirror (Splits, Fades, Stretch Markers)
-- Author: soun-dev
-- Description: Mirrors edits from reference track to target track, 
-- including:
    -- Item positions and lengths
    -- Fades and fade shapes/directions
    -- Stretch markers with exact position
-- Instructions:
    -- 1. Select reference track FIRST.
    -- 2. Select target track SECOND.
    -- 3. Run script.
    -- NOTE: Deletes all items in target track before mirroring.
-- Version: 1.0

local function ClearStretchMarkerExtState()
    for i=1,20 do
        local val = reaper.GetExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i))
        if val == "" then
            break
        else
            reaper.DeleteExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i), false)
        end
    end
end

local function CopyStretchMarkers(take)
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local count = reaper.GetTakeNumStretchMarkers(take)
    if count == 0 then return end

    for i = 0, count -1 do
        local retval, pos, srcpos = reaper.GetTakeStretchMarker(take, i)
        local slope = reaper.GetTakeStretchMarkerSlope(take, i)
        local str = string.format("{%.9f %.9f %.9f}", pos / playRate, srcpos / playRate, slope)
        reaper.SetExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i+1), str, false)
    end
end

local function PasteStretchMarkers(take)
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    -- Clear existing stretch markers
    local existingCount = reaper.GetTakeNumStretchMarkers(take)
    for i = existingCount -1, 0, -1 do
        reaper.SetTakeStretchMarker(take, i, -1, -1) -- delete marker
    end

    for i=1,20 do
        local str = reaper.GetExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i))
        if str == "" then break end

        local pos, srcpos, slope = string.match(str, "{([%d%.%-e]+) ([%d%.%-e]+) ([%d%.%-e]+)}")
        if pos and srcpos and slope then
            pos = tonumber(pos) * playRate
            srcpos = tonumber(srcpos) * playRate
            slope = tonumber(slope)
            reaper.SetTakeStretchMarker(take, -1, pos, srcpos)
            local idx = reaper.GetTakeNumStretchMarkers(take) - 1
            reaper.SetTakeStretchMarkerSlope(take, idx, slope)
        else
            break
        end
    end
end

reaper.Undo_BeginBlock()

local ref_track = reaper.GetSelectedTrack(0, 0)
local tgt_track = reaper.GetSelectedTrack(0, 1)

if not ref_track or not tgt_track then
    reaper.ShowMessageBox("Please select reference track FIRST, then target track SECOND.", "Error", 0)
    return
end

-- Delete all items on target track
for i = reaper.CountTrackMediaItems(tgt_track) -1, 0, -1 do
    local item = reaper.GetTrackMediaItem(tgt_track, i)
    reaper.DeleteTrackMediaItem(tgt_track, item)
end

-- Loop through reference items and mirror
for i = 0, reaper.CountTrackMediaItems(ref_track) -1 do
    local ref_item = reaper.GetTrackMediaItem(ref_track, i)

    -- Copy item properties
    local pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")

    local fadein_len = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEINLEN")
    local fadeout_len = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEOUTLEN")
    local fadein_shape = reaper.GetMediaItemInfo_Value(ref_item, "C_FADEINSHAPE")
    local fadeout_shape = reaper.GetMediaItemInfo_Value(ref_item, "C_FADEOUTSHAPE")
    local fadein_dir = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEINDIR")
    local fadeout_dir = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEOUTDIR")

    local ref_take = reaper.GetActiveTake(ref_item)

    -- Create new item on target track
    local tgt_item = reaper.AddMediaItemToTrack(tgt_track)
    reaper.SetMediaItemInfo_Value(tgt_item, "D_POSITION", pos)
    reaper.SetMediaItemInfo_Value(tgt_item, "D_LENGTH", len)
    reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEINLEN", fadein_len)
    reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEOUTLEN", fadeout_len)
    reaper.SetMediaItemInfo_Value(tgt_item, "C_FADEINSHAPE", fadein_shape)
    reaper.SetMediaItemInfo_Value(tgt_item, "C_FADEOUTSHAPE", fadeout_shape)
    reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEINDIR", fadein_dir)
    reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEOUTDIR", fadeout_dir)

    -- Add take with same source
    if ref_take then
        local src = reaper.GetMediaItemTake_Source(ref_take)
        local new_take = reaper.AddTakeToMediaItem(tgt_item)
        reaper.SetMediaItemTake_Source(new_take, src)
        -- Copy take properties
        local startoffs = reaper.GetMediaItemTakeInfo_Value(ref_take, "D_STARTOFFS")
        local playrate = reaper.GetMediaItemTakeInfo_Value(ref_take, "D_PLAYRATE")
        reaper.SetMediaItemTakeInfo_Value(new_take, "D_STARTOFFS", startoffs)
        reaper.SetMediaItemTakeInfo_Value(new_take, "D_PLAYRATE", playrate)

        -- Copy stretch markers using ExtState method
        ClearStretchMarkerExtState()
        CopyStretchMarkers(ref_take)
        PasteStretchMarkers(new_take)
    end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Track Edit Mirror (Splits, Fades, Exact Stretch Markers)", -1)

