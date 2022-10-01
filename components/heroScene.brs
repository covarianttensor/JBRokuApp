' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function that runs for the scene on channel startup
sub init()
  'To see print statements/debug info, telnet on port 8089
  print "heroScene.brs - [init]"
  ' Keep track of the order in which screens have been visited. Need to know what screen
  ' to return to when back button is pressed.
  m.MenuNavigationHistory = []
  ' HeroScreen Node with RowList
  m.HeroScreen = m.top.FindNode("HeroScreen")
  ' VideoDetailsScreen Node with description & video player
  m.VideoDetailsScreen = m.top.FindNode("VideoDetailsScreen")
  ' VideoStreamDetailsScreen Node with description & video player
  m.VideoStreamDetailsScreen = m.top.FindNode("VideoStreamDetailsScreen")
  ' VideoShowScreen Node for displaying collection of VIDEO content nodes
  m.VideoShowScreen = m.top.FindNode("VideoShowScreen")
  ' AudioDetailsScreen Node for displaying an AUDIO content node
  m.AudioDetailsScreen = m.top.FindNode("AudioDetailsScreen")
  ' AudioStreamDetailsScreen Node for displaying an AUDIO content node
  m.AudioStreamDetailsScreen = m.top.FindNode("AudioStreamDetailsScreen")
  ' PodcastScreen Node for displaying collection of AUDIO content nodes
  m.PodcastScreen = m.top.FindNode("PodcastScreen")
  ' RadioStationListScreen Node for displaying a list of radio stations.
  m.RadioStationListScreen = m.top.FindNode("RadioStationListScreen")
  ' LibraryScreen Node for displaying collection of compilation nodes
  m.LibraryScreen = m.top.FindNode("LibraryScreen")
  ' The spinning wheel node
  m.LoadingIndicator = m.top.findNode("LoadingIndicator")
  ' Dialog box node. Appears if content can't be loaded
  m.WarningDialog = m.top.findNode("WarningDialog")
  ' Transitions between screens
  m.FadeIn = m.top.findNode("FadeIn")
  m.FadeOut = m.top.findNode("FadeOut")
  ' Set focus to the scene
  m.top.setFocus(true)
end sub

' Hero Grid Content handler fucntion. If content is set, stops the
' loadingIndicator and focuses on GridScreen.
sub OnChangeContent()
  print "heroScene.brs - [OnChangeContent]"
  m.loadingIndicator.control = "stop"
  if m.top.content.hasField("isErrorNode")
    'Warn the user if there was a bad request
    m.WarningDialog.message = "Unable to load content feed." + chr(10) + "Press '*' or OK or '<-' to continue."
    m.WarningDialog.visible = "true"
  else
    m.HeroScreen.setFocus(true)
  end if
end sub

' Row item selected handler function.
' On select any item on home scene, show sub node and hide home.
sub OnRowItemSelected_HeroScreen()
  'print "HeroScene.brs - [OnRowItemSelected_HeroScreen]"
  showContainer(m.HeroScreen.focusedContent)
end sub

sub OnRowItemSelected_VideoShowScreen()
  'print "HeroScene.brs - [OnRowItemSelected_VideoShowScreen]"
  showContainer(m.VideoShowScreen.focusedContent)
end sub

sub OnRowItemSelected_LibraryScreen()
  'print "HeroScene.brs - [OnRowItemSelected_LibraryScreen]"
  showContainer(m.LibraryScreen.focusedContent)
end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as String, press as Boolean) as Boolean
  print ">>> HomeScene >> OnkeyEvent"
  result = false
  print "in HeroScene.xml onKeyEvent ";key;" "; press
  if press then
    if key = "back"
      print "------ [back pressed] ------"
      showPreviousContainer()
      result = true
    else if key = "OK"
      print "------- [ok pressed] -------"
      if m.WarningDialog.visible = true
        showPreviousContainer()
      end if
    else if key = "options"
      print "------ [options pressed] ------"
      m.WarningDialog.visible = "false"
      m.HeroScreen.setFocus(true)
    end if
  end if
  return result
end function

'///////////////////////////////////////////'
' Helper functions

