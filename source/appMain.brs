'********************************************************************
'**  Sunlight Foundation - Congressional Video Stream
'**  November 20100
'**  Copyright (c) 2010 Sunlight Foundation. All rights reserved.
'********************************************************************

Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()
    ShowChambers()
    'ShowHouseVideos(videos)

End Sub

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
    theme.OverhangOffsetSD_Y = "0"
    theme.OverhangSliceSD = "pkg:/images/overhang_background_sd_720x83.jpg"
   ' theme.OverhangLogoSD  = "pkg:/images/overhang_logo_sd_160x40.png"
    theme.OverhangOffsetHD_X = "0"
    theme.OverhangOffsetHD_Y = "0"
    theme.OverhangSliceHD = "pkg:/images/overhang_background_hd_1281x165.jpg"
   ' theme.OverhangLogoHD  = ""
    theme.BreadcrumbTextRight = "#E8BB4B"
    theme.BackgroundColor = "#FFFFFF"
    app.SetTheme(theme)

End Sub

Function showGenericErrorMessage(mess)
    message = CreateObject("roMessageDialog")
    message.SetText(mess)
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

Function showSenateMessage()
    message = CreateObject("roMessageDialog")
    message.SetText("We're sorry but the U.S. Senate does not offer a live video stream at this time. Please consider writing your senator to request a video feed.")
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
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                if msg.GetIndex() = 0 then
                   ShowHouseVideos()

                elseif msg.GetIndex() = 1 then
                   ShowSenateMessage()
                end if
            end if
        end if
    end while
End Function

Function ShowHouseVideos() As Integer
    
    waitobj = ShowPleaseWait("Retrieving legislative days", "")
    videos = GetDaysFeed("", false, CreateObject("roArray", 100, true))
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
    waitobj = "forgetit"
    screen.show()

    hasFailedOnce = false

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemFocused() then
                screen.SetBreadcrumbText("", str(msg.GetIndex() + 1) + " of " + video_count)
                screen.show()
                if (video_count.ToInt() - msg.GetIndex() <= 8) and hasFailedOnce = false then
                    last_day = videos[video_count.ToInt() - 1].Title
                    temp_videos = GetDaysFeed(last_day, true, videos)
                    if temp_videos = invalid then
                        return -1
                    endif
                    videos = temp_videos
                    old_video_count = video_count
                    video_count = str(videos.Count())
                    if video_count = old_video_count then
                        hasFailedOnce = true
                    else    
                        screen.SetContentList(videos)
                        screen.SetFocusedListItem(msg.GetIndex())
                    endif
                    
                    screen.SetBreadcrumbText("", str(msg.GetIndex() + 1) + " of " + video_count)
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


    
Function ShowClipDetailScreen(clip, videoId)

    springboard = CreateObject("roSpringboardScreen")
    port = CreateObject("roMessagePort")
    springboard.AddButton(1, "Play just this clip")
    springboard.AddButton(2, "Play stream from this point")
    
    springboard.SetMessagePort(port)
    springboard.SetContent(clip)
    springboard.SetDescriptionStyle("video")
    springboard.SetStaticRatingEnabled(false)
    springboard.SetPosterStyle("rounded-rect-16x9-generic")
    springboard.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed() then
                return -1
        
            elseif msg.isButtonPressed() then
                print "button pressed"
                if msg.GetIndex() = 1 then
                    showVideoScreen(clip, videoId)
                elseif msg.GetIndex() = 2 then
                    print "vid length" 
                    print clip.VidLength
                    print "offset"
                    print clip.StreamStartTimeOffset
'                    if clip.VidLength <> invalid then
 '                      new_duration = clip.VidLength - clip.StreamStartTimeOffset
  '                  else
   '                    new_duration = clip.Length - clip.StreamStartTimeOffset
    '                endif
     '               clip.PlayDuration = new_duration
                    clip.PlayDuration = invalid
                    showVideoScreen(clip, videoId)
                end if
            end if
        end if
    end while
    
End Function

Function ShowDayClips(vid) As Integer
   
    waitobj = ShowPleaseWait("Retrieving clips for this day", "")
    clips = GetClipsFeed(vid)
    clip_count = str(clips.Count())
    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetMessagePort(port)
    screen.SetContentList(clips)
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
                showClipDetailScreen(clips[msg.GetIndex()], vid.videoId)
            else if msg.isScreenClosed() then
                print "closed"
                return -1
            end if
        end If

    end while
    return 0
End Function

