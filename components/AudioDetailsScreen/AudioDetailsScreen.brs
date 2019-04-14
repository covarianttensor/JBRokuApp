' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

Function init ()
    m.top.observeField("visible", "onVisibleChange")

    m.PeopleRowList      =   m.top.findNode("PeopleRowList")

    m.fadeIn            =   m.top.findNode("fadeinAnimation")
    m.fadeOut           =   m.top.findNode("fadeoutAnimation")

    m.Background = m.top.findNode("Background") 'Background Artwork
    m.AlbumPlay = m.top.findNode("AlbumPlay") 'Bottom Playbar Artwork

    m.EpisodeTitle       =   m.top.findNode("EpisodeTitle")
    m.EpisodeDate        =   m.top.findNode("EpisodeDate")
    m.EpisodeSummary     =   m.top.findNode("EpisodeSummary")

    m.AlbumPlay.uri = "pkg://images/assets/default_album_art.jpg"

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

    m.check = 0 'Initializes m.check before opening a podcast
end Function

Sub onVisibleChange()
  if m.top.visible
    m.fadeIn.control="start"
  else
    ' Screen is hiding. Kill everything.
    m.fadeOut.control="start"
    m.background.uri=""
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
    audiocontent = m.top.content
    m.Audio.content = audiocontent
    m.audio.control = "stop"
    m.audio.control = "none"
    m.audio.control = "play"
    m.Play.text = "O" 'Resets currently playing time
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
        else if key = "OK"
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
              playaudio()
          end if
          return true
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
          else if (m.Audio.state = "none" or m.Audio.state = "stopped" or m.Audio.state = "finished")
              playaudio()
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
        else if key = "fastforward"
          if (m.Audio.duration <> invalid and m.Audio.duration > 0 and (m.Audio.state = "playing" or m.Audio.state = "buffering"))
            skipInSeconds(true, 60)
          end if
          return true
        else if key = "rewind"
          if (m.Audio.duration <> invalid and m.Audio.duration > 0 and (m.Audio.state = "playing" or m.Audio.state = "buffering"))
						skipInSeconds(false, 60)
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
  audioContainer = m.top.content
  m.AlbumPlay.uri                  = audioContainer.hdPosterUrl
  m.top.overhangTitle              = audioContainer.shortTitle
  m.Background.uri                 = audioContainer.hdBackgroundImageUrl

  m.EpisodeTitle.text             = audioContainer.title
  m.EpisodeDate.text              = audioContainer.releaseDate
  m.EpisodeSummary.text           = audioContainer.description

  ' Show host and guest info if available
  populatePeopleRowList()
  
  ' Set Playbar Color
  if audioContainer.uniqueProperties.DoesExist("playbarColor")
    m.TimerRect.color = audioContainer.uniqueProperties.playbarColor
  else
    m.TimerRect.color = "0xBF5FFFFF" ' Default color
  end if

  ' Read container data
  if audioContainer.containerType = "audio"
    m.Audio.content = audioContainer
  end if
end sub

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