' Shows provided node in it's designated screen.
sub showContainer(containerNode as object)
  if containerNode.hasField("containerType")
    ' Show selected container
    if containerNode.containerType = "video"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.VideoDetailsScreen.content = containerNode
      m.VideoDetailsScreen.setFocus(true)
      m.VideoDetailsScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "videostream"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.VideoStreamDetailsScreen.content = containerNode
      m.VideoStreamDetailsScreen.setFocus(true)
      m.VideoStreamDetailsScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "videoshow"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.VideoShowScreen.content = containerNode
      m.VideoShowScreen.setFocus(true)
      m.VideoShowScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "audio"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.AudioDetailsScreen.content = containerNode
      m.AudioDetailsScreen.setFocus(true)
      m.AudioDetailsScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "audiostream"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.AudioStreamDetailsScreen.content = containerNode
      m.AudioStreamDetailsScreen.setFocus(true)
      m.AudioStreamDetailsScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "audioshow"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.PodcastScreen.content = containerNode
      m.PodcastScreen.setFocus(true)
      m.PodcastScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "radiostationlist"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.RadioStationListScreen.content = containerNode
      m.RadioStationListScreen.setFocus(true)
      m.RadioStationListScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    else if containerNode.containerType = "library"
      m.FadeIn.control = "start"
      hideAllScreens()
      m.LibraryScreen.content = containerNode
      m.LibraryScreen.setFocus(true)
      m.LibraryScreen.visible = "true"
      m.MenuNavigationHistory.push(containerNode) ' Add node to container navigation history
    end if
  end if
end sub

sub hideAllScreens()
  ' Hide all screens
  m.HeroScreen.visible = "false"
  m.VideoDetailsScreen.visible = "false"
  m.VideoStreamDetailsScreen.visible = "false"
  m.VideoShowScreen.visible = "false"
  m.AudioDetailsScreen.visible = "false"
  m.AudioStreamDetailsScreen.visible = "false"
  m.PodcastScreen.visible = "false"
  m.RadioStationListScreen.visible = "false"
  m.LibraryScreen.visible = "false"
end sub

