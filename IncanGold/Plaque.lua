m_bDeckHidden = false --State of Deck
m_objMainDeck = nil -- The Main Deck

m_btnNumberOfButtons = 0
m_iBtnDeal = -1 --Deal Button
m_iBtnShowHideButton = -1 --Deal Button

m_tbGUIDinDescription = {} -- Tags in Description

--Round Vars
m_bRoundIsOn = false
m_bShuffleBeforeDeal = false
m_iCurrentPath = 1
m_iNumberOfPlayersIn = 0
m_iNumberOfHazzards_Spider = 0
m_iNumberOfHazzards_Mummy = 0
m_iNumberOfHazzards_Boulder = 0
m_iNumberOfHazzards_Snake = 0
m_iNumberOfHazzards_Fire = 0
m_bRoundOverDueToHazzards = false
m_sRoundOverDueToHazzard = ""
m_iDealtCards_count = 0
m_tbDealtCards = {}
m_iNumberOfHazzardsOutOfDeck = 0
m_iDontFlipNumber_0 = -1
m_iDontFlipNumber_1 = -1

function onLoad()
    createMainButton()
    createShowHideButton()
    --setDeckHidden(false)
    
    m_tbGUIDinDescription = getTags(self.getDescription(),"")
    m_iCurrentPath = 2
    
    resetRound()
end

function mainButton()
    if m_bRoundIsOn then
        if m_bShuffleBeforeDeal then
            mainDeckShuffle()
            m_bShuffleBeforeDeal = false
        end
        if dealCardInRound() >= 5 then
            m_bRoundIsOn = false
            setDeckButtonLabel("Start new round")
        end
    else

        --
    
        if retractAllCardsToDeck() then
            if m_bRoundOverDueToHazzards then
                moveDoubleHazzardsToBottom(m_sRoundOverDueToHazzard)
            end
            dealtCardsEmpty()
            m_bShuffleBeforeDeal = true
            resetRound()
            setDeckButtonLabel("Deal")
        end
    end
end
--de1e9e
--3a7ba4 643121 7fd96c 35cf3f 414af8 d2ffb3 42ff95 452a15 4c5d92 ab0899 3e74c7 301212 44549d 135447 5894ba 6ff4eb c884fc 59b770
--832b6f 4ffd93 9bf66e a9440a 8ecbee
--getSnapPoints() --Returns Table

function dealCardInRound()
    --Return values
    -- -1: Could not run for some reason... couldn't find deck etc
    -- 0: Dealt a card round still exists
    -- 5: Two hazzards on table round is automatically over
    if m_iCurrentPath > 19 then --Ran out of paths
        return -1
    elseif m_bRoundOverDueToHazzards == true then
        return 1
    end
    local deck = getDeckObject()
    if deck == false then
        return -1
    end
    local nextPath = getObjectFromGUID(m_tbGUIDinDescription[m_iCurrentPath])
    if nextPath == nil then
        printToAll("Could not find next path. Ensure all paths are in Plaque description.")
        return -1
    end
    
    local card = deck.takeObject() 
    dealtCardsStore(card) --Stores the card in the array
    local vec = nextPath.getPosition()
    vec[2] = vec[2] + 0.5
    flipCardFaceUp(card, true)
    card.setPositionSmooth(vec,  false,  true)
    
    
    local cardType = roundCardTypeCheck(card.getDescription())
    if cardType ~= false and cardType ~= "" then
        if cardType == "hazard" then
            --true in the below adds the hazzard to round totals
            m_sRoundOverDueToHazzard = roundHazzardSpecificCheck(card.getDescription(), true)
            local hazzardEnder = roundHazzardUpdate()
            if hazzardEnder ~= "" then
                markDoubleHazzards(m_sRoundOverDueToHazzard)
                printToAll("Two " .. hazzardEnder .. " cards")
                m_bRoundOverDueToHazzards = true
                return 5
            end
        end
    end
    m_iCurrentPath = m_iCurrentPath + 1
    if m_iCurrentPath > 19 then
        printToAll("Got to the end of the temple")
        return 5
    end
    
    return 0
end

