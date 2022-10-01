sub init()
    print "loadRadioStations_task.brs - [init]"
    m.top.functionname = "LoadStations"
    'm.top.radioStationListNode = createObject("roSGNode", "ContentNode") 'Appends all radio stations to a single content node
end sub

sub LoadStations()
    print "loadRadioStations_task.brs - [LoadStations]"
    stationData = GetStationData()

    if stationData <> Invalid
        stationListNode = createObject("roSGNode", "ContentNode")
        for each station in stationData["station"]
            row = createObject("roSGNode", "RadioStationListRowContentNode")

            row.station_name = station["station_name"]
            row.title = station["station_list_text"]
            row.Description = station["description"]
            row.station_art_url = station["station_art_url"]

            row.ContentType = "audio"

            plsData = parsePLS(requestData(station["stream_pls_url"]))
            if plsData <> Invalid
                if plsData["numberofentries"] >= 2
                    row.URL = plsData["file2"]
                else if plsData["numberofentries"] = 1
                    row.URL = plsData["file1"]
                else
                    ? "ERROR PARSING PLS FILE: Invalid number of entries."
                end if
            else
                ? "ERROR PARSING PLS FILE: File is in invalid format."
            end if

            row.streamFormat = station["stream_type"]

            row.metadata_url = station["metadata_url"]
            row.metadata_extraction_method = station["metadata_extraction_method"]

            row.background_art_display_mode = station["background_art_display_mode"]

            row.Length = 1000
            stationListNode.appendChild(row)

            ? "PROCESSED PLS for: " + station["stream_pls_url"]
        end for

        m.top.radioStationListNode = stationListNode
        ? "radioStationListNode set."
	else
		? "ERROR PARSING STATION CONFIG!"
	end if
end sub

Function GetStationData()
    print "loadRadioStations_task.brs - [GetStationData]"
    feedData = Invalid
    if m.top.shouldDefaultToLocalConfig = true then
        ' Read local JSON feed
        ba = CreateObject("roByteArray")
        ba.ReadFile(m.top.stationListConfig_local)
        feedData = parseJSON(ba.ToAsciiString())
        if feedData <> Invalid
            return feedData ' Success
        else
            ? "ERROR READING STATION LIST CONFIG (LOCAL)!"
        end if
    else
        ' Read remote JSON feed
        feedData = parseJSON(requestData(m.top.stationListConfig_remote))
        ' Check if data is valid JSON
        if feedData <> Invalid
            return feedData ' Success
        else
            ? "ERROR READING STATION LIST CONFIG (REMOTE)!"
            ' Attempt to read local feed instead.
            ba = CreateObject("roByteArray")
            ba.ReadFile(m.top.stationListConfig_local)
            feedData = parseJSON(ba.ToAsciiString())
            if feedData <> Invalid
                ? "REAING LOCAL STATION LIST CONFIG INSTEAD."
                return feedData ' Success
            else
                ? "ERROR READING STATION LIST CONFIG (REMOTE & LOCAL)!"
            end if
        end if
    end if
    return feedData 'Default
end Function

' Makes a web request for the raw string data from url
Function requestData(url)
    print "loadRadioStations_task.brs - [requestData]"
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

Function parsePLS(plsData) ' Turns a PLS file into an associative array
    print "loadRadioStations_task.brs - [parsePLS]"
    ' Pre-Validation
    if plsData = ""
        return Invalid
    end if

    ' Initialize associative array
    plsAA = CreateObject("roAssociativeArray")

    ' Parse PLS file
    plsList = plsData.Split(chr(10)) ' Split by newline
    for each item in plsList
        if item <> "[playlist]"
            splitPos = Instr(1, item, "=")
            if splitPos > 0+1 and Len(item) >= 3 ' "=" found and left side must have at least one character, hence +1
                leftItem = LCase(Left(item, splitPos - 1))
                rightItem = Mid(item, splitPos+1, Len(item) - splitPos+1)

                if leftItem = "numberofentries"
                    plsAA[leftItem] = rightItem.ToInt()
                else if leftItem = "version"
                    plsAA[leftItem] = rightItem.ToInt()
                else if Left(leftItem, 6) = "length"
                    plsAA[leftItem] = rightItem.ToInt()
                else
                    ' Default assignment
                    plsAA[leftItem] = rightItem
                end if

            end if
        end if
    end for

    ' Post-Validation
    if plsAA.DoesExist("numberofentries") and type(plsAA["numberofentries"]) = "roInteger" and plsAA["numberofentries"] >= 1
        For i=1 To plsAA["numberofentries"] Step 1
            if plsAA.DoesExist("file" + StrI(i).trim()) = false
                return Invalid
            end if
            if plsAA.DoesExist("title" + StrI(i).trim()) = false
                return Invalid
            end if
            if plsAA.DoesExist("length" + StrI(i).trim()) = false
                return Invalid
            end if
        End For
    else
        return Invalid
    end if

    return plsAA ' Successfully passed tests
end Function