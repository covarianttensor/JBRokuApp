' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

 ' inits VideoShowScreen screen
 ' sets all observers
 ' configures buttons for ShowList screen
Function Init()
  print "VideoShowScreen.brs - [init]"
  m.top.observeField("visible", "onVisibleChange")
  m.top.observeField("focusedChild", "OnFocusedChildChange")

  'Get references to child nodes
  m.RowList           =   m.top.findNode("RowList")
  m.background        =   m.top.findNode("Background")
  m.EpisodeScreenshotPoster  =   m.top.findNode("EpisodeScreenshotPoster")
  m.EpisodeTitle      =   m.top.findNode("EpisodeTitle")
  m.EpisodeDate       =   m.top.findNode("EpisodeDate")
  m.EpisodeSummary    =   m.top.findNode("EpisodeSummary")
  m.fadeIn            =   m.top.findNode("fadeinAnimation")
  m.fadeOut           =   m.top.findNode("fadeoutAnimation")

  m.EpisodeScreenshotPoster.loadDisplayMode = "limitSize"
  m.EpisodeScreenshotPoster.loadWidth = 450
  m.EpisodeScreenshotPoster.loadHeight = 250
End Function

' set proper focus to buttons if ShowList opened and stops Video if ShowList closed
Sub onVisibleChange()
  print "VideoShowScreen.brs - [onVisibleChange]"
  if m.top.visible
    m.fadeIn.control="start"
  else
    m.fadeOut.control="start"
    m.background.uri=""
  end if
End Sub

' set proper focus to RowList in case if return from Details Screen
Sub OnFocusedChildChange()
  print "VideoShowScreen.brs - [OnFocusedChildChange]"
  if m.top.isInFocusChain() and not m.rowList.hasFocus() then m.rowList.setFocus(true)
End Sub

' Content change handler
' Updates screen with content
Sub OnContentChange()
  print "VideoShowScreen.brs - [OnContentChange]"
  setScreenContent()
End Sub

' handler of focused item in RowList
sub OnItemFocused()
  'print "HeroScreen.brs - [onItemFocused]"
  itemFocused = m.top.itemFocused

  'When an item gains the key focus, set to a 2-element array,
  'where element 0 contains the index of the focused row,
  'and element 1 contains the index of the focused item in that row.
  if itemFocused.Count() = 2 then
    focusedContent            = m.RowList.content.getChild(itemFocused[0]).getChild(itemFocused[1])
    if focusedContent <> invalid then
      m.top.focusedContent    = focusedContent
      m.EpisodeTitle.text     = focusedContent.title
      m.EpisodeDate.text      = focusedContent.releaseDate
      m.EpisodeSummary.text   = focusedContent.description
      ' m.background.uri        = focusedContent.hdBackgroundImageUrl
      ' Show Screenshot if available
      if focusedContent.hasField("extrainfo") and focusedContent.extrainfo.DoesExist("screenshotUrl")
        m.EpisodeScreenshotPoster.uri = focusedContent.extrainfo.screenshotUrl
      else
        m.EpisodeScreenshotPoster.uri = focusedContent.hdPosterUrl
      end if

    end if
  end if
end sub

'///////////////////////////////////////////'
' Helper functions

' Populates the screen with data from the recieved content node.
sub setScreenContent()
  print "VideoShowScreen.brs - [setScreenContent]"
  videoShowContainer = m.top.content
  m.top.videoShowTitle            = videoShowContainer.title
  m.background.uri                = videoShowContainer.hdBackgroundImageUrl
  if videoShowContainer.containerType = "videoshow"
    ' Create parent node
    parent = createObject("roSGNode", "ContentNode")

    ' Load json/array feed
    tvdata = m.global.tvdata
    collection = []
    for each groupItem in tvdata["collections"][videoShowContainer.collectionId].group
      collectionItem = tvdata[groupItem["organizationType"]][groupItem["id"]] ' Assign JSON fields to item/(future node)
      collectionItem["groupItem"] = groupItem ' Assign id
      collection.push(collectionItem) ' Add item
    end for

    ' Create grid
    if tvdata["collections"][videoShowContainer.collectionId].uniqueProperties.DoesExist("itemDisplayMode")
      ' Apply special configuration to row
      contentGrid = createGrid(collection, tvdata["collections"][videoShowContainer.collectionId].title, 3, tvdata["collections"][videoShowContainer.collectionId].uniqueProperties.itemDisplayMode)
    else
      contentGrid = createGrid(collection, tvdata["collections"][videoShowContainer.collectionId].title, 3, "")
    end if
    
    ' Reparent grid
    if contentGrid <> invalid
      for j = 0 to (contentGrid.getChildCount() - 1) ' For loop need to handle grid case
        contentGrid.getChild(0).reparent(parent,true)
      end for
    end if

    ' Trigger UI update by setting content
    m.RowList.content = parent
  end if
end sub

'Create a grid of content - simple splitting of a feed to different rows
'with the title of the row hidden.
'Set the for loop parameters to adjust how many columns there
'should be in the grid.
function createGrid(list as object, title as string, maxColumns as integer, itemMode as string)
  print "VideoShowScreen.brs - [createGrid]"
  Parent = createObject("RoSGNode","ContentNode")
  for i = 0 to list.count() step maxColumns
    row = createObject("RoSGNode","ContentNode")
    if i = 0
      row.Title = title
    end if
    rowHasAtleastOneItem = false
    for j = i to i + maxColumns - 1
      if list[j] <> invalid
        rowHasAtleastOneItem = true
        item = createObject("RoSGNode","ContentNode")
        if list[j].uniqueProperties.DoesExist("itemDisplayMode")
          ' Override Row item mode configuration
          item.addFields({"itemmode": list[j].uniqueProperties.itemDisplayMode})
        else
          ' Default behavior
          item.addFields({"itemmode": itemMode})
        end if
        AddAndSetFields(item,list[j])
        row.appendChild(item)
      end if
    end for
    if rowHasAtleastOneItem
      Parent.appendChild(row)
    end if
  end for
  return Parent
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