' Handles switching to previous screens, based on menu navigation history.
sub showPreviousContainer()
  ' if WarningDialog is open
  if m.WarningDialog.visible = true
    m.WarningDialog.visible = "false"
    if m.MenuNavigationHistory.count() >= 1
      ccNode = m.MenuNavigationHistory[m.MenuNavigationHistory.count()-1]
      if ccNode.containerNode = "video"
        hideAllScreens()
        m.VideoDetailsScreen.visible = "true"
        m.VideoDetailsScreen.setFocus(true)
      else if ccNode.containerNode = "videostream"
        hideAllScreens()
        m.VideoStreamDetailsScreen.visible = "true"
        m.VideoStreamDetailsScreen.setFocus(true)
      else if ccNode.containerNode = "videoshow"
        hideAllScreens()
        m.VideoShowScreen.visible = "true"
        m.VideoShowScreen.setFocus(true)
      else if ccNode.containerNode = "audio"
        hideAllScreens()
        m.AudioDetailsScreen.visible = "true"
        m.AudioDetailsScreen.setFocus(true)
      else if ccNode.containerNode = "audiostream"
        hideAllScreens()
        m.AudioStreamDetailsScreen.visible = "true"
        m.AudioStreamDetailsScreen.setFocus(true)
      else if ccNode.containerNode = "audioshow"
        hideAllScreens()
        m.PodcastScreen.visible = "true"
        m.PodcastScreen.setFocus(true)
      else if ccNode.containerNode = "radiostationlist"
        hideAllScreens()
        m.RadioStationListScreen.visible = "true"
        m.RadioStationListScreen.setFocus(true)
      else if ccNode.containerNode = "library"
        hideAllScreens()
        m.LibraryScreen.visible = "true"
        m.LibraryScreen.setFocus(true)
      else
        ' Invalid container type. Default to showing home.
        hideAllScreens()
        m.HeroScreen.visible = "true"
        m.HeroScreen.setFocus(true)
      end if
    else
      ' No current container found. Default to showing home.
      hideAllScreens()
      m.HeroScreen.visible = "true"
      m.HeroScreen.setFocus(true)
    end if
    return
  end if

  ' Continue normally if no warning box is active.
  currentContainerNode = m.MenuNavigationHistory.pop() ' Remove current screen/node from history
  if m.MenuNavigationHistory.count() >= 1 ' Check that array has at least one entry
    ' Load previous node
    previousContainerNode = m.MenuNavigationHistory[m.MenuNavigationHistory.count()-1]
    ' Perform active screen element checks
    if foundActiveScreenElementsAndKilledThemWhileKeepingCurrentScreenActiveInMenuHistory(previousContainerNode) = false
      ' Active screen element checks found nothing. (i.e. video player playing, etc...)
      ' It's okay to show previous screen.
      if previousContainerNode.containerType = "video"
        m.FadeOut.control = "start"
        m.VideoDetailsScreen.content = previousContainerNode
        hideAllScreens()
        m.VideoDetailsScreen.setFocus(true)
        m.VideoDetailsScreen.visible = "true"
      else if previousContainerNode.containerType = "videostream"
        m.FadeOut.control = "start"
        m.VideoStreamDetailsScreen.content = previousContainerNode
        hideAllScreens()
        m.VideoStreamDetailsScreen.setFocus(true)
        m.VideoStreamDetailsScreen.visible = "true"
      else if previousContainerNode.containerType = "videoshow"
        m.FadeOut.control = "start"
        m.VideoShowScreen.content = previousContainerNode
        hideAllScreens()
        m.VideoShowScreen.setFocus(true)
        m.VideoShowScreen.visible = "true"
      else if previousContainerNode.containerType = "audio"
        m.FadeOut.control = "start"
        m.AudioDetailsScreen.content = previousContainerNode
        hideAllScreens()
        m.AudioDetailsScreen.setFocus(true)
        m.AudioDetailsScreen.visible = "true"
      else if previousContainerNode.containerType = "audiostream"
        m.FadeOut.control = "start"
        m.AudioStreamDetailsScreen.content = previousContainerNode
        hideAllScreens()
        m.AudioStreamDetailsScreen.setFocus(true)
        m.AudioStreamDetailsScreen.visible = "true"
      else if previousContainerNode.containerType = "audioshow"
        m.FadeOut.control = "start"
        m.PodcastScreen.content = previousContainerNode
        hideAllScreens()
        m.PodcastScreen.setFocus(true)
        m.PodcastScreen.visible = "true"
      else if previousContainerNode.containerType = "radiostationlist"
        m.FadeOut.control = "start"
        m.RadioStationListScreen.content = previousContainerNode
        hideAllScreens()
        m.RadioStationListScreen.setFocus(true)
        m.RadioStationListScreen.visible = "true"
      else if previousContainerNode.containerType = "library"
        m.FadeOut.control = "start"
        m.LibraryScreen.content = previousContainerNode
        hideAllScreens()
        m.LibraryScreen.setFocus(true)
        m.LibraryScreen.visible = "true"
      else
        ' Previous screen not a valid type. Keep current screen active
        ' and do nothing. Maybe show warning?
        print "Error: Invalid previous container node."
        m.MenuNavigationHistory.push(previousContainerNode)
      end if
    end if
  else
    if currentContainerNode <> invalid ' If current screen is valid, check for active screen elements
      ' Perform active screen element checks
      if foundActiveScreenElementsAndKilledThemWhileKeepingCurrentScreenActiveInMenuHistory(currentContainerNode) = false
        ' Active screen element checks found nothing. (i.e. video player playing, etc...)
        ' Show home screen, since there is no previous screen to show anymore.
        fadeOutToHomeScreen()
      end if
    else
      ' Show home screen, since there is no previous screen to show anymore;
      ' and the current screen is invalid.
      fadeOutToHomeScreen()
    end if
  end if
end sub

' If check finds active screen elements, it will kill/hide them and keep current screen active in
' menu history and return true.
' Returns false and does nothing, otherwise.
' Keep updating these checks as you add new screen types
function foundActiveScreenElementsAndKilledThemWhileKeepingCurrentScreenActiveInMenuHistory(containerNode as object)
  ' Perform active screen element checks
  if containerNode.containerType = "video" and m.VideoDetailsScreen.videoPlayerVisible = true
    ' Keep current screen active, but kill/hide currently active screen elements.
    m.MenuNavigationHistory.push(containerNode)
    m.VideoDetailsScreen.videoPlayerVisible = false
    return true
  else if containerNode.containerType = "videostream" and m.VideoStreamDetailsScreen.videoPlayerVisible = true
    ' Keep current screen active, but kill/hide currently active screen elements.
    m.MenuNavigationHistory.push(containerNode)
    m.VideoStreamDetailsScreen.videoPlayerVisible = false
    return true
  else
    ' Active screen element checks found nothing. (i.e. video player playing, etc...)
    return false
  end if
end function

sub fadeOutToHomeScreen()
  m.FadeOut.control = "start"
  hideAllScreens()
  m.HeroScreen.visible = "true"
  m.HeroScreen.setFocus(true)
end sub