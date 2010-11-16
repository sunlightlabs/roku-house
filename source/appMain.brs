'********************************************************************
'**  Sunlight Foundation - Congressional Video Stream
'**  November 20100
'**  Copyright (c) 2010 Sunlight Foundation. All rights reserved.
'********************************************************************

Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'set to go, time to get started
    print "getting vids and titles"
   

 
    ShowChambers()
    ShowHouseVideos(videos)

End Sub

Function showSenateMessage()
    message = CreateObject("roMessageDialog")
    message.SetText("We're sorry but the U.S. Senate does not offer a live video stream at this time. Please consider writing your senator to request a non-exclusive video feed.")
    message.AddButton(1, "OK")
    message.SetMessagePort(CreateObject("roMessagePort"))    
    message.Show()
    while true
        dlmsg = wait(0, message.GetMessagePort())
        if dlmsg.isButtonPressed()
            return -1
        endif
    end while
End Function

Function ShowChambers()
    chambers = [{  Title: "House Stream",
        HDPosterUrl: "pkg:/images/category_poster_304x237_house.jpg",
        SDPosterUrl: "pkg:/images/category_poster_304x237_house.jpg"
    },
    {   Title: "Senate Stream",
        HDPosterUrl: "pkg:/images/category_poster_304x237_senate.jpg",
        SDPosterUrl: "pkg:/images/category_poster_304x237_senate.jpg"
    }]

    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetListStyle("arced-landscape")
    screen.SetAdUrl("http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/banner_ad_sd_540x60.jpg", "http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/sunlight2_728x90_roku.jpg")
    screen.SetAdDisplayMode("scale-to-fit")   
    screen.SetContentList(chambers)
    screen.Show()
    while true    
        msg = wait(0, screen.GetMessagePort())
        if msg.isListItemSelected() then
            if msg.GetIndex() = 0 then
                videos = GetDaysFeed("", false, CreateObject("roArray", 100, true))
                titles = GetTitles(videos)
                ShowHouseVideos(videos)

            elseif msg.GetIndex() = 1 then
               ShowSenateMessage()
            end if
        end if
    end while
End Function

Function ShowHouseVideos(videos) As Integer
    video_count = str(videos.Count())
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.SetAdUrl("http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/banner_ad_sd_540x60.jpg", "http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/sunlight2_728x90_roku.jpg")
    screen.SetAdDisplayMode("scale-to-fit")    
    screen.SetContentList(videos)
    screen.SetBreadcrumbText("", "1 of "+ video_count)
    screen.SetFocusedListItem(0)
    screen.show()

    hasFailedOnce = false

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemFocused() then
                screen.SetBreadcrumbText("", str(msg.GetIndex() + 1) + " of " + video_count)
                screen.show()
                if (video_count.ToInt() - msg.GetIndex() <= 4) and hasFailedOnce = false then
                    last_day = videos[video_count.ToInt() - 1].Title
                    temp_videos = GetDaysFeed(last_day, true, videos)
                    videos = temp_videos
                    video_count = str(videos.Count())
                    if video_count.ToInt() = 7 then
                        hasFailedOnce = true
                        
                    endif
                    screen.SetContentList(videos)
                    screen.SetFocusedListItem(msg.GetIndex())
                    screen.show()
                endif

            else if msg.isListItemSelected() then
                ShowDayClips(videos[msg.GetIndex()])
            else if msg.isScreenClosed() then
                return -1
                print "closed"
            end if
           
        end If

    end while
    return 0

End Function


