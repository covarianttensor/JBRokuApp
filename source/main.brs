' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function called when channel application starts.
sub Main(input as Dynamic)
  print "################"
  print "Start of Channel"
  print "################"
  ' Add deep linking support here. Input is an associative array containing
  ' parameters that the client defines. Examples include "options, contentID, etc."
  ' See guide here: https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
  ' For example, if a user clicks on an ad for a movie that your app provides,
  ' you will have mapped that movie to a contentID and you can parse that ID
  ' out from the input parameter here.
  ' Call the service provider API to look up
  ' the content details, or right data from feed for id
  if input <> invalid
    print "Received Input -- write code here to check it!"
    if input.reason <> invalid
      if input.reason = "ad" then
        print "Channel launched from ad click"
        'do ad stuff here
      end if
    end if
    if input.contentID <> invalid
      m.contentID = input.contentID
      print "contentID is: " + input.contentID
      'launch/prep the content mapped to the contentID here
    end if
  end if
  showHeroScreen()
end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen()
  print "main.brs - [showHeroScreen]"
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)

  ' Create global variable container
  m.glb = screen.getGlobalNode()

  ' Create AA for feed data
  m.glb.Addfield("tvdata", "assocarray", true)

  ' Load feed data
  ba = CreateObject("roByteArray")
  ba.ReadFile("pkg:/source/config.json")
  configAA = parseJSON(ba.ToAsciiString())
  if configAA <> Invalid
      feedData = Invalid
      if configAA["shouldReadLocalFeed"] = true
        ' Read local JSON feed
        ba.ReadFile(configAA["localFeedUri"])
        feedData = parseJSON(ba.ToAsciiString())
      else
        ' Read remote JSON feed
        feedData = parseJSON(requestData(configAA["remoteFeedUri"]))
      end if
      ' Check if data is was valid JSON
      if feedData <> Invalid
        m.glb.tvdata = feedData ' Initialized global variable with feed data (associative array)
      else
        ? "ERROR READING ROKU FEED!"
      end if
	else
		? "ERROR READING CONFIG!"
	end if

  ' Create AA for bookmark data
  m.glb.Addfield("bookmarkdata", "assocarray", true) ' Stores bookmarks for certain content types

  ' Load bookmark data
  bookmarkdata = GetBookmarkdata()
  if bookmarkdata <> Invalid
    m.glb.bookmarkdata = bookmarkdata
  else
    m.glb.bookmarkdata = {}
  end if
 
  ' Add other global fields
  m.glb.addField("PodcastFF", "int", true) 'To be used for trickplay functions in XML component
  m.glb.PodcastFF = 0
  m.glb.addField("PodcastRewind", "int", true) 'To be used for trickplay functions in XML component
  m.glb.PodcastRewind = 0

  ' Show home
  scene = screen.CreateScene("HeroScene")
  screen.show()

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
  end while
end sub

' Loads bookmark data and returns an AA
' If error occurs, returns Invalid.
function GetBookmarkdata() As Dynamic
  sec = CreateObject("roRegistrySection", "PersistentSettings")
  if sec.Exists("BookmarkData")
    bookmarkdata = parseJSON(sec.Read("BookmarkData")) ' Convert JSON string back into AA
    return bookmarkdata
  end if
  return invalid
end function

' Makes a web request for the raw string data from url
function requestData(url)
    http = createObject("roUrlTransfer")
    http.RetainBodyOnError(true)
    port = createObject("roMessagePort")
    http.setPort(port)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.enablehostverification(false)
    http.enablepeerverification(false)
    http.setUrl(url)
    if http.AsyncGetToString() Then
      msg = wait(10000, port)
      if (type(msg) = "roUrlEvent")
        'HTTP response code can be <0 for Roku-defined errors
        if (msg.getresponsecode() > 0 and  msg.getresponsecode() < 400)
          return msg.getstring()
        else
          ? "Data retrieval failed: "; msg.getfailurereason();" "; msg.getresponsecode();" "; url
          return  ""
        end if
        http.asynccancel()
      else if (msg = invalid)
        ? "Data retrieval failed."
        return ""
        http.asynccancel()
      end if
    end if
end function