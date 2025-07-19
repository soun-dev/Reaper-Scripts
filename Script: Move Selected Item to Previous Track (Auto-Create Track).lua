-- Move Items To Previous Track
-- ReaScript Name: Move Selected Items to Previous Track (Create if doesn't exist).
-- Author: Nirmal Dev
-- Description: Moves selected items to the previous track. 
-- Creates the track if it doesn't exist.
-- Version: 1.0

function move_items_to_previous_track()
    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then return end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local track_item_map = {}

    -- Group items by their source track
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local src_track = reaper.GetMediaItemTrack(item)
        if not track_item_map[src_track] then
            track_item_map[src_track] = {}
        end
        table.insert(track_item_map[src_track], item)
    end

    -- Move items track-by-track
    for src_track, items in pairs(track_item_map) do
        local track_index = reaper.GetMediaTrackInfo_Value(src_track, "IP_TRACKNUMBER")

        local prev_track
        if track_index > 1 then
            prev_track = reaper.GetTrack(0, track_index - 2) -- zero-based
        else
            -- Create new track at the top
            reaper.InsertTrackAtIndex(0, true)
            prev_track = reaper.GetTrack(0, 0)
        end

        -- Move all items from this track together
        for _, item in ipairs(items) do
            reaper.MoveMediaItemToTrack(item, prev_track)
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Move selected items to previous track (grouped)", -1)
end

move_items_to_previous_track()