function resetRound()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    flipCardFaceDown(deck)
    deck.randomize()
    
    m_bRoundIsOn = true
    m_iNumberOfPlayersIn = 1
    m_iNumberOfHazzards_Spider = 0
    m_iNumberOfHazzards_Mummy = 0
    m_iNumberOfHazzards_Boulder = 0
    m_iNumberOfHazzards_Snake = 0
    m_iNumberOfHazzards_Fire = 0
    m_bRoundOverDueToHazzards = false
    m_iCurrentPath = 2
    m_sRoundOverDueToHazzard = ""
    m_iDontFlipNumber_0 = -1
    m_iDontFlipNumber_1 = -1
    resetAllPathColors()
    return true
end

function resetAllPathColors(newColor)
    if newColor == nil or newColor == "" then
        newColor = "White"
    end
    for i, v in ipairs(m_tbGUIDinDescription) do
        if i == 1 then --is there continue in lua?
        elseif i <= 19 then
            local path = getObjectFromGUID(m_tbGUIDinDescription[i])
            if path == nil then
                printToAll("Could not find path: " .. i)
                return false
            end
            path.setColorTint( stringColorToRGB(newColor) )
            if i == 19 then
                return true
            end
        else
            return true
        end
    end
    return false
end

function mainDeckShuffle()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    deck.randomize()
end

function roundCardTypeCheck(cardDescription)
    if cardDescription == "" then
        return false
    end
    local cardTags = getTags(cardDescription,"#")
    for i, v in ipairs(cardTags) do
        if v == "#hazard" then
            return "hazard"
        elseif v == "#gem" then
            return "gem"
        elseif v == "#artifact" then
            return "artifact"
        end
    end
    return ""
end

function roundHazzardSpecificCheck(cardDescription, addToTotals)
    if cardDescription == "" then
        return false
    end
    local cardTags = getTags(cardDescription,"#")
    for i, v in ipairs(cardTags) do
        if v == "#snake" then
            if addToTotals then
                m_iNumberOfHazzards_Snake = m_iNumberOfHazzards_Snake + 1
            end
            return "snake"
        elseif v == "#mummy" then
            if addToTotals then
                m_iNumberOfHazzards_Mummy = m_iNumberOfHazzards_Mummy + 1
            end
            return "mummy"
        elseif v == "#boulder" then
            if addToTotals then
                m_iNumberOfHazzards_Boulder = m_iNumberOfHazzards_Boulder + 1
            end
            return "boulder"
        elseif v == "#fire" then
            if addToTotals then
                m_iNumberOfHazzards_Fire = m_iNumberOfHazzards_Fire + 1
            end
            return "fire"
        elseif v == "#spider" then
            if addToTotals then
                m_iNumberOfHazzards_Spider = m_iNumberOfHazzards_Spider + 1
            end
            return "spider"
        end
    end
    return false
end

function roundHazzardUpdate()
    if m_iNumberOfHazzards_Spider >= 2 then
        return "spider"
    elseif m_iNumberOfHazzards_Mummy >= 2 then
        return "mummy"
    elseif m_iNumberOfHazzards_Boulder >= 2 then
        return "boulder"
    elseif m_iNumberOfHazzards_Snake >= 2 then
        return "snake"
    elseif m_iNumberOfHazzards_Fire >= 2 then
        return "fire"
    end
    return ""
end

function markDoubleHazzards(hazzardType)
    local nextFreeHazzard = getNextFreeHazzardPlacementObject()
    if nextFreeHazzard == false then
        return false
    elseif hazzardType == "" then
        return false
    end
    local hazzardTag = false
    
    for i, v in ipairs(m_tbDealtCards) do
        hazzardTag = roundHazzardSpecificCheck(v.getDescription(),false)
        if hazzardTag == hazzardType then
            if m_iDontFlipNumber_0 == -1 then
                m_iDontFlipNumber_0 = i
            elseif m_iDontFlipNumber_1 == -1 then
                m_iDontFlipNumber_1 = i
                return true
            end
        end
    end
end

function toggleDeckVisibility()
    if m_bDeckHidden == true then
        setDeckHidden(false)
    else
        setDeckHidden(true)
    end
end

