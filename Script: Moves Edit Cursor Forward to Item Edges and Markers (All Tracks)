-- @description Move edit cursor forward to next item edge or marker (no dialog on end)
-- @version 1.1
-- @author ChatGPT

local function get_all_targets()
    local targets = {}
    local cursor_pos = reaper.GetCursorPosition()

    -- Get item edges
    local num_items = reaper.CountMediaItems(0)
    for i = 0, num_items - 1 do
        local item = reaper.GetMediaItem(0, i)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local edge1 = pos
        local edge2 = pos + len

        if edge1 > cursor_pos then table.insert(targets, edge1) end
        if edge2 > cursor_pos then table.insert(targets, edge2) end
    end

    -- Get project markers
    local _, num_markers, _ = reaper.CountProjectMarkers(0)
    for i = 0, num_markers - 1 do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if not isrgn and pos > cursor_pos then
            table.insert(targets, pos)
        end
    end

    table.sort(targets)
    return targets
end

-- === Main ===
local targets = get_all_targets()
if #targets > 0 then
    reaper.SetEditCurPos(targets[1], true, false)
end
