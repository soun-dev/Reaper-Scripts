-- Move selected items to previous track, creating one if needed
function move_items_to_previous_track()
    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then return end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local src_track = reaper.GetMediaItemTrack(item)
        local track_index = reaper.GetMediaTrackInfo_Value(src_track, "IP_TRACKNUMBER")

        if track_index > 1 then
            local prev_track = reaper.GetTrack(0, track_index - 2) -- zero-based
            reaper.MoveMediaItemToTrack(item, prev_track)
        else
            -- Insert track at top
            reaper.InsertTrackAtIndex(0, true)
            local new_track = reaper.GetTrack(0, 0)
            reaper.MoveMediaItemToTrack(item, new_track)
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Move items to previous track (create if needed)", -1)
end

move_items_to_previous_track()
