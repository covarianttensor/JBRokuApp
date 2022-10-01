' ********** Copyright (c) 2019-2021 Oscar Cerna-Mandujano.  All Rights Reserved. **********

' 1st function called when channel application starts.
sub Main(args as Dynamic)
  print "################"
  print "Start of Channel"
  print "################"

  ' Initialize home screen menu.
  showHeroScreen(args)
end sub

' ========== Helper Functions ==========

' Returns a deep link as an associative array.
Function getDeepLink(args) as Object
  deepLink = Invalid ' Default value is Invalid.

  if args.contentid <> Invalid and args.mediaType <> Invalid
    deepLink = {
      id: args.contentId
      type: args.mediaType
    }
  end if

  return deepLink
end Function

' Loads bookmark data and returns an AA
' If error occurs, returns Invalid.
Function GetBookmarkdata() As Dynamic
  sec = CreateObject("roRegistrySection", "PersistentSettings")
  if sec.Exists("BookmarkData")
    bookmarkdata = parseJSON(sec.Read("BookmarkData")) ' Convert JSON string back into AA
    return bookmarkdata
  end if
  return invalid
end Function

' Makes a web request for the raw string data from url
Function requestData(url)
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
end Function

' ========== Helper Subroutines ==========

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen(args as Dynamic)
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

        ' Check for error in remote feed.
        if feedData = invalid
          ' Attempt to read local feed instead.
          ba.ReadFile(configAA["localFeedUri"])
          feedData = parseJSON(ba.ToAsciiString())
          ? "ERROR GETTING REMOTE FEED. READING LOCAL FEED INSTEAD."
        end if
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

  ' ***** Process parameters. *****

  ' Check if app has been launched in any special way.
  if args.reason <> Invalid
    if args.reason = "ad" then
      print "Channel launched from ad click"
      'do ad stuff here
    end if
  end if

  ' Check for deep link and create global deep link variable.
  ' Then display deep link content if valid.
  deepLink = getDeepLink(args) ' Returns Invalid if none is found.
  m.glb.addField("deepLink", "assocarray", false) ' Create global variable.
  m.glb.deepLink = deepLink ' Assign local value to created global variable.
  if m.glb.deepLink <> Invalid then
    print "Valid start up deep link recieved."
    ' process deep link here
  end if

  ' ***** Continue with normal application execution. *****

  ' Show home
  scene = screen.CreateScene("HeroScene")
  screen.show()
  scene.signalBeacon("AppLaunchComplete") ' [Cert. Requirement: 3.2]

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
    if type(msg) = "roInputEvent"
      if msg.IsInput()
          info = msg.GetInfo()
          if info.DoesExist("mediatype") and info.DoesExist("contentid")
              mediaType = info.mediatype
              contentId = info.contentid
          end if
      end if
    end if
  end while
end sub