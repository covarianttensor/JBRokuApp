' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

 ' inits details screen
 ' sets all observers
 ' configures buttons for Details screen
Function Init()
  print "VideoDetailsScreen.brs - [init]"
  m.top.observeField("visible", "onVisibleChange")
  m.top.observeField("focusedChild", "OnFocusedChildChange")

  m.Overhang           =   m.top.findNode("Overhang")
  m.VideoBookmarkTimer =   m.top.findNode("VideoBookmarkTimer")
  m.buttons            =   m.top.findNode("Buttons")

  m.EpisodeTitle       =   m.top.findNode("EpisodeTitle")
  m.EpisodeDate        =   m.top.findNode("EpisodeDate")
  m.EpisodeSummary     =   m.top.findNode("EpisodeSummary")

  m.videoPlayer        =   m.top.findNode("VideoPlayer")
  m.PeopleRowList      =   m.top.findNode("PeopleRowList")
  m.poster             =   m.top.findNode("Poster")
  m.background         =   m.top.findNode("Background")
  m.fadeIn             =   m.top.findNode("fadeinAnimation")
  m.fadeOut            =   m.top.findNode("fadeoutAnimation")

  m.VideoBookmarkTimer.ObserveField("fire", "OnVideoBookmarkUpdate")

  ' create buttons
  result = []
  result.push({"title" : "Play"}) ' Add Play Button
  m.buttons.content = ContentList2SimpleNode(result)
End Function

' set proper focus to buttons if Details opened and stops Video if Details closed
Sub onVisibleChange()
  print "VideoDetailsScreen.brs - [onVisibleChange]"
  if m.top.visible
    m.fadeIn.control="start"
    m.buttons.jumpToItem = 0
    m.buttons.setFocus(true)
  else
    m.fadeOut.control="start"
    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"
    m.poster.uri=""
    m.background.uri=""
    m.VideoBookmarkTimer.control = "stop"
  end if
End Sub

' set proper focus to Buttons in case if return from Video PLayer
Sub OnFocusedChildChange()
  print "VideoDetailsScreen.brs - [OnFocusedChildChange]"
  if m.top.isInFocusChain() and not m.buttons.hasFocus() and not m.videoPlayer.hasFocus() then
    m.buttons.setFocus(true)
  end if
End Sub

' set proper focus on buttons and stops video if return from Playback to details
Sub onVideoVisibleChange()
  print "VideoDetailsScreen.brs - [onVideoVisibleChange]"
  if m.videoPlayer.visible = false and m.top.visible = true
    m.buttons.setFocus(true)
    m.videoPlayer.control = "stop"
    m.VideoBookmarkTimer.control = "stop"
  end if
End Sub

' event handler of Video player msg
Sub OnVideoPlayerStateChange()
  print "VideoDetailsScreen.brs - [OnVideoPlayerStateChange]"
  if m.videoPlayer.state = "error"
    ' error handling
    m.VideoBookmarkTimer.control = "stop"
    m.videoPlayer.visible = false
  else if m.videoPlayer.state = "playing"
    ' playback handling
    m.VideoBookmarkTimer.control = "start" ' Start bookmark timer
  else if m.videoPlayer.state = "finished"
    m.videoPlayer.visible = false
    m.VideoBookmarkTimer.control = "stop"
  end if
End Sub

' on Button press handler
Sub onItemSelected()
  print "VideoDetailsScreen.brs - [onItemSelected]"
  ' first button is Play
  if m.top.itemSelected = 0
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"
    m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
  else if m.top.itemSelected = 1 ' Resume button
    if GetVideoBookmark() <> Invalid
      m.videoPlayer.seek = GetVideoBookmark()
      m.videoPlayer.visible = true
      m.videoPlayer.setFocus(true)
      m.videoPlayer.control = "play"
      m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
    end if
  end if
End Sub

' Content change handler
Sub OnContentChange()
  print "VideoDetailsScreen.brs - [OnContentChange]"
  m.Overhang.title                = m.top.content.shortTitle
  m.videoPlayer.content           = m.top.content
  m.poster.uri                    = m.top.content.hdPosterUrl
  m.EpisodeTitle.text             = m.top.content.title
  m.EpisodeDate.text              = m.top.content.releaseDate
  m.EpisodeSummary.text           = m.top.content.description

  ' Show Screenshot if available
  if m.top.content.hasField("extrainfo") and m.top.content.extrainfo.DoesExist("screenshotUrl")
    m.background.uri                = m.top.content.extrainfo.screenshotUrl
  else
    m.background.uri                = m.top.content.hdBackgroundImageUrl
  end if
  
  ' Show host and guest info if available
  populatePeopleRowList()

  ' Set Button Menu
  if GetVideoBookmark() <> Invalid
    if m.buttons.content.getChildCount() > 1
      m.buttons.content.getChild(1).title = GetPositionAsResumeTimeString(GetVideoBookmark()) ' Set Resume button text
    else
      item = createObject("roSGNode", "ContentNode")
      item.setFields({ title: GetPositionAsResumeTimeString(GetVideoBookmark()) })
      m.buttons.content.appendChild(item) ' Add new resume button
    end if
  else
    if m.buttons.content.getChildCount() > 1
      m.buttons.content.removeChildIndex(1) ' Remove Resume Button
    end if
  end if
