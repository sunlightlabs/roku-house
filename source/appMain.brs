'********************************************************************
'**  Video Player Example Application - Main
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'********************************************************************

Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'set to go, time to get started
    print "getting vids and titles"
    m.videos = GetDaysFeed()
    m.titles = GetTitles(m.videos)
    ShowHouseVideos()

End Sub

Function ShowHouseVideos() As Integer
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetListStyle("flat-category")
    screen.SetContentList(m.videos)
    screen.SetMessagePort(port)
    screen.SetFocusedListItem(1)
    screen.show()

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
            else if msg.isListItemSelected() then
                ShowDayClips(m.videos[msg.GetIndex()])
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
'** Theme attributes affect the branding of the application
'** and are artwork, colors and offsets specific to the app
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "31"
    theme.OverhangSliceSD = "pkg:/images/Overhang_Background_SD.png"
    theme.OverhangLogoSD  = "pkg:/images/Overhang_Logo_SD.png"

    theme.OverhangOffsetHD_X = "125"
    theme.OverhangOffsetHD_Y = "35"
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_HD.png"

    app.SetTheme(theme)

End Sub

Function ShowDayClips(vid) As Integer
   
    clips = GetClipsFeed(vid)
    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")
    screen.SetListStyle("flat-category")
    screen.SetMessagePort(port)
    screen.SetContentList(clips)
    screen.SetFocusedListItem(1)
    screen.show()

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
            else if msg.isListItemSelected() then
                showVideoScreen(clips[msg.GetIndex()])
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
    print eve
    if clip.events <> invalid then
        for each e in clip.events.event
            events = events + e.GetText()
        next
    end if

    o = CreateObject("roAssociativeArray")
    desc = vid.Description
    o.Title = desc
    o.Description = events
    o.ShortDescriptionLine1 = "HouseLive.gov Feed"
    o.ShortDescriptionLine2 = events
    o.StreamUrls = vid.StreamUrls
    o.StreamBitrates = [0]
    o.StreamFormat = "mp4"
    o.StreamQualities = ["SD"]
    o.StreamStartTimeOffset = clip.offset.GetText().ToInt()
    o.PlayStart = o.StreamStartTimeOffset
    o.PlayDuration = clip.duration.GetText().ToInt()
    o.Length = vid.Length

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

    return o

End Function

Function GetClipsFeed(vid) As Dynamic

    clips = CreateObject("roArray", 100, true)
    timestamp_id = vid.TimeStampId
    feed = CreateObject("roAssociativeArray")
    feed.url = "http://api.realtimecongress.org/api/v1/videos.xml?per_page=1&apikey=sunlight9&sections=clips&order=legislative_day&sort=desc&timestamp_id=" + timestamp_id
    feed.timer = CreateObject("roTimespan")
    

    http = NewHttp(feed.url)
    response = http.GetToStringWithRetry()
    xml = CreateObject("roXMLElement")
    if not xml.Parse(response) then
       print "Can't parse feed"
       return invalid
    endif

    if xml.videos.clips = invalid then
            print "Feed Empty or invalid"
            return invalid
    else
        for count = xml.videos.video.clips.clip.Count()-1 to 0 step -1
        'for each cl in xml.videos.video.clips.clip
            print count
            print type(xml.videos.video.clips.clip)
            cl = xml.videos.video.clips.clip[count]
            print type(cl)
            o = GetClipItem(cl, vid)
            clips.Push(o)
        'next
        end for

    endif

    return clips

End Function


Function GetDaysFeed() As Dynamic
    
    feed = CreateObject("roAssociativeArray")
    feed.url = "http://api.realtimecongress.org/api/v1/videos.xml?per_page=7&apikey=sunlight9&sections=basic&order=legislative_day&sort=desc"
    feed.timer = CreateObject("roTimespan")
    
    videos = CreateObject("roArray", 7, true)

    http = NewHttp(feed.url)
    response = http.GetToStringWithRetry()
    xml = CreateObject("roXMLElement")
    if not xml.Parse(response) then
       print "Can't parse feed"
       return invalid
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