'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'** Theme attributes affect the branding of the appication
'** and are artwork, colors and offsets specific to the app
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "0"
    theme.OverhangOffsetSD_Y = "25"
    'theme.GridScreenLogoOffsetSD_Y = "25"
    theme.OverhangSliceSD = "pkg:/images/overhang_background_sd_720x110.jpg"
    'theme.GridScreenOverhangSliceSD = "pkg:/images/overhang_background_sd_720x110.jpg"
    theme.OverhangLogoSD  = "pkg:/images/overhang_logo_sd_160x40.png"
    'theme.GridScreenLogoSD  = "pkg:/images/overhang_logo_sd_160x40.png"
    'theme.GridScreenOverhangLogoSD  = "pkg:/images/overhang_logo_sd_160x40.png"

    theme.OverhangOffsetHD_X = "0"
    theme.OverhangOffsetHD_Y = "25"
    'theme.GridScreenLogoOffsetHD_Y = "25"
    theme.OverhangSliceHD = "pkg:/images/overhang_background_hd_1281x165.png"
    'theme.GridScreenOverhangSliceHD = "pkg:/images/overhang_background_hd_1281x165.jpg"
    theme.OverhangLogoHD  = ""
    'theme.GridScreenLogoHD  = "pkg:/images/overhang_logo_hd_280x70.png"
    'theme.GridScreenOverhangLogoHD  = "pkg:/images/overhang_logo_hd_280x70.png"
    theme.BreadcrumbTextRight = "#E8BB4B"
    theme.BackgroundColor = "#FFFFFF"
    'theme.GridScreenBackgroundColor = "#FFFFFF"
    'theme.CounterTextLeft = "#40868e"
    'theme.CounterTextRight = "#40868e"
    'theme.CounterSeparator = "#40868e"

    app.SetTheme(theme)

End Sub

Function ShowClipDetailScreen(clip)

    springboard = CreateObject("roSpringboardScreen")
    port = CreateObject("roMessagePort")
    springboard.AddButton(1, "Play just this clip")
    springboard.AddButton(2, "Play stream from this point")
    
    springboard.SetMessagePort(port)
    springboard.SetContent(clip)
    springboard.SetDescriptionStyle("generic")
    springboard.SetStaticRatingEnabled(false)
    springboard.Show()
    while true
        msg = wait(0, port)
        if msg.isScreenClosed() then
            return -1
        
        elseif msg.isButtonPressed() then
            print "button pressed"
            if msg.GetIndex() = 1 then
                showVideoScreen(clip)
            elseif msg.GetIndex() = 2 then
                new_duration = clip.Length - clip.StreamStartTimeOffset
                clip.PlayDuration = new_duration
                showVideoScreen(clip)
            end if
        end if
    end while
    
End Function

Function ShowDayClips(vid) As Integer
   
    waitobj = ShowPleaseWait("Retrieving clips for this day", "")
    clips = GetClipsFeed(vid)
    clip_count = str(clips.Count())
    screen = CreateObject("roPosterScreen")
    'screen = CreateObject("roGridScreen")
    port = CreateObject("roMessagePort")
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetMessagePort(port)
    'screen.SetupLists(1)
    'screen.SetContentList(0, clips)
    'screen.SetDescriptionVisible(false)
    'screen.SetDisplayMode("scale-to-fit")
    screen.SetContentList(clips)
    'screen.SetFocusedListItem(0,0)
    screen.SetBreadcrumbText("", "1 of " + clip_count)
    waitobj = "forget it"
    screen.Show()

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemFocused() then
                screen.SetBreadcrumbText("", str(msg.GetIndex() + 1) + " of " + clip_count)
                screen.show()

            else if msg.isListItemSelected() then
                showClipDetailScreen(clips[msg.GetIndex()])
            else if msg.isScreenClosed() then
                print "closed"
                return -1
            end if
        end If

    end while
    return 0
End Function

Function GetClipItem(clip, vid)
    events = ""
    eve = clip.GetNamedElements("events")
    if clip.events <> invalid then
        for each e in clip.events.event
            events = events + " " + e.GetText()
        next
    end if
    o = CreateObject("roAssociativeArray")
    desc = vid.Description
    o.Title = desc
    o.Description = events
    o.ShortDescriptionLine1 = "HouseLive.gov Feed"
