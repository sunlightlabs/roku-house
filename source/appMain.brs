'********************************************************************
'**  Video Player Example Application - Main
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'********************************************************************

Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'prepare the screen for display and get ready to begin
    screen=preShowHomeScreen("HouseLive.gov Legislative Days", "")
    if screen=invalid then
        print "unexpected error in preShowHomeScreen"
        return
    end if

    'set to go, time to get started
    'showHomeScreen(screen)
    print "getting vids and titles"
    m.videos = GetDaysFeed()
    m.titles = GetTitles(m.videos)

    print m.videos
    print m.titles
    
    screen.SetContentList(m.videos)
    screen.SetFocusedListItem(1)
    screen.show()

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            print "showHomeScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; m.curCategory
            else if msg.isListItemSelected() then
                print "list item selected | index = "; msg.GetIndex()
                print m.videos[msg.GetIndex()]
                showVideoScreen(m.videos[msg.GetIndex()])
                print "after event call"
                'kid = m.Categories.Kids[msg.GetIndex()]
                'if kid.type = "special_category" then
                '    displaySpecialCategoryScreen()
                'else
                '    displayCategoryPosterScreen(kid)
                'end if
            else if msg.isScreenClosed() then
                print "closed"
            end if
        end If

    end while
    
End Sub


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

                
Function GetVideoItem(vid)
    print "getting video " + vid.GetName()
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

    return o

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
    print xml

    if xml.results = invalid then
        print "results invalid"
        if xml.results.video then
            print "has single vid"
            videos.Push(GetVideoItem(xml.results.video))
        else
            print "Feed Empty or invalid"
            return invalid
        endif
    else
        'use get children call here instead? START HERE
        for each vid in xml.videos.video
            print vid.GetName()
            if vid.GetName() = "video" then
                o = GetVideoItem(vid)
                print o
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


