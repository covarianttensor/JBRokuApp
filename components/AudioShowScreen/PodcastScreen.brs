' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

Function init ()
    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")
    m.fadeIn            =   m.top.findNode("fadeinAnimation")
    m.fadeOut           =   m.top.findNode("fadeoutAnimation")

    m.PodcastArt = m.top.findNode("PodcastArt") 'Album Artwork
    m.Background = m.top.findNode("Background") 'Background Artwork
    m.AlbumPlay = m.top.findNode("AlbumPlay") 'Bottom Playbar Artwork
    m.EpisodePicker = m.top.findNode("EpisodePicker") 'LabelList -- has wrapper class called "PodcastLabelList.xml

    m.EpisodeTitle       =   m.top.findNode("EpisodeTitle")
    m.EpisodeDate        =   m.top.findNode("EpisodeDate")
    m.EpisodeSummary     =   m.top.findNode("EpisodeSummary")

    m.AlbumPlay.uri = "pkg://images/assets/default_album_art.jpg"

    'm.EpisodePicker.color = m.global.ListColor 'LabelList -- Changes colors of labels
    m.current = m.top.findNode("PodcastPlaying") ' Label for currently playing Podcast located at the bottom of the album artwork
    m.AlbumRect = m.top.findNode("AlbumRect") 'Background shading rectangle for Current Podcast playing label

    m.EpisodePicker.SetFocus(true) ' Set Focus on Label List

    m.TimerRect = m.top.findNode("TimeBarFront") 'Purple Time bar located in the playbar that moves as playback plays
    m.TimerAnim = m.top.findNode("TimerAnim") 'Animation to move Purple Time bar
    m.TimerInterp = m.top.findNode("TimerInterp") 'field interpolator for TimerAnim
    m.AudioCurrent = m.top.findNode("AudioCurrent") 'Current playback location time of Audio
    m.AudioDuration = m.top.findNode("AudioDuration") 'Length of selected Audio playback
    m.AudioTime = 0 'variable to keep playback time accurate. Fixes bug with mp3 files

    m.Play = m.top.findNode("Play") 'Play button
    m.FFAnim = m.top.findNode("FFAnim") 'FastForward Animation for trickplay
    m.RewindAnim = m.top.findNode("RewindAnim") 'Rewind Animation for trickplay

    m.Audio = createObject("roSGNode", "Audio")
    m.Audio.notificationInterval = 0.1
    m.AudioDuration.text = secondsToMinutes(0) 'toString Method to format playback string
    m.AudioCurrent.text = secondsToMinutes(0)
    m.Audio.observeField("duration", "onAudioDurationChanged")

    m.PlayTime = m.top.findNode("PlayTime") 'One second timer to advance AudioCurrent every second
    m.PlayTime.ObserveField("fire", "TimeUpdate") 'Updates AudioCurrent string

    m.EpisodePicker.observeField("itemFocused", "setaudio") 'Set's audio content to focused item in Labellist
    m.EpisodePicker.observeField("itemSelected", "playaudio") 'Plays audio content in Label List
    m.global.observeField("PodcastFF", "FF") 'Calls function for trickplay when FastForward button is pressed
    m.global.observeField("PodcastRewind", "Rewind") 'Calls function for trickplay when Rewind button is pressed

    m.check = 0 'Initializes m.check before opening a podcast
end Function

Sub onVisibleChange()
  if m.top.visible
    m.fadeIn.control="start"
  else
    ' Screen is hiding. Kill everything.
    m.fadeOut.control="start"
    m.background.uri=""
    m.AlbumRect.opacity = "0"
    m.Audio.control = "stop"
    m.TimerAnim.control = "stop"
    m.PlayTime.control = "stop"
    m.Play.text = "N"
    m.AudioTime = 0'resets audiotime
    m.AudioCurrent.text = secondsToMinutes(0)
    m.AudioDuration.text = secondsToMinutes(0)
    m.TimerRect.width = 0
    m.TimerAnim.duration = 0
    m.AlbumPlay.uri = "pkg://images/assets/default_album_art.jpg"
  end if
