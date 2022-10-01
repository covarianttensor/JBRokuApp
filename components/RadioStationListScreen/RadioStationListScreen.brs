' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

 ' inits details screen
 ' sets all observers
 ' configures buttons for Details screen
Function init ()
    print "RadioStationListScreen.brs - [init]"
    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")

    m.fadeIn             =   m.top.findNode("fadeinAnimation")
    m.fadeOut            =   m.top.findNode("fadeoutAnimation")

    ' GLOBALS
    m.BackgroundArtUri_Default = "pkg:/images/radio_stations/background_gradients/0.jpg"
    m.RadioStationArtUri_Default = "pkg:/images/radio_stations/station/default_station_art.png"
    m.AlbumArtUri_Default = "pkg:/images/radio_stations/default_album_art.jpg"
    m.BackgroundUri_CurrentSong = ""

    ' INIT
    ' The spinning wheel node
    m.LoadingIndicator = m.top.findNode("LoadingIndicator")
    m.LoadingIndicator.control = "stop"

    m.NetworkLogo = m.top.findNode("NetworkLogo") 'Radio storm logo
    m.NetworkLogo.uri = "pkg:/images/app/network_logo.png"

    m.Background = m.top.findNode("Background") 'Background Artwork
    m.Background.uri = m.BackgroundArtUri_Default
    m.Background_ForceChange = false ' Used to force the background to change instantly

    m.RadioStationList = m.top.findNode("RadioStationPicker") 'LabelList -- has wrapper class called "MyLabelList.xml

    m.Title = m.top.findNode("Title")
    m.Title.text = "Radio Station List"

    m.RadioStationArt = m.top.findNode("RadioStationArt")
    m.RadioStationArt.uri = m.RadioStationArtUri_Default

    m.RadioStationPlaying = m.top.findNode("RadioStationPlaying")
    m.RadioStationPlaying.text = "<NO STATION SELECTED>"

    m.SummaryBackground = m.top.findNode("SummaryBackground")

    m.StationSummary = m.top.findNode("StationSummary")
    m.StationSummary.text = ""

    m.RadioStationRect = m.top.findNode("RadioStationRect")

    m.PlayBar = m.top.findNode("PlayBar")

    m.CurrentAlbumArt = m.top.findNode("CurrentAlbumArt")
    m.CurrentAlbumArt.uri = m.AlbumArtUri_Default

    m.CurrentSongName = m.top.findNode("CurrentSongName")
    m.CurrentSongName.text = "N/A"

    m.CurrentArtistName = m.top.findNode("CurrentArtistName")
    m.CurrentArtistName.text = "n/a"

    m.Play = m.top.findNode("Play") 'Play button

    m.Audio = createObject("roSGNode", "Audio")
    m.Audio.notificationInterval = 0.1

    m.CurrentTrackInfoUpdateTimer = m.top.findNode("CurrentTrackInfoUpdateTimer") 'Timer that updates the currently playing track info.
    m.CurrentTrackInfoUpdateTimer.ObserveField("fire", "CurrentTrackInfoUpdate")

    m.BackgroundArtTimer = m.top.findNode("BackgroundArtTimer") 'Timer that cycles through background art.
    m.BackgroundArtTimer.ObserveField("fire", "BackgroundArtUpdate")
    m.BackgroundArtTimer_TimeElapsed = 0 ' Time in seconds
    m.BackgroundArtTimer_MaxTimeCap = 180 ' BackgroundArtTimer_TimeElapsed will be reset to zero when it reaches a value of BackgroundArtTimer_MaxTimeCap or greater

    m.RadioStationList.SetFocus(true) ' Set Focus on Label List

    'm.RadioStationList.observeField("itemFocused", "setaudio") 'Set's audio content to focused item in Labellist
    m.RadioStationList.observeField("itemSelected", "playRadioStation") 'Plays radio station content in Label List (a.k.a m.RadioStationList)
end Function

' EVENTS

' Content change handler
sub OnContentChange()
    print "RadioStationListScreen.brs - [OnContentChange]"
    loadRadioStations()
end sub

' set proper focus to buttons if Details opened and stops Video if Details closed
Sub onVisibleChange()
  print "RadioStationListScreen.brs - [onVisibleChange]"
  if m.top.visible
    m.fadeIn.control="start"
  else
    ' Screen is hiding. Kill everything.
    m.fadeOut.control="start"
    ' TODO: Kill everthing.
    stopRadioStation()
  end if