'    o.ShortDescriptionLine2 = events
    o.StreamUrls = vid.StreamUrls
    o.StreamBitrates = [0]
    o.StreamFormat = "mp4"
    o.StreamQualities = ["SD"]
    o.StreamStartTimeOffset = clip.offset.GetText().ToInt()
    o.PlayStart = o.StreamStartTimeOffset
    o.PlayDuration = clip.duration.GetText().ToInt()
    o.Length = vid.Length
    o.SDPosterUrl = "pkg:/images/video_clip_poster_sd_185x94.jpg"
    o.HDPosterUrl = "pkg:/images/video_clip_poster_hd_250x141.jpg"
    o.ContentType = "episode"

    return o

End Function

Function GetVideoItem(vid)
    o = CreateObject("roAssociativeArray")
    desc = vid.GetNamedElements("legislative-day")[0].GetText()
    o.Title = desc
    o.Description = "HouseLive feed for " + desc
    o.ShortDescriptionLine1 = "HouseLive.gov Feed"
    o.ShortDescriptionLine2 = desc
    o.StreamUrls = [vid.GetNamedElements("clip-urls")[0].mp4.GetText()]
    o.StreamBitrates = [0]
    o.StreamFormat = "mp4"
    o.StreamQualities = ["SD"]
    o.Length = vid.duration.GetText().ToInt()
    o.TimeStampId = vid.GetNamedElements("timestamp-id")[0].GetText()
    o.SDPosterUrl = "pkg:/images/legislative_day_poster_304x237.jpg"
    o.HDPosterUrl = "pkg:/images/legislative_day_poster_304x237.jpg"
    o.ContentType = "episode"
    return o

End Function

Function GetClipsFeed(vid) As Dynamic

    clips = CreateObject("roArray", 100, true)
    timestamp_id = vid.TimeStampId
    feed = CreateObject("roAssociativeArray")
    feed.url = "http://api.realtimecongress.org/api/v1/videos.xml?per_page=1&apikey=sunlight9&sections=clips&order=legislative_day&sort=desc&timestamp_id=" + timestamp_id
    

    http = NewHttp(feed.url)
    response = http.GetToStringWithRetry()
    xml = CreateObject("roXMLElement")
    if not xml.Parse(response) then
       print "Can't parse feed"
       return invalid
    endif

    
    vid.SDPosterUrl = "pkg:/images/full_stream_poster_sd_185x94.jpg"
    vid.HDPosterUrl = "pkg:/images/full_stream_poster_hd_250x141.jpg"
    clips.push(vid)

    if xml.videos.clips = invalid then
            print "Feed Empty or invalid"
            return invalid
    else
        for count = xml.videos.video.clips.clip.Count()-1 to 0 step -1
        'for each cl in xml.videos.video.clips.clip
            cl = xml.videos.video.clips.clip[count]
            o = GetClipItem(cl, vid)
            clips.Push(o)
        'next
        end for

    endif

    return clips

End Function


Function GetDaysFeed(start_day, append, videos) As Dynamic
    
    feed = CreateObject("roAssociativeArray")
    feed.url = "http://api.realtimecongress.org/api/v1/videos.xml?per_page=7&apikey=sunlight9&sections=basic&order=legislative_day&sort=desc"
    if start_day <> "" then
        print "start_day in get days feed: " + start_day
        feed.url = feed.url + "&legislative_day%3C=" + start_day
    endif 

    print feed.url
    http = NewHttp(feed.url)
    print http
    response = http.GetToStringWithRetry()
'    print response
    xml = CreateObject("roXMLElement")
    if not xml.Parse(response) then
       print "Can't parse feed"
       return videos
    endif

    if xml.videos = invalid then
        if xml.video then
            print "has single vid"
            videos.Push(GetVideoItem(xml.video))
        else
            print "Feed Empty or invalid"
            return invalid
        endif
    else
        for each vid in xml.videos.video
            if vid.GetName() = "video" then
                o = GetVideoItem(vid)
                videos.Push(o)
            endif
        next

    endif

    return videos

End Function

Function GetTitles(videos As Object) as Dynamic
    
    titles = CreateObject("roArray", 7, true)   
    for each vid in videos
        titles.Push(vid.Title)
    next
    return titles
End Function


