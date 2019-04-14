sub Init()
    m.lgroup = m.top.findNode("lgroup")
    m.Poster = m.top.findNode("poster")
    m.itemBottomLabel = m.top.findNode("itemBottomLabel")
end sub

sub itemContentChanged()
    m.Poster.loadDisplayMode = "limitSize"

    ' Set Layout
    if m.top.height < 400 and m.top.width < 400
        m.Poster.loadWidth = 200
        m.Poster.loadHeight = 200
    end if

    if m.top.height > 0 And m.top.width > 0 then
        m.Poster.width  = m.top.height
        m.Poster.height = m.top.height
    end if

    m.lgroup.translation = "[" + StrI((m.top.width - m.Poster.width)/2) + ",0]"
    
    m.itemBottomLabel.width = m.top.width

    ' Set info
    m.Poster.uri           = m.top.itemContent.portraitUrl
    m.itemBottomLabel.text = m.top.itemContent.name
end sub