End Sub

' set proper focus to Poscast List (EpisodePicker)
Sub OnFocusedChildChange()
  if m.top.isInFocusChain() and not m.EpisodePicker.hasFocus() then m.EpisodePicker.setFocus(true)
End Sub

sub FF() 'FastForward function
  if (m.Audio.duration <> invalid and m.Audio.duration > 0 and (m.Audio.state = "playing" or m.Audio.state = "buffering"))
    skipInSeconds(true, 60)
  end if
end sub

sub Rewind() 'Rewind function
  if (m.Audio.duration <> invalid and m.Audio.duration > 0 and (m.Audio.state = "playing" or m.Audio.state = "buffering"))
    skipInSeconds(false, 60)
  end if
end sub

sub setaudio() 'Sets audio content
    audiocontent = m.EpisodePicker.content.getChild(m.EpisodePicker.itemFocused)
    m.EpisodeTitle.text             = audiocontent.title
    m.AlbumPlay.uri                 = audiocontent.hdPosterUrl
    m.EpisodeDate.text              = audiocontent.releaseDate
    m.EpisodeSummary.text           = audiocontent.description
end sub

sub controlaudioplay() 'Makes sure that audio stops when finished
    if (m.audio.state= "finished")
        m.audio.control = "stop"
        m.audio.control = "none"
    end if
end sub

sub TimeUpdate() ' Timer update for playback, current audio time, etc.
    m.AudioTime += 1
    m.AudioCurrent.text = secondsToMinutes(m.AudioTime)
    if m.AudioTime = m.check
        m.PlayTime.control = "stop"
    end if
end sub

sub playaudio() 'Plays audio and changes Currently playing parameter
    audiocontent = m.EpisodePicker.content.getChild(m.EpisodePicker.itemSelected)
    m.Audio.content = audiocontent
    m.audio.control = "stop"
    m.audio.control = "none"
    m.audio.control = "play"
    m.AlbumRect.opacity = "0.8"
    m.Play.text = "O" 'Resets currently playing time
    m.current.text = audiocontent.shortTitle 'Changes title to new playback
    m.TimerInterp.keyValue = "[0,1470]" 'Sets width for animations of playbar
    m.TimerAnim.control = "start"
    m.PlayTime.control = "start" ' starts audio
    m.AudioTime = 0'resets audiotime
end sub

' Sets the playbar animation parameters
sub onAudioDurationChanged()
  m.check = m.audio.duration
  m.TimerAnim.duration = m.audio.duration 'Sets animation duration for playbar
  m.TimerAnim.control = "start"
  'm.split will be used for trickplay. It will help reset the animation's for the trickplay bar rectangle based off of new remaining time of audio
  if m.audio.duration > 0
    m.split = 1470.0/m.audio.duration
  else
    m.split = 1 ' Prevent division by zero if duration is zero
  end if
  m.AudioDuration.text = secondsToMinutes(m.audio.duration) 'toString to set audio playback length
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean 'Key functions for UI
    if press
        if key = "replay"
            if (m.Audio.state = "playing")
                playaudio()

                return true
            end if
        else if key = "play"
            if (m.Audio.state = "playing")
                m.Audio.control = "pause"
                m.TimerAnim.control = "pause"
                m.PlayTime.control = "stop"
                m.Play.text = "N"
            else if (m.Audio.state = "paused")
                m.Audio.control = "resume"
                m.TimerAnim.control = "resume"
                m.PlayTime.control = "start"
                m.Play.text = "O"
            else
                return false
            end if
                return true
        else if key = "right"
                if (m.Audio.duration <> invalid and m.Audio.duration > 0 and (m.Audio.state = "playing" or m.Audio.state = "buffering"))
                  skipInSeconds(true, 10)
                end if
                return true
        else if key = "left"
                if (m.Audio.duration <> invalid and m.Audio.duration > 0 and (m.Audio.state = "playing" or m.Audio.state = "buffering"))
                  skipInSeconds(false, 10)
                end if
                return true
        end if
    end if