End Sub

' Updates video playback bookmark position
sub OnVideoBookmarkUpdate()
  if m.videoPlayer.state = "playing"
    ' Bookmark if playing
    SaveVideoBookmark()

    ' Set Button Menu
    if m.buttons.content.getChildCount() > 1
      m.buttons.content.getChild(1).title = GetPositionAsResumeTimeString(GetVideoBookmark()) ' Set Resume button text
    else
      item = createObject("roSGNode", "ContentNode")
      item.setFields({ title: GetPositionAsResumeTimeString(GetVideoBookmark()) })
      m.buttons.content.appendChild(item) ' Add new resume button
    end if
  end if
end sub

'///////////////////////////////////////////'
' Helper function convert AA to Node
Function ContentList2SimpleNode(contentList as Object, nodeType = "ContentNode" as String) as Object
  print "VideoDetailsScreen.brs - [ContentList2SimpleNode]"
  result = createObject("roSGNode", nodeType)
  if result <> invalid
    for each itemAA in contentList
      item = createObject("roSGNode", nodeType)
      item.setFields(itemAA)
      result.appendChild(item)
    end for
  end if
  return result
End Function

' Saves video player position for current video.
sub SaveVideoBookmark()
  BookmarkTime = m.videoPlayer.position ' position is a double
  bookmarkdataAA = m.global.bookmarkdata ' Create local copy (We can't modify global node fields directly. i.e. because it's a deep copy)
  bookmarkdataAA[m.top.content.groupItem.id] = BookmarkTime ' Set or assing new AA entry
  m.global.bookmarkdata = bookmarkdataAA ' Reassign copy to global node
  bookmarkdata = formatJSON(m.global.bookmarkdata) ' Convert AA to JSON formatted string
  sec = CreateObject("roRegistrySection", "PersistentSettings") ' Load/Create entry
  sec.Write("BookmarkData", bookmarkdata) ' Set string to BookmarkData field.
  sec.Flush() ' Persist bookmark data
end sub

' Loads bookmark data
' If error occurs, returns Invalid.
function GetVideoBookmark() As Dynamic
  if m.global.bookmarkdata.DoesExist(m.top.content.groupItem.id)
    return m.global.bookmarkdata[m.top.content.groupItem.id]
  else
    return Invalid
  end if
end function

' Returns position as a friendly string.
function GetPositionAsResumeTimeString(position as double) as Dynamic
  if position > 0
    minutes = position \ 60
    seconds = position MOD 60
    return "Resume (" + minutes.toStr() + " min " + seconds.toStr() + " sec)"
  else
    return Invalid
  end if
end function

' Helper function to add and set fields of a content node
function AddAndSetFields(node as object, aa as object)
  'This gets called for every content node -- commented out since it's pretty verbose
  'print "UriHandler.brs - [AddAndSetFields]"
  addFields = {}
  setFields = {}
  for each field in aa
    if node.hasField(field)
      setFields[field] = aa[field]
    else
      addFields[field] = aa[field]
    end if
  end for
  node.setFields(setFields)
  node.addFields(addFields)
end function

' Creates row for people row list
function createRow(collection as object, title as String)
  Parent = createObject("RoSGNode", "ContentNode")
  row = createObject("RoSGNode", "ContentNode")
  row.Title = title
  for each itemAA in collection
    item = createObject("RoSGNode","ContentNode")
    AddAndSetFields(item, itemAA)
    row.appendChild(item)
  end for
  Parent.appendChild(row)
  return Parent
end function

sub populatePeopleRowList()
  ' Check if node has extended info field
  if m.top.content.hasField("extrainfo")
    ' Create parent node
    parent = createObject("roSGNode", "ContentNode")

    ' Create row counter
    rowCount = 0

    ' Load tv data
    tvdata = m.global.tvdata

    if m.top.content.extrainfo.DoesExist("hosts")
      ' Create hosts AA
      collectionHosts = []
      for each hostId in m.top.content.extrainfo.hosts
        collectionHostsItem = tvdata["people"][hostId]
        collectionHostsItem["peopleId"] = hostId
        collectionHosts.push(collectionHostsItem)
      end for

      ' Create hosts row
      hostsRow = createRow(collectionHosts, "Hosts")

      ' Reparent rows
      hostsRow.getChild(0).reparent(parent,true)

      ' increase counter
      rowCount = rowCount + 1
    end if

    if m.top.content.extrainfo.DoesExist("guests")
      ' Create guests AA
      collectionGuests = []
      for each guestId in m.top.content.extrainfo.guests
        collectionGuestsItem = tvdata["people"][guestId]
        collectionGuestsItem["peopleId"] = guestId
        collectionGuests.push(collectionGuestsItem)
      end for

      ' Create guests row
      guestsRow = createRow(collectionGuests, "Special Guests")

      ' Reparent rows
      guestsRow.getChild(0).reparent(parent,true)

      ' increase counter
      rowCount = rowCount + 1
    end if
    
    if rowCount > 0
      ' Trigger UI update by setting content
      m.PeopleRowList.content = parent
    else
      ' Trigger UI update by setting content
      m.PeopleRowList.content = Invalid
    end if
  else
    ' Trigger UI update by setting content
    m.PeopleRowList.content = Invalid
  end if
end sub