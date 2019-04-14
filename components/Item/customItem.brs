sub Init()
    m.Poster = m.top.findNode("poster")
    m.ShortTitleOverlay = m.top.findNode("ShortTitleOverlay")
    m.ShortTitleOverlayBackground = m.top.findNode("ShortTitleOverlayBackground")
    m.itemBottomLabel = m.top.findNode("itemBottomLabel")
end sub

sub itemContentChanged()
    m.Poster.loadDisplayMode = "scaleToZoom"

    ' Set Layout
    if m.top.height < 400 and m.top.width < 400
        m.Poster.loadWidth = 300
        m.Poster.loadHeight = 150
    end if

    if m.top.height > 0 And m.top.width > 0 then
        m.Poster.width  = m.top.width
        m.Poster.height = m.top.height
    end if
    
    m.itemBottomLabel.width = m.Poster.width
    m.ShortTitleOverlay.width = m.Poster.width - 15
    m.ShortTitleOverlayBackground.width = m.Poster.width

    ' Set info and opacity
    m.itemBottomLabel.opacity="0"
    m.ShortTitleOverlayBackground.opacity = "0"
    m.Poster.uri = m.top.itemContent.HDPOSTERURL

    ' Override defaults if special mode is given.
    if m.top.itemContent.itemmode = "featured"
        m.itemBottomLabel.text = m.top.itemContent.title
        m.Poster.uri = m.top.itemContent.hdBackgroundImageUrl
        m.itemBottomLabel.opacity="1"
    else if m.top.itemContent.itemmode = "episode"
        m.ShortTitleOverlay.text = m.top.itemContent.shortTitle
        m.ShortTitleOverlayBackground.opacity = "1"
    else if m.top.itemContent.itemmode = "show"
        m.ShortTitleOverlay.text = m.top.itemContent.title
        m.ShortTitleOverlayBackground.opacity = "0.6"
    else if m.top.itemContent.itemmode = "icon"
        m.itemBottomLabel.text = m.top.itemContent.shortTitle
        m.itemBottomLabel.opacity="1"
    end if
end sub