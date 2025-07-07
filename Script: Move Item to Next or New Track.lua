-- Move selected items to next track, creating one if needed
function move_items_to_next_track()
    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then return end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local new_track_created = false
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local src_track = reaper.GetMediaItemTrack(item)
        local track_index = reaper.GetMediaTrackInfo_Value(src_track, "IP_TRACKNUMBER")
        local next_track = reaper.GetTrack(0, track_index) -- zero-based

        if not next_track then
            -- Create new track at bottom
            reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
            next_track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
            new_track_created = true
        end

        reaper.MoveMediaItemToTrack(item, next_track)
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Move items to next track (create if needed)", -1)
end

move_items_to_next_track()
