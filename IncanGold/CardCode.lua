function onCollisionEnter( info )
    derp = info.collision_object
    if self.is_face_down == false then
        if derp.getName() == "Path" then
            local plaque = getPlaqueObject()
            if plaque ~= false then
                plaque.CALLBACKcardhitpath(self)
            end
        end
    end
end

--function onCollisionExit( info )
--    derp = info.collision_object
    --if derp.getDescription() == "Path" then
--        derp.setColorTint( stringColorToRGB( 'White' ) )
    --end
--end

function getPlaqueObject()
    local tags = getTags(path.getDescription())
    --e63c4a
    local plaque = getObjectFromGUID(tags[1])
    if plaque == nil then
        printToAll("Could not find plaque")
        return false
    end
    return plaque
end

function getTags(description, requiredElement)
    --Inputs:
    --description:	string
    --      A string with #tags delimited by spaces
    --requiredElement: string
    --      The prefix required to count the tag.
    --      Blank means no tag
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
        if tag ~= nil and requiredElement ~= nil then
            if requiredElement == "" then
                _returnArray[_numberOfElements] = tag
                _numberOfElements = _numberOfElements + 1
                --print(tag)
            elseif string.len(tag) > string.len(requiredElement) then
                if string.sub(tag,1,string.len(requiredElement)) ==    requiredElement then
                    --print(tag)
                    _returnArray[_numberOfElements] = tag
                    _numberOfElements = _numberOfElements + 1
                end
            end
        end
    end
    if _numberOfElements == 1 then
        return false
    end
    return _returnArray
end