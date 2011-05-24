'**********************************************************
'**  Video Player Example Application - Video Playback 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'***********************************************************
'** Create and show the video screen.  The video screen is
'** a special full screen video playback component.  It 
'** handles most of the keypresses automatically and our
'** job is primarily to make sure it has the correct data 
'** at startup. We will receive event back on progress and
'** error conditions so it's important to monitor these to
'** understand what's going on, especially in the case of errors
'***********************************************************  

Function showVideoFailureMessage()
    message = CreateObject("roMessageDialog")
    message.SetText("We're sorry, the video you requested could not be loaded. The provider of this content has been notified.")
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

Function analytics(hit_type, video_id)
    
    utmac = getGAKey()
    utmhn = "roku.sunlightfoundation.com"
    utmn = itostr(rnd(9999999999))
    cookie = itostr(rnd(99999999))
    random_num = itostr(rnd(2147483647))
    todayobj = CreateObject("roDateTime")
    today = itostr(todayobj.getHours() * 60 * 60) + itostr(todayobj.getMinutes() * 60)
    referer = "http://rokudevice.com"
    device_info = CreateObject("roDeviceInfo")
    uservar = "device_id_" + device_info.GetDeviceUniqueId()
    uservar2 = "dt_" + device_info.getdisplayType()  
    uservar3 = "vid_" + video_id
    utmp = "/roku/" + hit_type + "/" + uservar3

    url = "http://www.google-analytics.com/__utm.gif?utmwv=1&utmn="+utmn+"&utmsr=-&utmsc=-&utmul=-&utmje=0&utmfl=-&utmdt=-&utmhn="+utmhn+"&utmr="+referer+"&utmp="+utmp+"&utmac="+utmac+"&utmcc=__utma%3D"+cookie+"."+random_num+"."+today+"."+today+"."+today+".2%3B%2B__utmb%3D"+cookie+"%3B%2B__utmc%3D"+cookie+"%3B%2B__utmz%3D"+cookie+"."+today+".2.2.utmccn%3D(direct)%7Cutmcsr%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D"+cookie+"."+uservar+"%3B"+"."+uservar2+"%3B."+uservar3

    print "posting to " + url 
    http = NewHttp(url)
    response = http.GetToStringWithRetry()

    
End Function

Function showVideoScreen(episode As Object, videoId)

    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)
    print "printing episode"
    print episode
    print episode.StreamUrls[0]
'   screen.Show()
    screen.SetPositionNotificationPeriod(5)
    screen.SetContent(episode)
    analytics("videostart-rokuhouse", videoId)
   ' sleep(3000)
    nowpos = invalid
    screen.Show()
    'Uncomment his line to dump the contents of the episode to be played
    'PrintAA(episode)
    while true
        msg = wait(0, port)
        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            elseif msg.isRequestFailed()
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData() 
                print "playstart"
                print episode.PlayStart
                print "playduration"
                print episode.PlayDuration
                print "nowpos"
                print nowpos

                if nowpos = invalid or (episode.PlayStart + episode.PlayDuration - nowpos) > 15 or nowpos = episode.PlayStart then
                    showVideoFailureMessage()
                    analytics("videofail-rokuhouse", videoId)
                endif

                print msg.getMessage()

            elseif msg.isStatusMessage()
                print "Video status: "; msg.GetIndex(); " " msg.GetData() 
            elseif msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                'RegWrite(episode.ContentId, nowpos.toStr())
                print "now position"
                print nowpos
                
            else
                print "Unexpected event type: "; msg.GetType()
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while
End Function