function flipCardFaceUp(_card, _isMainDeckCard)
    --Seems the wrong way around.
    --It's this way for the main deck.
    if _isMainDeckCard then
        return flipCardFaceDown(_card)
    end
    if _card.is_face_down then  --Mean card is face down
        _card.flip()
    end
    return true
end

function flipCardFaceDown(_card, _isMainDeckCard)
    if _isMainDeckCard then
        return flipCardFaceUp(_card)
    end
    if _card.is_face_down == false then --Mean card is face up
        _card.flip()
    end
    return true
end

function dealtCardsStore(_card)
    if _card == nil then
        return false
    end
    m_iDealtCards_count = m_iDealtCards_count + 1
    m_tbDealtCards[m_iDealtCards_count] = _card
    return true
end

function dealtCardsEmpty()
    m_iDealtCards_count = 0
    m_tbDealtCards = {}
    return true
end

function retractAllCardsToDeck()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    local vec = deck.getPosition()
    vec[2] = vec[2] + 1
    for i, v in ipairs(m_tbDealtCards) do
        if v ~= nil and m_iDontFlipNumber_0 ~= i and m_iDontFlipNumber_1 ~= i then
            v.setLock(false)
            flipCardFaceDown(v)
            v.setPositionSmooth(vec,  false,  true)
        end
    end
    return true
end

function moveDoubleHazzardsToBottom(hazzardType)
    local nextFreeHazzard = getNextFreeHazzardPlacementObject()
    if nextFreeHazzard == false then
        return false
    elseif hazzardType == "" then
        return false
    end
    local hazzardTag = false
    local vec = nextFreeHazzard.getPosition()
    vec[2] = vec[2] + 1
    for i, v in ipairs(m_tbDealtCards) do
        hazzardTag = roundHazzardSpecificCheck(v.getDescription(),false)
        if hazzardTag == hazzardType then
            v.setLock(false)
            flipCardFaceUp(v)
            v.setPositionSmooth(vec,  false,  true)
            --m_tbDealtCards[i] = nil
        end
    end
    m_iNumberOfHazzardsOutOfDeck = m_iNumberOfHazzardsOutOfDeck + 1
end

function setDeckHidden(newValue)
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    
    if newValue then --Hide Deck
        m_bDeckHidden = true
        deck.setInvisibleTo(getSeatedPlayers())
        setShowHideButtonLabel("Show Deck")
    else --Show Deck
        m_bDeckHidden = false
        deck.setInvisibleTo()
        setShowHideButtonLabel("Hide Deck")
    end
end

function setDeckButtonLabel(newValue)
    if m_iBtnDeal ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnDeal
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function setShowHideButtonLabel(newValue)
    if m_iBtnShowHideButton ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnShowHideButton
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function getDeckObject()
    if m_objMainDeck ~= nil then
        return m_objMainDeck
    else
        local deck = getObjectFromGUID(m_tbGUIDinDescription[1])
        if deck == nil then
            printToAll("Could not find deck")
            return false
        end
        m_objMainDeck = deck
        return m_objMainDeck
    end
end

function getNextFreeHazzardPlacementObject()
    -- Only the Hazzard placement tags are 19 -23 inc
    local idOfFreeHazzard = 20 + m_iNumberOfHazzardsOutOfDeck
    local nextFreeHazzard = getObjectFromGUID(m_tbGUIDinDescription[idOfFreeHazzard])
    if idOfFreeHazzard < 20 or idOfFreeHazzard > 24 then
        printToAll("nextFreeHazzard is out of bounds: " .. m_iNumberOfHazzardsOutOfDeck)
    elseif nextFreeHazzard == nil then
        printToAll("Could not find next free Hazzard: " .. m_iNumberOfHazzardsOutOfDeck)
        return false
    end
    return nextFreeHazzard
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

function createMainButton()
    local button_parameters = {}

    button_parameters.click_function = "mainButton"
    button_parameters.function_owner = self
    button_parameters.position = {0,0,-21}
    button_parameters.label = "Deal"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDeal = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createShowHideButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleDeckVisibility"
    button_parameters.function_owner = self
    button_parameters.position = {-5.6,0,-21}
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnShowHideButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end