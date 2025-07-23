-- Moves Edit Cursor Backwards to Item Edges and Markers (All Tracks)
-- Author: Nirmal Dev
-- Description: Moves the edit cursor backwards to the next item edge (start or end) or project marker across all tracks.
-- Version: 1.0

local function get_all_targets()
    local targets = {}
    local cursor_pos = reaper.GetCursorPosition()
    local epsilon = 0.00001 -- margin for floating point errors

    -- Get item edges
    local num_items = reaper.CountMediaItems(0)
    for i = 0, num_items - 1 do
        local item = reaper.GetMediaItem(0, i)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local edge1 = pos
        local edge2 = pos + len

        if edge1 < cursor_pos - epsilon then table.insert(targets, edge1) end
        if edge2 < cursor_pos - epsilon then table.insert(targets, edge2) end
    end

    -- Get project markers
    local _, num_markers, _ = reaper.CountProjectMarkers(0)
    for i = 0, num_markers - 1 do
        local retval, isrgn, pos, _, _, _ = reaper.EnumProjectMarkers(i)
        if not isrgn and pos < cursor_pos - epsilon then
            table.insert(targets, pos)
        end
    end

    -- Explicitly allow 0.0 (project start) as a valid target
    if cursor_pos > epsilon then
        table.insert(targets, 0.0)
    end

    table.sort(targets, function(a, b) return a > b end)
    return targets
end

-- === Main ===
local targets = get_all_targets()
if #targets > 0 then
    reaper.SetEditCurPos(targets[1], true, false)
end