end Function

sub skipInSeconds(forward as Boolean, seconds as integer) 'trickplay functions. 2 Functions for each FastForward and Rewind to account for edge cases. (Skipping or Rewinding 10 seconds past or before)
    if forward then
        if (m.check - seconds) > m.AudioTime
            print m.check
            m.AudioTime += seconds
            m.TimerInterp.KeyValue = [m.TimerRect.width + m.split*10, 1470] 'Calculates new trickplay animation values for rectangle
            m.TimerAnim.duration = m.check - (m.AudioTime + 10) 'Calculates remaining time of audio
            m.FFAnim.control = "start"
            m.Audio.seek = m.AudioTime
            m.TimerAnim.control = "start"
            print "1"
        else
            print m.AudioTime
            m.AudioTime = m.check
            m.AudioCurrent.text = secondsToMinutes(m.check)
            m.TimerAnim.control = "stop"
            m.TimerRect.width = 1470
            m.FFAnim.control = "start"
            m.PlayTime.control = "stop"
            m.Audio.seek = m.AudioTime
            print m.check
            print "2"

        end if
    else
        if m.AudioTime > seconds
            m.AudioTime -= seconds
            m.TimerInterp.KeyValue = [m.TimerRect.width - m.split*10, 1470]
            m.TimerAnim.duration = m.check - (m.AudioTime - 10)
            m.RewindAnim.control = "start"
            m.PlayTime.control = "start"
            m.Audio.seek = m.AudioTime
            m.TimerAnim.control = "start"
            print "3"
        else
            m.AudioTime = 0
            m.TimerInterp.KeyValue = [0, 1470]
            m.TimerAnim.duration = m.check
            m.TimerAnim.control = "start"
            m.RewindAnim.control = "start"
            m.PlayTime.control = "start"
            m.Audio.seek = m.AudioTime
            print "4"
        end if
    end if
end sub

Function secondsToMinutes(seconds as integer) as String 'toString method to convert any format of time to specific time format. ex: secondsToMinutes(66) prints "1:06"
    x = seconds\60
    y = seconds MOD 60
    if y < 10
        y = y.toStr()
        y = "0"+y
    else
        y = y.toStr()
    end if
    result = x.toStr()
    result = result +":"+ y
    return result
end Function


sub OnContentChange()
  setScreenContent()
end sub

' Populates the screen with data from the recieved content node.
sub setScreenContent()
  audioShowContainer = m.top.content
  m.PodcastArt.uri                 = audioShowContainer.hdPosterUrl
  m.top.overhangTitle              = audioShowContainer.title
  m.Background.uri                 = audioShowContainer.hdBackgroundImageUrl
  
  ' Set Playbar Color
  if audioShowContainer.uniqueProperties.DoesExist("playbarColor")
    m.TimerRect.color = audioShowContainer.uniqueProperties.playbarColor
  else
    m.TimerRect.color = "0xBF5FFFFF" ' Default color
  end if

  ' Read container data
  if audioShowContainer.containerType = "audioshow"
    ' Create parent node
    parent = createObject("roSGNode", "ContentNode")

    ' Load json/array feed
    tvdata = m.global.tvdata
    collection = []
    for each groupItem in tvdata["collections"][audioShowContainer.collectionId].group
      collectionItem = tvdata[groupItem["organizationType"]][groupItem["id"]] ' Assign JSON fields to item/(future node)
      collectionItem["groupItem"] = groupItem ' Assign id
      collection.push(collectionItem) ' Add item
    end for

    ' Create Column
    contentColumn = createColumn(collection)

    ' Trigger UI update by setting content
    m.EpisodePicker.content = contentColumn
  end if
end sub

function createColumn(collection as object)
  column = createObject("RoSGNode", "ContentNode")
  for each itemAA in collection
    item = createObject("RoSGNode","ContentNode")
    AddAndSetFields(item, itemAA)
    column.appendChild(item)
  end for
  return column
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