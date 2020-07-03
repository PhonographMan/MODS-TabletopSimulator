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
    _haveAtLeastOneEntry = false
    _numberOfElements = 1
    for tag in _stringSplit do
        if string.sub(tag,1,1) == "#" then
            print(tag)
            _returnArray[_numberOfElements] = tag
            _numberOfElements = _numberOfElements + 1
            --_returnArray = table.insert(_returnArray, tag)
            _haveAtLeastOneEntry = true
            end
    end
    if _haveAtLeastOneEntry == false then
        return false
    end
    return _returnArray
end

function onCollisionEnter( info )
    derp = info.collision_object
    if self.is_face_down == false then
        _descTags = getTags(derp.getDescription())
        if _descTags ~= false then
            t = {}
            table.insert(t,"a")
            table.insert(t,"b")
            table.insert(t,"c")
            for i, v in ipairs(_descTags) do
                if v ~= "" then
                    print(i,v)
                    if setColorBasedOnCardType(v) == true then
                       return true
                    end
                end
            end
            --for k,v in _descTags do print(k,v) end
            --for key,tag in _descTags do
            --    print("outter",tag)
                
            --end
            --self.setColorTint( stringColorToRGB( 'Pink' ) )
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
    print("inner",cardType)
    switch(cardType)
    {
        ["#red"] = setColor(self,"Red"),
        ["#blue"] = setColor(self,"Blue"),
        ["#pink"] = setColor(self,"Pink")
    }
    return true
end

function setColor(obj,color)
    obj.setColorTint( stringColorToRGB(color) )
end