function getTags(description)
	--Inputs:
	--description:	string
    --      A string with #tags delimited by spaces
	--Outputs:
    --fail | bool: false
    --      There were no tags
    --success | table: values
    --      The values found
    if description == "" then
        return false
    end
    _stringSplit = string.gmatch(description, "%S+")
    _returnArray = {}
    _numberOfElements = 1
    for tag in _stringSplit do
        if string.sub(tag,1,1) == "#" then
            print(tag)
            _returnArray[_numberOfElements] = tag
            _numberOfElements = _numberOfElements + 1
            end
    end
    if _numberOfElements == 1 then
        return false
    end
    return _returnArray
end

function onCollisionEnter( info )
    derp = info.collision_object
    if self.is_face_down == false then
        _descTags = getTags(derp.getDescription())
        if _descTags ~= false then
            for i, v in ipairs(_descTags) do
                if setColorBasedOnCardType(v) == true then
                   return true
                end
            end
        end
    end
end

function setColorBasedOnCardType(cardType)
    --Inputs:
	--cardType:	string
    --      The tag with a card type
	--Outputs:
    --fail | bool: false
    --      Colour not changed
    --success | bool: true
    --      Colour changed
    if cardType == "" then
        return false
    elseif cardType == "#hazzard" then
        return setColor(self,"Red")
    elseif cardType == "#gem" then
        return setColor(self,"Teal")
    elseif cardType == "#artefact" then
        return setColor(self,"Yellow")
    end
    return false
end

function setColor(obj,color)
    obj.setColorTint( stringColorToRGB(color) )
    return true
end