-- Track Edit Mirror (Splits, Fades, Stretch Markers)
-- Author: soun-dev
-- Description: Mirrors edits from reference track to target track, 
-- including:
    -- Item positions and lengths
    -- Fades and fade shapes/directions
    -- Stretch markers
-- Instructions:
    -- 1. Select reference track FIRST.
    -- 2. Select target track SECOND.
    -- 3. Run script.
    -- NOTE: Deletes all items in target track before mirroring.
-- Version: 1.0

local function ClearStretchMarkerExtState()
    for i=1,20 do
        local val = reaper.GetExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i))
        if val == "" then break else
            reaper.DeleteExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i), false)
        end
    end
end

local function CopyStretchMarkers(take)
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local count = reaper.GetTakeNumStretchMarkers(take)
    if count == 0 then return end
    for i=0,count-1 do
        local retval, pos, srcpos = reaper.GetTakeStretchMarker(take, i)
        local slope = reaper.GetTakeStretchMarkerSlope(take, i)
        local str = string.format("{%.9f %.9f %.9f}", pos/playRate, srcpos/playRate, slope)
        reaper.SetExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i+1), str, false)
    end
end

local function PasteStretchMarkers(take)
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local existingCount = reaper.GetTakeNumStretchMarkers(take)
    for i=existingCount-1,0,-1 do
        reaper.SetTakeStretchMarker(take, i, -1, -1)
    end
    for i=1,20 do
        local str = reaper.GetExtState("ARCHIESTRETCHMARKCOPYPASTE", tostring(i))
        if str == "" then break end
        local pos, srcpos, slope = string.match(str, "{([%d%.%-e]+) ([%d%.%-e]+) ([%d%.%-e]+)}")
        if pos and srcpos and slope then
            pos = tonumber(pos)*playRate
            srcpos = tonumber(srcpos)*playRate
            slope = tonumber(slope)
            reaper.SetTakeStretchMarker(take, -1, pos, srcpos)
            local idx = reaper.GetTakeNumStretchMarkers(take) - 1
            reaper.SetTakeStretchMarkerSlope(take, idx, slope)
        else break end
    end
end

local function GetOverlap(a_start, a_end, b_start, b_end)
    local overlap_start = math.max(a_start, b_start)
    local overlap_end = math.min(a_end, b_end)
    return math.max(0, overlap_end - overlap_start)
end

local function SplitItemAtPosition(item, pos)
    if pos <= reaper.GetMediaItemInfo_Value(item, "D_POSITION") then
        return item
    elseif pos >= reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") then
        return item
    else
        return reaper.SplitMediaItem(item, pos)
    end
end

local function GetAllSplitPositions(ref_track)
    local positions = {}
    local count = reaper.CountTrackMediaItems(ref_track)
    for i=0,count-1 do
        local item = reaper.GetTrackMediaItem(ref_track, i)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        positions[pos] = true
        positions[pos + len] = true
    end
    local pos_array = {}
    for p in pairs(positions) do
        table.insert(pos_array, p)
    end
    table.sort(pos_array)
    return pos_array
end

local function FindBestOverlappingRefItem(ref_track, tgt_item)
    local tgt_pos = reaper.GetMediaItemInfo_Value(tgt_item, "D_POSITION")
    local tgt_len = reaper.GetMediaItemInfo_Value(tgt_item, "D_LENGTH")
    local tgt_end = tgt_pos + tgt_len

    local best_idx = -1
    local best_overlap = 0
    local ref_count = reaper.CountTrackMediaItems(ref_track)
    for i=0, ref_count-1 do
        local ref_item = reaper.GetTrackMediaItem(ref_track, i)
        local ref_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
        local ref_len = reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")
        local ref_end = ref_pos + ref_len

        local overlap = GetOverlap(tgt_pos, tgt_end, ref_pos, ref_end)
        if overlap > best_overlap then
            best_overlap = overlap
            best_idx = i
        end
    end
    if best_idx >= 0 and best_overlap > 0 then
        return reaper.GetTrackMediaItem(ref_track, best_idx), best_overlap
    else
        return nil, 0
    end
end

-- Main
reaper.Undo_BeginBlock()

local ref_track = reaper.GetSelectedTrack(0, 0)
local tgt_track = reaper.GetSelectedTrack(0, 1)

if not ref_track or not tgt_track then
    reaper.ShowMessageBox("Please select reference track FIRST, then target track SECOND.", "Error", 0)
    return
end

local tgt_count = reaper.CountTrackMediaItems(tgt_track)
if tgt_count == 0 then
    reaper.ShowMessageBox("Target track has no items.", "Error", 0)
    return
end

local split_positions = GetAllSplitPositions(ref_track)

-- Split target items
for i = 0, reaper.CountTrackMediaItems(tgt_track)-1 do
    local item = reaper.GetTrackMediaItem(tgt_track, i)
    for _, pos in ipairs(split_positions) do
        local new_item = SplitItemAtPosition(item, pos)
        if new_item ~= item then item = new_item end
    end
end

-- Delete target items with no overlap & copy fades/stretch markers for others
for i = reaper.CountTrackMediaItems(tgt_track)-1, 0, -1 do
    local tgt_item = reaper.GetTrackMediaItem(tgt_track, i)
    local ref_item, overlap = FindBestOverlappingRefItem(ref_track, tgt_item)

    if not ref_item or overlap <= 0 then
        -- No overlap: delete target item
        reaper.DeleteTrackMediaItem(tgt_track, tgt_item)
    else
        -- Overlap: copy fades and stretch markers
        local tgt_len = reaper.GetMediaItemInfo_Value(tgt_item, "D_LENGTH")
        local fadein_len = math.min(reaper.GetMediaItemInfo_Value(ref_item, "D_FADEINLEN"), tgt_len)
        local fadeout_len = math.min(reaper.GetMediaItemInfo_Value(ref_item, "D_FADEOUTLEN"), tgt_len)

        if fadein_len < 0.05 then fadein_len = 0.05 end
        if fadeout_len < 0.05 then fadeout_len = 0.05 end

        local fadein_shape = reaper.GetMediaItemInfo_Value(ref_item, "C_FADEINSHAPE")
        local fadeout_shape = reaper.GetMediaItemInfo_Value(ref_item, "C_FADEOUTSHAPE")
        local fadein_dir = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEINDIR")
        local fadeout_dir = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEOUTDIR")

        reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEINLEN", fadein_len)
        reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEOUTLEN", fadeout_len)
        reaper.SetMediaItemInfo_Value(tgt_item, "C_FADEINSHAPE", fadein_shape)
        reaper.SetMediaItemInfo_Value(tgt_item, "C_FADEOUTSHAPE", fadeout_shape)
        reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEINDIR", fadein_dir)
        reaper.SetMediaItemInfo_Value(tgt_item, "D_FADEOUTDIR", fadeout_dir)

        local ref_take = reaper.GetActiveTake(ref_item)
        local tgt_take = reaper.GetActiveTake(tgt_item)

        if ref_take and tgt_take then
            ClearStretchMarkerExtState()
            CopyStretchMarkers(ref_take)
            PasteStretchMarkers(tgt_take)
        end
    end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Track Edit Mirror (Splits, Fades, Stretch Markers, No Source Check)", -1)
