'******************************************************
'**  Video Player Example Application -- Category Feed 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'******************************************************

'******************************************************
' Set up the category feed connection object
' This feed provides details about top level categories 
'******************************************************
Function InitCategoryFeedConnection() As Object

    conn = CreateObject("roAssociativeArray")

    'conn.UrlCategoryFeed = "http://www.whitehouse.gov/podcast/video/weekly-addresses/rss.xml"
    conn.UrlCategoryFeed = "http://houselive.gov/VPodcast.php?view_id=2"
'    conn.UrlPrefix   = "http://rokudev.roku.com/rokudev/examples/videoplayer/xml"

'    conn.UrlCategoryFeed = conn.UrlPrefix + "/categories.xml"

    conn.Timer = CreateObject("roTimespan")

    conn.LoadCategoryFeed    = load_category_feed
    conn.GetCategoryNames    = get_category_names

    print "created feed connection for " + conn.UrlCategoryFeed
    return conn

End Function

'*********************************************************
'** Create an array of names representing the children
'** for the current list of categories. This is useful
'** for filling in the filter banner with the names of
'** all the categories at the next level in the hierarchy
'*********************************************************
Function get_category_names(categories As Object) As Dynamic

    categoryNames = CreateObject("roArray", 100, true)

    for each category in categories
        'print category.Title
        categoryNames.Push(category.Title)
    next

    return categoryNames

End Function


'******************************************************************
'** Given a connection object for a category feed, fetch,
'** parse and build the tree for the feed.  the results are
'** stored hierarchically with parent/child relationships
'** with a single default node named Root at the root of the tree
'******************************************************************
Function load_category_feed(conn As Object) As Dynamic

    http = NewHttp(conn.UrlCategoryFeed)

    Dbg("url: ", http.Http.GetUrl())

    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    Dbg("Took: ", m.Timer)
    m.Timer.Mark()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
         print "Can't parse feed"
        return invalid
    endif
    Dbg("Parse Took: ", m.Timer)

    m.Timer.Mark()
    if xml.channel = invalid then
        print "no channel tag"
        return invalid
    endif

    'topNode.isapphome = true
    categories = CreateObject("roArray", 30, true)    
    for each item in xml.channel.item
        o = CreateObject("roAssociativeArray")
        if item.GetName() = "item" then
            o.Type = "normal"
            o.Title =item.title.GetText()
            o.Description = "HouseLive" 'xml.description.GetText()
            o.ShortDescriptionLine1 = item.description.GetText()
            o.ShortDescriptionLine2 = "HouseLive.gov feeds"
            o.StreamUrls = [item.enclosure@url]
            o.StreamBitrates = [0]
            o.StreamFormat = "mp4"
            o.StreamQualities = ["SD"]
            categories.Push(o)
        endif
    next
    Dbg("Traversing: ", m.Timer)

    return categories
    'topNode.isapphome = true

End Function

'******************************************************
'MakeEmptyCatNode - use to create top node in the tree
'******************************************************
Function MakeEmptyCatNode() As Object
    return init_category_item()
End Function


'***********************************************************
'Given the xml element to an <Category> tag in the category
'feed, walk it and return the top level node to its tree
'***********************************************************
Function ParseCategoryNode(xml As Object) As dynamic
    o = init_category_item()

    print "ParseCategoryNode: " + xml.GetName()
    'PrintXML(xml, 5)

    'parse the curent node to determine the type. everything except
    'special categories are considered normal, others have unique types 
    if xml.GetName() = "item" then
        print xml.enclosure@url
        print xml.title.GetText()
       ' print "item: " + xml.title + " | " + xml.description
        o.Type = "normal"
        o.Title = xml.title.GetText()
        o.Description = "HouseLive" 'xml.description.GetText()
        o.ShortDescriptionLine1 = xml.title.GetText()
        o.ShortDescriptionLine2 = "HouseLive.gov feeds"
        o.Url = xml.enclosure@url
        o.StreamBitrates = [0]
        o.StreamFormat = "mp4"
        o.StreamQualities = ["SD"]
'        o.SDPosterURL = xml@sd_img
 '       o.HDPosterURL = xml@hd_img
    else
        print "ParseCategoryNode skip: " + xml.GetName()
        return invalid
    endif

    'only continue processing if we are dealing with a known type
    'if new types are supported, make sure to add them to the list
    'and parse them correctly further downstream in the parser 
    while true
        if o.Type = "normal" exit while
        if o.Type = "special_category" exit while
        print "ParseCategoryNode unrecognized feed type"
        return invalid
    end while 

    'get the list of child nodes and recursed
    'through everything under the current node

    return o
End Function


'******************************************************
'Initialize a Category Item
'******************************************************
Function init_category_item() As Object
    o = CreateObject("roAssociativeArray")
    o.Title       = ""
    o.Type        = "normal"
    o.Description = ""
    o.Kids        = CreateObject("roArray", 100, true)
    o.Parent      = invalid
    o.Feed        = ""
    o.IsLeaf      = cn_is_leaf
    o.AddKid      = cn_add_kid
    return o
End Function


'********************************************************
'** Helper function for each node, returns true/false
'** indicating that this node is a leaf node in the tree
'********************************************************
Function cn_is_leaf() As Boolean
    if m.Kids.Count() > 0 return true
    if m.Feed <> "" return false
    return true
End Function


'*********************************************************
'** Helper function for each node in the tree to add a 
'** new node as a child to this node.
'*********************************************************
Sub cn_add_kid(kid As Object)
    if kid = invalid then
        print "skipping: attempt to add invalid kid failed"
        return
     endif
    
    kid.Parent = m
    m.Kids.Push(kid)
End Sub
