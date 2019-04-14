' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

Function init ()
    m.top.observeField("visible", "onVisibleChange")

    m.fadeIn            =   m.top.findNode("fadeinAnimation")
    m.fadeOut           =   m.top.findNode("fadeoutAnimation")

    m.Background = m.top.findNode("Background") 'Background Artwork
    m.AlbumPlay = m.top.findNode("AlbumPlay") 'Bottom Playbar Artwork

    m.CurrentSongName = m.top.findNode("CurrentSongName")
    m.CurrentSongName.text = ""

    m.CurrentArtistName = m.top.findNode("CurrentArtistName")
    m.CurrentArtistName.text = ""

    m.EpisodeTitle       =   m.top.findNode("EpisodeTitle")
    m.EpisodeDate        =   m.top.findNode("EpisodeDate")
    m.EpisodeSummary     =   m.top.findNode("EpisodeSummary")

    m.AlbumPlay.uri = "pkg://images/assets/default_album_art.jpg"

    m.Play = m.top.findNode("Play") 'Play button

    m.Audio = createObject("roSGNode", "Audio")
    m.Audio.notificationInterval = 0.1
end Function

Sub onVisibleChange()
  if m.top.visible
    m.fadeIn.control="start"
  else
    ' Screen is hiding. Kill everything.
    m.fadeOut.control="start"
    m.background.uri=""
    m.AlbumPlay.uri = "pkg://images/assets/default_album_art.jpg"
    stopRadioStation()
  end if
End Sub

function onKeyEvent(key as String, press as Boolean) as Boolean 'Key functions for UI
    if press
        if key = "play"
          if (m.Audio.state = "playing")
              stopRadioStation()
          else
              playRadioStation()
          end if
          return true
        else if key = "OK"
          if (m.Audio.state = "playing")
              stopRadioStation()
          else
              playRadioStation()
          end if
          return true
        end if
    end if
    return false
end Function

sub stopRadioStation() 'Plays audio and updates UI
    m.Audio.control = "stop"
    m.Play.text = "N"
    m.CurrentSongName.text = ""
    m.CurrentArtistName.text = ""
end sub

sub playRadioStation() 'Plays audio and updates UI
    m.Audio.content = m.top.content ' Get current radio station node
    m.Audio.control = "stop"
    m.Audio.control = "none"
    m.Audio.control = "play"
    m.Play.text = "P"
    m.CurrentSongName.text = m.top.content.title
    m.CurrentArtistName.text = m.top.content.shortTitle
end sub

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

  ' Read container data
  if audioContainer.containerType = "audiostream"
    m.Audio.content = audioContainer
  end if
end sub