End Sub

' set proper focus to Radio Staion List (RadioStationPicker)
Sub OnFocusedChildChange()
    print "RadioStationListScreen.brs - [OnFocusedChildChange]"
    if m.top.isInFocusChain() and not m.RadioStationList.hasFocus() then m.RadioStationList.setFocus(true)
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
        end if
    end if
end Function

' METHODS (Timers/Field Observer Methods)

sub CurrentTrackInfoUpdate() ' Timer update for currently playing track
    if m.Audio.state = "playing"
        GetCurrentTrackInfo()
    end if
end sub

sub BackgroundArtUpdate() ' Used for changing the current background art
    'Advance timer
    m.BackgroundArtTimer_TimeElapsed += m.BackgroundArtTimer.duration

    ' Update Background Art
    if m.Audio.state = "playing"
        ChangeBackgroundArt()
    end if

    ' Reset the timer if necessary
    if m.BackgroundArtTimer_TimeElapsed >= m.BackgroundArtTimer_MaxTimeCap
        m.BackgroundArtTimer_TimeElapsed = 0
    end if
end sub

' METHODS (Task Initializers)

sub loadRadioStations()
    print "RadioStationListScreen.brs - [loadRadioStations]"
    m.LoadingIndicator.control = "start"
    ' Create task
    m.loadRadioStations_task = createObject("roSGNode", "loadRadioStations_task")
    m.loadRadioStations_task.observeField("radioStationListNode", "onLoadRadioStationsResponse")
    ' Initialize task specific fields
    m.loadRadioStations_task.shouldDefaultToLocalConfig = m.top.content.shouldDefaultToLocalConfig
    m.loadRadioStations_task.stationListConfig_local = m.top.content.stationListConfig_local
    m.loadRadioStations_task.stationListConfig_remote = m.top.content.stationListConfig_remote
    'tasks have a control field with specific values
    m.loadRadioStations_task.control = "RUN"
end sub

sub readAPI(url)
    ' create a task
    m.api_task = createObject("roSGNode", "url_request_task")
    m.api_task.observeField("response", "onAPIResponse")
    ' Initialize task specific fields
    m.api_task.url = url
    'tasks have a control field with specific values
    m.api_task.control = "RUN"
end sub

' METHODS (Post Task Handlers)

sub onLoadRadioStationsResponse()
    print "RadioStationListScreen.brs - [onLoadRadioStationsResponse]"
    m.LoadingIndicator.control = "stop"
    ' Update radio stations list
    m.RadioStationList.content = m.loadRadioStations_task.radioStationListNode
end sub

sub onAPIResponse(obj)
	response = obj.getData() ' Get raw data

    m.CurrentlyPlayingRadioStation = m.RadioStationList.content.getChild(m.RadioStationList.itemSelected) ' Get current radio station node
    ' Use specified matadata parsing method
    if m.CurrentlyPlayingRadioStation.metadata_extraction_method = "live365"
        ' live365 parse method
        data = parseJSON(response) ' Parse raw data as JSON and turn into associative array
        if data <> Invalid
            'Update UI
            m.CurrentSongName.text = data["current-track"]["title"]
            m.CurrentArtistName.text = data["current-track"]["artist"]
            m.CurrentAlbumArt.uri = data["current-track"]["art"]

            m.BackgroundUri_CurrentSong = data["current-track"]["art"]

            ChangeBackgroundArt() ' Update background
        end if
    else if m.CurrentlyPlayingRadioStation.metadata_extraction_method = "looz.net"
        ' looz.net parse method
        data = parseJSON(response) ' Parse raw data as JSON and turn into associative array
        if data <> Invalid
            'Update UI
            data2 = data["title"].Replace("&amp;", "&").Split(" - ") ' Splits string into a roList containing artist and track info
            if data2.Count() = 2
                ' Show Artist and Song
                m.CurrentSongName.text = data2[1]
                m.CurrentArtistName.text = data2[0]
            else
                if data["title"].Replace("&amp;", "&") = ""
                    ' No information available
                    m.CurrentSongName.text = "N/A"
                    m.CurrentArtistName.text = "n/a"
                else
                    ' Show Title
                    m.CurrentSongName.text = data["title"].Replace("&amp;", "&")
                    m.CurrentArtistName.text = ""
                end if
            end if

            m.CurrentAlbumArt.uri = m.AlbumArtUri_Default

            m.BackgroundUri_CurrentSong = m.AlbumArtUri_Default

            ChangeBackgroundArt() ' Update background
        end if
    end if
