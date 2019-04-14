sub init()
  print "HomescreenBuilder.brs - [init]"
  ' setting the task thread function
  m.top.functionName = "buildHomeMenu"
  m.top.control = "RUN"
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

function createRow(collection as object, title as String, itemMode as String)
  Parent = createObject("RoSGNode", "ContentNode")
  row = createObject("RoSGNode", "ContentNode")
  row.Title = title
  for each itemAA in collection
    item = createObject("RoSGNode","ContentNode")
    if itemAA.uniqueProperties.DoesExist("itemDisplayMode") and itemMode <> "featured"
      ' Override Row item mode configuration
      item.addFields({"itemmode": itemAA.uniqueProperties.itemDisplayMode})
    else
      ' Default behavior
      item.addFields({"itemmode": itemMode})
    end if
    AddAndSetFields(item, itemAA)
    row.appendChild(item)
  end for
  Parent.appendChild(row)
  return Parent
end function


' Builds root menu
sub buildHomeMenu()
  print "HomescreenBuilder.brs - [buildHomeMenu]"
  ' Create parent node
  parent = createObject("roSGNode", "ContentNode")

  ' Load home screen feeds
  tvdata = m.global.tvdata

  ' Check if tvdata is valid. If not, then that means the feed
  ' failed to load. m.top.content should be set to invalid; this will trigger
  ' a warning message that will be shown to the user.
  if tvdata <> Invalid and type(tvdata) = "roAssociativeArray"
    ' Feed data is a valid assocarray
    ' Process normally.
    for each homepageCollectionId in tvdata["homepage"]
      collection = []
      for each groupItem in tvdata["collections"][homepageCollectionId].group
        collectionItem = tvdata[groupItem["organizationType"]][groupItem["id"]] ' Assign JSON fields to item/(future node)
        collectionItem["groupItem"] = groupItem ' Assign id
        collection.push(collectionItem) ' Add item
      end for
      ' Create row
      if tvdata["collections"][homepageCollectionId].uniqueProperties.DoesExist("itemDisplayMode")
        ' Apply special configuration to row
        contentRow = createRow(collection, tvdata["collections"][homepageCollectionId].title, tvdata["collections"][homepageCollectionId].uniqueProperties.itemDisplayMode)
      else
        contentRow = createRow(collection, tvdata["collections"][homepageCollectionId].title, "")
      end if
      
      ' Reparent row
      if contentRow <> invalid
        for j = 0 to (contentRow.getChildCount() - 1) ' For loop need to handle grid case
          contentRow.getChild(0).reparent(parent,true)
        end for
      end if

    end for

    ' Trigger UI update by setting content
    m.top.content = parent
  else
    ' Feed data is invalid. Return node with error field
    errorNode = createObject("RoSGNode", "ContentNode")
    AddAndSetFields(errorNode, {"isErrorNode" : true })
    m.top.content = errorNode
  end if
end sub