Function AddActors(clip)
    l_names = clip.GetNamedElements("legislator_names")
    count = 0
    actors = CreateObject("roArray", 3, False)
    if l_names.Count() > 0 then
        for each a in l_names.GetChildElements()
            if count < 3 then
                actors.Push(a.GetText())
                count = count + 1
            end if
        next
    end if
    if count > 0 then
        return actors
    else 
        return -1
    endif
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
    o.StreamFormat = vid.StreamFormat
    o.StreamQualities = ["SD"]
    o.StreamStartTimeOffset = clip.offset.GetText().ToInt()
    o.PlayStart = o.StreamStartTimeOffset
    o.PlayDuration = clip.duration.GetText().ToInt()
    o.VidLength = vid.Length
    o.SDPosterUrl = "pkg:/images/video_clip_poster_sd_185x94.jpg"
    o.HDPosterUrl = "pkg:/images/video_clip_poster_hd_250x141.jpg"
    o.ContentType = "episode"
    o.MinBandwidth = 60
 
    actors = AddActors(clip)
    if type(actors) = "roArray" then
        o.Actors = actors
    end if
    
    
    return o

End Function

Function GetVideoItem(vid)
    o = CreateObject("roAssociativeArray")
    desc = vid.GetNamedElements("legislative_day")[0].GetText()
    o.Title = desc
    o.Description = "HouseLive feed for " + desc
    o.ShortDescriptionLine1 = "Video Feed from the House Floor"
    o.ShortDescriptionLine2 = desc
    print "type vid" + type(vid)
    clip_urls = vid.GetNamedElements("clip_urls")
    print type(clip_urls)
    print clip_urls.Count()
    if clip_urls.Count() > 0 then
        if clip_urls[0].GetNamedElements("mp4").Count() > 0 then
            mp4_url = clip_urls[0].GetNamedElements("mp4")[0].GetText()
'        else if clip_urls[0].GetNamedElements("wmv").Count() > 0 then
 '           wmv_url = clip_urls[0].GetNamedElements("wmv")[0].GetText()
        else
            return -1
        end if
    else
        return -1
    end if
    mp4_url = vid.GetNamedElements("clip_urls")[0].mp4.GetText()
    hls_url = vid.GetNamedElements("clip_urls")[0].hls.GetText()
    if hls_url <> "" then
        o.StreamUrls = [hls_url]
        o.StreamFormat = "hls"
        print "hls url"
        print hls_url
    elseif mp4_url <> "" then
        o.StreamUrls = [mp4_url]
        o.StreamFormat = "mp4"
        print "mp4 url"
        print mp4_url
    else
        return -1
    endif
    o.StreamBitrates = [0]
    o.StreamQualities = ["SD"]
    o.Length = vid.duration.GetText().ToInt()
    o.VideoId = vid.GetNamedElements("video_id")[0].GetText()
    o.StreamStartTimeOffset = 0
    o.SDPosterUrl = "pkg:/images/legislative_day_poster_304x237.jpg"
    o.HDPosterUrl = "pkg:/images/legislative_day_poster_304x237.jpg"
    o.ContentType = "episode"
    o.MinBandwidth = 60
    
    actors = AddActors(vid)
    if type(actors) = "roArray" then
        o.Actors = actors
    end if
    return o

End Function

Function GetClipsFeed(vid) As Dynamic

    clips = CreateObject("roArray", 100, true)
    video_id = vid.VideoId
    feed = CreateObject("roAssociativeArray")
    feed.url = "http://api.realtimecongress.org/api/v1/videos.xml?per_page=1&apikey="+ GetKey() + "&sections=clips&video_id=" + video_id
    
    print feed.url
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
            ShowGenericErrorMessage("We're sorry; an error has occurred. Please try again later.") 
            return clips
    else
        for each cl in xml.videos.video.clips.clip
        'for each cl in xml.videos.video.clips.clip
            'cl = xml.videos.video.clips.clip[count]
            o = GetClipItem(cl, vid)
            clips.Push(o)
        'next
        end for

    endif

    return clips

End Function


Function GetDaysFeed(start_day, append, videos) As Dynamic
    
    feed = CreateObject("roAssociativeArray")
    feed.url = "http://api.realtimecongress.org/api/v1/videos.xml?per_page=14&apikey=" + GetKey() + "&chamber=house&sections=duration,clip_id,clip_urls,legislator_names,video_id,pubdate,bills,legislative_day&order=legislative_day&sort=desc"
    if start_day <> "" then
        print "start_day in get days feed: " + start_day
        feed.url = feed.url + "&legislative_day__lt=" + start_day 
        
    endif 

    print feed.url
    http = NewHttp(feed.url)
    print http
    response = http.GetToStringWithRetry()
'    print response
    xml = CreateObject("roXMLElement")
    if not xml.Parse(response) then
       print "Can't parse feed"
       ShowGenericErrorMessage("We're sorry; an error has occurred. Please try again later.") 
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
                if type(o) = "roAssociativeArray" then
                    videos.Push(o)
                end if
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