end sub

' METHODS (General Purpose)

sub playRadioStation() 'Plays audio and updates UI
    m.CurrentTrackInfoUpdateTimer.control = "stop" ' stops current track info update timer
    m.BackgroundArtTimer.control = "stop"
    m.CurrentlyPlayingRadioStation = m.RadioStationList.content.getChild(m.RadioStationList.itemSelected) ' Get current radio station node
    m.Audio.content = m.CurrentlyPlayingRadioStation
    m.Audio.control = "stop"
    m.Audio.control = "none"
    m.Audio.control = "play"
    m.Play.text = "P"
    if m.CurrentlyPlayingRadioStation.station_art_url = ""
        m.RadioStationArt.opacity = ".6"
        m.RadioStationArt.uri = m.RadioStationArtUri_Default
    else
        m.RadioStationArt.opacity = "1"
        m.RadioStationArt.uri = m.CurrentlyPlayingRadioStation.station_art_url
    end if
    m.RadioStationRect.opacity = "0.8"
    m.SummaryBackground.opacity = "0.7"
    m.PlayBar.opacity = "0.7"
    m.RadioStationPlaying.text = m.CurrentlyPlayingRadioStation.station_name
    m.StationSummary.text = m.CurrentlyPlayingRadioStation.Description
    m.Background_ForceChange = true
    GetCurrentTrackInfo()
    m.CurrentTrackInfoUpdateTimer.control = "start" ' starts current track info update timer
    m.BackgroundArtTimer.control = "start"
end sub

sub stopRadioStation() 'Stops audio
    m.Audio.control = "stop"
    m.Play.text = "N"
    m.CurrentTrackInfoUpdateTimer.control = "stop"
    m.BackgroundArtTimer.control = "stop"
end sub

sub GetCurrentTrackInfo()
    m.CurrentlyPlayingRadioStation = m.RadioStationList.content.getChild(m.RadioStationList.itemSelected) ' Get current radio station node
    ' Use specified matadata updating method
    if m.CurrentlyPlayingRadioStation.metadata_extraction_method = "live365"
        ' live365 matadata updating method
        readAPI(m.CurrentlyPlayingRadioStation.metadata_url)
    else if m.CurrentlyPlayingRadioStation.metadata_extraction_method = "looz.net"
        ' live365 matadata updating method
        readAPI(m.CurrentlyPlayingRadioStation.metadata_url)
    else
        ' Default matadata updating method
        setDefaultMetadata()
    end if
end sub

sub ChangeBackgroundArt() ' Used for changing the current background art
    m.CurrentlyPlayingRadioStation = m.RadioStationList.content.getChild(m.RadioStationList.itemSelected) ' Get current radio station node
    if m.CurrentlyPlayingRadioStation.background_art_display_mode = "album"
        m.Background.uri = m.BackgroundUri_CurrentSong
    else if m.CurrentlyPlayingRadioStation.background_art_display_mode = "gradients"
        if m.BackgroundArtTimer_TimeElapsed <= 0 or m.BackgroundArtTimer_TimeElapsed = m.BackgroundArtTimer_MaxTimeCap or m.Background_ForceChange = true
            m.Background.uri = "pkg:/images/radio_stations/background_gradients/" + StrI(Rnd(58)).trim() + ".jpg" ' Picks a random gradient background
        end if
    else
        ' Default behavior if no proper background art display mode is specified
        m.Background.uri = m.BackgroundUri_Default
    end if
    m.Background_ForceChange = false ' Reset force flag
end sub

sub setDefaultMetadata()
    m.CurrentlyPlayingRadioStation = m.RadioStationList.content.getChild(m.RadioStationList.itemSelected) ' Get current radio station node
    'Update UI
    m.CurrentSongName.text = m.CurrentlyPlayingRadioStation.station_name
    m.CurrentArtistName.text = m.CurrentlyPlayingRadioStation.title
    m.CurrentAlbumArt.uri = m.AlbumArtUri_Default

    m.BackgroundUri_CurrentSong = m.AlbumArtUri_Default

    ChangeBackgroundArt() ' Update background
end sub