--Tags Needed
--Plaque:
--First tag should be the default deck. This is technically optional
--      Default: de1e9e
--Next 18 Tags should be all the Path objects of the main pool:
--      Default: 3a7ba4 643121 7fd96c 35cf3f 414af8 d2ffb3 42ff95 452a15 4c5d92 ab0899 3e74c7 301212 44549d 135447 5894ba 6ff4eb c884fc 59b770
--Next 5 Tags should be all the locations for hazzards. This is where they'll go if two are drawn
--      Default: 832b6f 4ffd93 9bf66e a9440a 8ecbee
--Next 8 Tags should be the over (tags 25-33)
--      Default: 91a013 9492b7 b102ac ba9dc6 69d9c9 96c03a 4bb075 1d7a60


--Overall Vars
m_objMainDeck = nil -- The Main Deck
m_objArtifcatDeck= nil -- The Main Deck
m_tbPlayerInformation = nil -- Information on the Players in play
m_tbMoneyBags = nil -- Money Bags

m_btnNumberOfButtons = 0
m_iBtnDeal = -1 --Deal Button
m_iBtnShowHideButton = -1 --Deal Button
m_iBtnOverflowShowHideButton = -1 --Show Hide Overflow
m_iBtnSmoothMovementButton = -1 --SmoothMovement
m_iBtnDeckInteractable = -1 --SmoothMovement
m_iBtnUtilityInteractable = -1 --SmoothMovement

m_tbGUIDinDescription = {} -- Tags in Description

--Game Vars
m_iHazzardsCards_count = 0
m_tbHazzardsRemoved = {}
m_iRoundNumber = 0
m_iNumberOfHazzardsOutOfDeck = 0
m_bDeckIsInteractable = false
m_tmrPreRound = nil --Holds the timer identifier for the merge
m_iBetweenRoundSetup = -1
m_iNumberOfArtifactsThisGame = 0

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
m_iDontFlipNumber_0 = -1
m_bReadyForNextCard = false
m_bAreInOverflow = false
m_iNumberOfCardsInDeck = 0
m_bWaitingForPlayerResponce = false
m_iCurrentGems = 0
m_iCurrentArtifacts = 0
m_iMaxGemsInFrontOfPlayer = 0

--Deck Recovery
m_bNeedRecovery = false

--Options
m_bDeckHidden = false --State of Deck
m_bSmoothMovement = false--Movecards smoothly
m_bOverflowShown = false
m_bUtilityLocationsOn = false

function onLoad()
    createMainButton()
    createShowHideButton()
    createSmoothMovementButton()
    createOverflowShowHideButton()
    createInteractableDeckButton()
    createUtilityLocationsToggleButton()
    
    setSmoothMovement(false)
    
    m_tbGUIDinDescription = getTags(self.getDescription(),"")
    m_iCurrentPath = 2
    
    m_tbPlayerInformation = createDefaultPlayerTable()
    updatePlayerCardsInTable()
    hideAllStayLeaveCards()
    m_tbMoneyBags = createMoneyBagsTable()
    setUtilityLocations(false)
    
    resetRound()
    setDeckButtonLabel("Setup next game")
    --setupDebugTimer()
    --setDeckHidden(false)
    showHideOverflowPaths(false)
    setDeckInteractable(false)
end

function onCollisionEnter(info)
    local derp = info.collision_object
    if m_bNeedRecovery then
        deckRecovery(derp)
    end
end

function mainButton()
    if m_iBetweenRoundSetup > -1 then
        return false
    end
    
    if m_iRoundNumber == 0 then
        m_iNumberOfArtifactsThisGame = 0
        m_iRoundNumber = m_iRoundNumber + 1
        updateInPlayers()
        mergeHazardCardsToMainDeck()
        hazardCardsEmpty()
        retractAllCardsToDeck()
        dealtCardsEmpty()
        resetRound()
        
        createArtifactTakeOutTimer()
        setDeckButtonLabel("Taking out Artifacts")
        m_iBetweenRoundSetup = m_iBetweenRoundSetup + 1
    elseif m_bRoundIsOn and m_bWaitingForPlayerResponce == false then
        if m_bReadyForNextCard == true then
            if m_bShuffleBeforeDeal then
                artifactDeckShuffle()
                dealArtifactToMainDeck()
                m_bShuffleBeforeDeal = false
                createPreRoundTimer()
                return true
            end
            if dealCardInRound() >= 5 then
                m_bRoundIsOn = false
                m_iRoundNumber = m_iRoundNumber + 1
                if m_iRoundNumber >= 6 then
                    setDeckButtonLabel("Setup next game")
                    m_iRoundNumber = 0
                else
                    m_bAreInOverflow = false
                    setDeckButtonLabel("Start new round")
                end
            else
                setDeckButtonLabel("Deal")
            end
        else
            printToAll("Wooah there buddy. Slow that click down a little.")
        end
    elseif m_bWaitingForPlayerResponce then
        printToAll("Things might get dangerous...")
    else
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

function CALLBACKcardhitpath(card)
    m_bReadyForNextCard = true
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
    if m_iCurrentPath > 33 then --Ran out of paths
        return -1
    elseif m_bRoundOverDueToHazzards == true then
        return 1
    end
    local deck = getDeckObject()
    if deck == false then
        return -1
    end
    
    if m_iNumberOfCardsInDeck == -9001 then
        local deck = getDeckObject()
        if deck == nil then
            printToAll("mainButton: Could not find deck")
        end
        m_iNumberOfCardsInDeck = deck.getQuantity()
    end
    
    if m_iNumberOfCardsInDeck <= 0 then
        printToAll("Ran out of cards")
        return 7
    end
    
    local nextPath = getObjectFromGUID(m_tbGUIDinDescription[m_iCurrentPath])
    if nextPath == nil then
        printToAll("Could not find next path. Ensure all paths are in Plaque description.")
        return -1
    end
    
    local card = getCurrentNextCard(deck)
    if card == false then
        printToAll("dealCardInRound: Could not find card")
        return -1
    end
    dealtCardsStore(card) --Stores the card in the array
    local vec = nextPath.getPosition()
    
    
    if m_iNumberOfCardsInDeck > 1 then
        local vec = nextPath.getPosition()
        vec[2] = vec[2] + 0.5
        flipCardFaceUp(card, true)
        m_bReadyForNextCard = false
        if m_bSmoothMovement then
            card.setPositionSmooth(vec,  false,  false)
        else
            card.setPosition(vec)
        end
    else
        flipCardFaceUp(card)
    end
    
    m_iNumberOfCardsInDeck = m_iNumberOfCardsInDeck - 1
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
        elseif cardType == "gem" then
            local gemValue = getGemAmountFromDesc(card.getDescription())
            
            printToAll("Gem Card value: " .. gemValue)
            printToAll("Per Person: "..getGemAmountPerPerson(gemValue))
            printToAll("On Card: "..getAmountOfGemsOnCard(gemValue))
            giveGemsToSeatedPlayers(getGemAmountPerPerson(gemValue))
        end
    end
    m_iCurrentPath = m_iCurrentPath + 1
    if m_iCurrentPath == 20 then --Main paths ran out
        m_bAreInOverflow = true
        m_iCurrentPath = 25
        showHideOverflowPaths(true)
        printToAll("Ran out of paths... welcome to the overflow!")
        return 0
    elseif m_iCurrentPath > 33 then
        printToAll("Got to the end of the temple")
        return 6
    end
    
    
    
    return 0
end

function getCurrentNextCard(deck)
    if deck == nil then
        return false
    end
    local card = deck.takeObject()
    if card == nil and m_bAreInOverflow then
        return deck
    elseif card == nil then
        return false
    end
    return card
end

function resetRound()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    m_bAreInOverflow = false
    showHideOverflowPaths(false)
    
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
    resetAllPathColors()
    m_bReadyForNextCard = true
    m_iNumberOfCardsInDeck = -9001
    m_bShuffleBeforeDeal = true
    m_iCurrentGems = 0
    m_iCurrentArtifacts = 0
    m_iMaxGemsInFrontOfPlayer = 0
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
        elseif i >= 25 then
            local path = getObjectFromGUID(m_tbGUIDinDescription[i])
            if path == nil then
                printToAll("Could not find path: " .. i)
                return false
            end
            path.setColorTint( stringColorToRGB(newColor) )
            --if i == 19 then
            --    return true
            --end
        --else
        --    return true
        end
    end
    return true
end

function mainDeckShuffle()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    deck.randomize()
end

function artifactDeckShuffle()
    local deck = getArtifcatDeckObject()
    if deck == false then
        printToAll("artifactDeckShuffle: Could not find Artifact Deck")
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

function roundHazzardSpecificCheck(cardDescription, addToTotals, storeResult)
    if cardDescription == "" then
        return false
    end
    local cardTags = getTags(cardDescription,"#")
    for i, v in ipairs(cardTags) do
        if v == "#snake" then
            if addToTotals then
                m_iNumberOfHazzards_Snake = m_iNumberOfHazzards_Snake + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "snake"
        elseif v == "#mummy" then
            if addToTotals then
                m_iNumberOfHazzards_Mummy = m_iNumberOfHazzards_Mummy + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "mummy"
        elseif v == "#boulder" then
            if addToTotals then
                m_iNumberOfHazzards_Boulder = m_iNumberOfHazzards_Boulder + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "boulder"
        elseif v == "#fire" then
            if addToTotals then
                m_iNumberOfHazzards_Fire = m_iNumberOfHazzards_Fire + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "fire"
        elseif v == "#spider" then
            if addToTotals then
                m_iNumberOfHazzards_Spider = m_iNumberOfHazzards_Spider + 1
            end
            if storeResult then
                hazardCardsStore(v)
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
                hazardCardsStore(v)
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
    if _card == nil then
        return false
    end
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
    if _card == nil then
        return false
    end
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

function hazardCardsStore(_card)
    if _card == nil then
        return false
    end
    m_iHazzardsCards_count = m_iHazzardsCards_count + 1
    m_tbHazzardsRemoved[m_iHazzardsCards_count] = _card
    return true
end

function hazardCardsEmpty()
    m_iHazzardsCards_count = 0
    m_tbHazzardsRemoved = {}
    return true
end

--

function retractAllCardsToDeck()
    local vec = getPositionOfDeck()
    --if m_bDeckIsActuallyASingleCard == false then
    --    local deck = getDeckObject()
    --    if deck == false then
    --        return false
    --    end
    --    vec = deck.getPosition()
    --    vec[2] = vec[2] + 1
    --else
    --    local vec = getPositionOfDeck()
    --end
    for i, v in ipairs(m_tbDealtCards) do
        if v ~= nil and m_iDontFlipNumber_0 ~= i then
            v.setLock(false)
            flipCardFaceDown(v)
            if m_bSmoothMovement then
                v.setPositionSmooth(vec,  false,  true)
            else
                v.setPosition(vec)
            end
        end
    end
    return true
end

function mergeHazardCardsToMainDeck()
    local vec = getPositionOfDeck()
    --if m_bDeckIsActuallyASingleCard == false then
    --    local deck = getDeckObject()
    --    if deck == false then
    --        return false
    --    end
    --    vec = deck.getPosition()
    --    vec[2] = vec[2] + 1
    --else
    --    local vec = getPositionOfDeck()
    --end

    for i, v in ipairs(m_tbHazzardsRemoved) do
        if v ~= nil then
            v.setLock(false)
            flipCardFaceDown(v)
            if m_bSmoothMovement then
                v.setPositionSmooth(vec,  false,  true)
            else
                v.setPosition(vec)
            end
        end
    end
    m_iNumberOfHazzardsOutOfDeck = 0
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
            if m_bSmoothMovement then
                v.setPositionSmooth(vec,  false,  true)
            else
                v.setPosition(vec)
            end
            
            hazzardType = "#nothing" --Only one hazzard is moved
        end
    end
    m_iNumberOfHazzardsOutOfDeck = m_iNumberOfHazzardsOutOfDeck + 1
end

function dealArtifactToMainDeck()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    local artDeck = getArtifcatDeckObject()
    if artDeck == false then
        return false
    end
    local card
    if artDeck.getQuantity() > 0 then
        card = artDeck.takeObject()
    else
        card = artDeck
    end
    if card == nil then
        return false
    end
    local vec = getPositionOfDeck()
    vec[2] = vec[2] + 0.5
    if m_bSmoothMovement then
        card.setPositionSmooth(vec,  false,  true)
    else
        card.setPosition(vec)
    end
end

function toggleSmoothMovement()
    if m_bSmoothMovement then
        setSmoothMovement(false)
    else
        setSmoothMovement(true)
    end
end

function setDeckHidden(newValue)
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    
    if newValue then --Hide Deck
        m_bDeckHidden = true
        --deck.setInvisibleTo(getSeatedPlayers())
        deck.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
        setShowHideButtonLabel("Hide Deck")
    else --Show Deck
        m_bDeckHidden = false
        deck.setInvisibleTo()
        setShowHideButtonLabel("Show Deck")
    end
end

function setSmoothMovement(newValue)
    if newValue then --Hide Deck
        m_bSmoothMovement = true
        setSmoothMovementButtonLabel("Smooth Movement")
    else --Show Deck
        m_bSmoothMovement = false
        setSmoothMovementButtonLabel("Instant Movement")
    end
end

function setSmoothMovementButtonLabel(newValue)
    if m_iBtnShowHideButton ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnSmoothMovementButton
        button_parameters.label = newValue
        self.editButton(button_parameters)
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

function setOverflowButtonLabel(newValue)
    if m_iBtnOverflowShowHideButton ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnOverflowShowHideButton
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function setDeckInteractableLabel(newValue)
    if m_iBtnDeckInteractable ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnDeckInteractable
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function setUtilityButtonLabel(newValue)
    if m_iBtnDeckInteractable ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnUtilityInteractable
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function getDeckObject()
    if m_objMainDeck ~= nil then
        m_bNeedRecovery = false
        m_objMainDeck.interactable = m_bDeckIsInteractable
        return m_objMainDeck
    else
        local deck = getObjectFromGUID(m_tbGUIDinDescription[1])
        if deck == nil then
            if findDeckUsingCollider() then
                m_objMainDeck.interactable = m_bDeckIsInteractable
                return m_objMainDeck
            end
            printToAll("Could not find deck. If this keeps happenning drop the deck on the Plaque so I can find it.")
            m_bNeedRecovery = true
            return false
        end
        if findDeckUsingCollider() then
            m_objMainDeck.interactable = m_bDeckIsInteractable
            return m_objMainDeck
        end
        m_objMainDeck = deck
        m_bNeedRecovery = false
        m_objMainDeck.interactable = m_bDeckIsInteractable
        return m_objMainDeck
    end
end

function deckRecovery(obj)
    if obj == nil then
        return false
    end
    local cardTags 
    if m_bAreInOverflow and obj.getQuantity() == -1 then
        cardTags = getTags(obj.getDescription(),"#")
        if cardTags ~= false then
            if deckRecovery_ifDeckSetDeck(obj,cardTags) then
                return true
            end
        end
    end
    if obj.getQuantity() == -1 then --Not a deck
        return false
    end
    local objectsInObj = obj.getObjects()
    for i, v in ipairs(objectsInObj) do
        cardTags = getTags(v.description,"#")
        if deckRecovery_ifDeckSetDeck(obj,cardTags) then
            return true
        end
    end
    return false
end

function deckRecovery_ifDeckSetDeck(obj,cardTags)
    for j, w in ipairs(cardTags) do
            if getCardTypeFromSingleTag(w) ~= false then
                --Basically there is a playing card which we think
                --is part of the main deck in this deck
                m_objMainDeck = obj
                m_bNeedRecovery = false
                printToAll("Found the deck! Thank you. Clicking too quickly can cause me to lose it.")
                return true
            end
        end
    return false
end


function takeOutArtifactsInToNewDeck()
    local deck = getDeckObject()
    if deck == nil then
        return false
    end
    local cardTags
    if deck.getQuantity() == -1 then --Not a deck
        return false
    end
    local objectsInObj = deck.getObjects()
    for i, v in ipairs(objectsInObj) do
        cardTags = getTags(v.description,"#")
        for j, w in ipairs(cardTags) do
            if getCardTypeFromSingleTag(w) == "artifact" then
                --There is an artifact
                printToAll(j)
                --local artifactCard = getObjectFromGUID(v.guid)
                local mytable = {}
                mytable.guid = v.guid
                local artifactCard = deck.takeObject(mytable)
                if artifactCard ~= nil then
                    artifactCard.setPosition(getPositionOfArtifcatDeck())
                end
            end
        end
    end
    return false
end

function showHideOverflowPaths(showIfTrue)
    --m_tbGUIDinDescription
    for i, v in ipairs(m_tbGUIDinDescription) do
        if i >= 25 then
            local overflowPath = getObjectFromGUID(m_tbGUIDinDescription[i])
            if overflowPath ~= nil then
                if showIfTrue then
                    overflowPath.setInvisibleTo()
                else
                    overflowPath.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
                end
            end
        end
    end
    if showIfTrue then
        setOverflowButtonLabel("Show Overflow")
    else
        setOverflowButtonLabel("Hide Overflow")
    end
    m_bOverflowShown = showIfTrue
end

function toggleOverflowPaths()
    if m_bOverflowShown then
        showHideOverflowPaths(false)
    else
        showHideOverflowPaths(true)
    end
end

function setDeckInteractable(newValue)
    m_bDeckIsInteractable = newValue
    if m_bDeckIsInteractable then
        setDeckInteractableLabel("Deck Interactable")
    else
        setDeckInteractableLabel("Deck Not-interactable")
    end
    local deck = getDeckObject()
    local artifcat = getArtifcatDeckObject()
end

function toggleDeckInteractable()
    if m_bDeckIsInteractable then
        setDeckInteractable(false)
    else
        setDeckInteractable(true)
    end
end

function setUtilityLocations(newValue)
    m_bUtilityLocationsOn = newValue
    if m_bUtilityLocationsOn then
        setUtilityButtonLabel("Utility On")
        showAllLocationsForPlayers()
    else
        setUtilityButtonLabel("Utility Off")
        hideAllLocationsForPlayers()
    end
    
end

function toggleUtilityLocations()
    if m_bUtilityLocationsOn then
        setUtilityLocations(false)
    else
        setUtilityLocations(true)
    end
end

--

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

function getCardTypeFromSingleTag(cardType)
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
    elseif cardType == "#hazard" then
        return "hazard"
    elseif cardType == "#gem" then
        return "gem"
    elseif cardType == "#artifact" then
        return "artifact"
    end
    return false
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
    if requiredElement == nil then
        requiredElement = ""
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

function createSmoothMovementButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleSmoothMovement"
    button_parameters.function_owner = self
    button_parameters.position = {-5.6,0,-24}
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnSmoothMovementButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createOverflowShowHideButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleOverflowPaths"
    button_parameters.function_owner = self
    button_parameters.position = {-11,0,-21}
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnOverflowShowHideButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createInteractableDeckButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleDeckInteractable"
    button_parameters.function_owner = self
    button_parameters.position = {-11,0,-24}
    button_parameters.label = "Interactable"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDeckInteractable = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createUtilityLocationsToggleButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleUtilityLocations"
    button_parameters.function_owner = self
    button_parameters.position = {-16.5,0,-21}
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnUtilityInteractable = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function setupDebugTimer()
    timerID = self.getGUID()..math.random(9999999999999)
    --Start timer which repeats forever, running countItems() every second
    Timer.create({
        identifier=timerID,
        function_name="findItemsWhereMainDeckShouldBe", function_owner=self,
        repetitions=0, delay=1
    })
end

function findDeckUsingCollider()
    local objects = findItemsWhereMainDeckShouldBe()
    for _, entry in ipairs(objects) do
        if deckRecovery(entry.hit_object) then
            return true
        end
    end
    return false
end

function findItemsWhereMainDeckShouldBe()
    --Find scaling factor
    local scale = self.getScale()
    --Set position for the sphere
    local pos = getPositionOfDeck()
    --Ray trace to get all objects
    return Physics.cast({
        origin=pos, direction={0,1,0}, type=2, max_distance=0,
        size={5*scale.x,7.4*scale.y,5.4*scale.z}, debug=true
    })
end

function findArtifcatDeckUsingCollider()
    local objects = findItemsWhereArtifcatDeckShouldBe()
    for _, entry in ipairs(objects) do
        if artifcatDeckRecovery(entry.hit_object) then
            return true
        end
    end
    return false
end

function findItemsWhereArtifcatDeckShouldBe()
    --Find scaling factor
    local scale = self.getScale()
    --Set position for the sphere
    local pos = getPositionOfArtifcatDeck()
    --Ray trace to get all objects
    return Physics.cast({
        origin=pos, direction={0,1,0}, type=2, max_distance=0,
        size={5*scale.x,7.4*scale.y,5.4*scale.z}, debug=true
    })
end

function artifcatDeckRecovery(obj)
    if obj == nil then
        return false
    end
    local cardTags 
    if obj.getQuantity() == -1 then
        cardTags = getTags(obj.getDescription(),"#")
        if cardTags ~= false then
            if artifcatDeckRecovery_ifDeckSetDeck(obj,cardTags) then
                return true
            end
        end
        return false
    end
    local objectsInObj = obj.getObjects()
    for i, v in ipairs(objectsInObj) do
        cardTags = getTags(v.description,"#")
        if cardTags ~= false then
            if artifcatDeckRecovery_ifDeckSetDeck(obj,cardTags) then
                return true
            end
        end
    end
    return false
end

function artifcatDeckRecovery_ifDeckSetDeck(obj,cardTags)
    for j, w in ipairs(cardTags) do
        printToAll(j .. ": " .. w)
        if getCardTypeFromSingleTag(w) ~= false then
            --Basically there is a playing card which we think
            --is part of the main deck in this deck
            m_objArtifcatDeck = obj
            printToAll("Found the artifcat deck!")
            return true
        end
    end
    return false
end

function getArtifcatDeckObject()
    if m_objArtifcatDeck ~= nil then
        m_bNeedRecovery = false
        m_objArtifcatDeck.interactable = m_bDeckIsInteractable
        return m_objArtifcatDeck
    else
        if findArtifcatDeckUsingCollider() then
            m_objArtifcatDeck.interactable = m_bDeckIsInteractable
            return m_objArtifcatDeck
        end
    end
    return false
end

function getPositionOfDeck()
    local scale = self.getScale()
    local pos = self.getPosition()
    pos.z = pos.z + 22.5
    pos.x = pos.x + 5.5
    pos.y=pos.y+(1.25*scale.y)
    return pos
end

function getPositionOfArtifcatDeck()
    local scale = self.getScale()
    local pos = getPositionOfDeck()
    pos.x = pos.x + 6
    return pos
end

function createPreRoundTimer()
    m_tmrPreRound = self.getGUID()..math.random(9999999999999)
    
    Timer.create({
        identifier=m_tmrPreRound,
        function_name="shuffleAndPressMainButton", function_owner=self,
        repetitions=0, delay=2
    })
    setDeckButtonLabel("Waiting for card")
end

function shuffleAndPressMainButton()
    Timer.destroy(m_tmrPreRound)
    m_tmrPreRound = nil
    --Ensures the interaction is updated if this is a new deck now
    local deck = getArtifcatDeckObject()
    mainDeckShuffle()
    mainButton()
end

function createArtifactTakeOutTimer()
    m_tmrPreRound = self.getGUID()..math.random(9999999999999)
    
    Timer.create({
        identifier=m_tmrPreRound,
        function_name="timerCallbackArtifact", function_owner=self,
        repetitions=0, delay=2
    })
    setDeckButtonLabel("Waiting for card")
end

function timerCallbackArtifact()
    Timer.destroy(m_tmrPreRound)
    m_tmrPreRound = nil
    takeOutArtifactsInToNewDeck()
    m_iBetweenRoundSetup = m_iBetweenRoundSetup + 1
    createArtifactShuffleTimer()
end

function createArtifactShuffleTimer()
    m_tmrPreRound = self.getGUID()..math.random(9999999999999)
    
    Timer.create({
        identifier=m_tmrPreRound,
        function_name="timerCallbackShuffleArtifact", function_owner=self,
        repetitions=0, delay=2
    })
    setDeckButtonLabel("Waiting for deck")
end

function timerCallbackShuffleArtifact()
    Timer.destroy(m_tmrPreRound)
    m_tmrPreRound = nil
    artifactDeckShuffle()
    m_iBetweenRoundSetup = -1
    setDeckButtonLabel("Start next round")
end

function createDefaultPlayerTable()
    local playerTable = {}
    playerTable.Green = createDefaultSinglePlayerTable()
    playerTable.Blue = createDefaultSinglePlayerTable()
    playerTable.Purple = createDefaultSinglePlayerTable()
    playerTable.Pink = createDefaultSinglePlayerTable()
    playerTable.White = createDefaultSinglePlayerTable()
    playerTable.Red = createDefaultSinglePlayerTable()
    playerTable.Orange = createDefaultSinglePlayerTable()
    playerTable.Yellow = createDefaultSinglePlayerTable()
    return playerTable
end

function createDefaultSinglePlayerTable()
    local singlePlayer = {}
    singlePlayer.areInRound = false
    singlePlayer.areInGame = false
    singlePlayer.areInRoom = false
    singlePlayer.objCardStay = nil
    singlePlayer.objCardLeave = nil
    singlePlayer.objOutsideTenCounter = nil
    return singlePlayer
end

function updatePlayerCardsInTable()
    if m_tbPlayerInformation == nil then
        printToAll("updatePlayerCardsInTable: PlayerInformation is blank")
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    local path
    for i, v in ipairs(colorsInOrder) do
        path = getObjectFromGUID(m_tbGUIDinDescription[1 + i])
        if path ~= nil then
            if findPlayerCardsInTable(m_tbPlayerInformation[v],path.getDescription()) == false then
                printToAll("updatePlayerCardsInTable: Couldn't find "..v.." Cards")
            end
        end
    end
    return true
end

function findPlayerCardsInTable(destTable,guidsFromPath)
    local pathTags = getTags(guidsFromPath,"")
    if pathTags == false then
        return false
    end
    destTable.objCardStay = getObjectFromGUID(pathTags[2])
    if destTable.objCardStay == nil then
        return false
    end
    destTable.objCardLeave = getObjectFromGUID(pathTags[3])
    if destTable.objCardLeave == nil then
        return false
    end
    destTable.objOutsideTenCounter = getObjectFromGUID(pathTags[4])
    if destTable.objOutsideTenCounter == nil then
        return false
    end
end

function hideAllStayLeaveCards()
    if hideAllStayLeaveCards == nil then
        printToAll("hideAllStayLeaveCards: PlayerInformation is blank")
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].objCardStay ~= nil then
            m_tbPlayerInformation[v].objCardStay.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
            m_tbPlayerInformation[v].objCardStay.interactable = false
        end
        if m_tbPlayerInformation[v].objCardLeave ~= nil then
            m_tbPlayerInformation[v].objCardLeave.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
            m_tbPlayerInformation[v].objCardStay.interactable = false
        end
    end
end

function showStayLeaveCardsForInPlayers()
    if hideAllStayLeaveCards == nil then
        printToAll("hideAllStayLeaveCards: PlayerInformation is blank")
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound then
            if m_tbPlayerInformation[v].objCardStay ~= nil then
                m_tbPlayerInformation[v].objCardStay.setInvisibleTo()
                m_tbPlayerInformation[v].objCardStay.interactable = true
                flipCardFaceUp(m_tbPlayerInformation[v].objCardStay)
            end
            if m_tbPlayerInformation[v].objCardLeave ~= nil then
                m_tbPlayerInformation[v].objCardLeave.setInvisibleTo()
                m_tbPlayerInformation[v].objCardStay.interactable = true
                flipCardFaceDown(m_tbPlayerInformation[v].objCardLeave)
            end
        end
    end
end

function hideAllLocationsForPlayers()
    if hideAllStayLeaveCards == nil then
        printToAll("hideAllStayLeaveCards: PlayerInformation is blank")
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].objCardStay ~= nil then
            m_tbPlayerInformation[v].objOutsideTenCounter.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
            m_tbPlayerInformation[v].objOutsideTenCounter.interactable = false
        end
    end
end

function showAllLocationsForPlayers()
    if hideAllStayLeaveCards == nil then
        printToAll("hideAllStayLeaveCards: PlayerInformation is blank")
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].objCardStay ~= nil then
            m_tbPlayerInformation[v].objOutsideTenCounter.setInvisibleTo()
            m_tbPlayerInformation[v].objOutsideTenCounter.interactable = true
        end
    end
end

function updateInPlayers()
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        m_tbPlayerInformation[v].areInRound = false
    end
    local seatedPlayers = getSeatedPlayers()
    for i, v in ipairs(seatedPlayers) do
        m_tbPlayerInformation[v].areInRound = true
    end
end

function getNumberOfPlayersInRound()
    local playersInRound = 0
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound then
            playersInRound = playersInRound + 1
        end
    end
    return playersInRound;
end

function getGemAmountFromDesc(cardDesc)
    local cardTags = getTags(cardDesc,"#")
    if cardTags == false then
        return 0
    end
    local numberTag
    for i, v in ipairs(cardTags) do
        if v ~= nil and string.len(v) > 1 then
            local stringBarFirst = string.sub(v,2,-1)
            --So this didn't work and I've no idea why.
            --printToAll("stringBarFirst: "..stringBarFirst)
            --numberTag = toNumber(stringBarFirst,10)
            --if numberTag ~= nil then
            --    return numberTag
            --end
            if stringBarFirst == "1" then
                return 1
            elseif stringBarFirst == "2" then
                return 2
            elseif stringBarFirst == "3" then
                return 3
            elseif stringBarFirst == "4" then
                return 4
            elseif stringBarFirst == "5" then
                return 5
            elseif stringBarFirst == "7" then
                return 7
            elseif stringBarFirst == "9" then
                return 9
            elseif stringBarFirst == "11" then
                return 11
            elseif stringBarFirst == "13" then
                return 13
            elseif stringBarFirst == "14" then
                return 14
            elseif stringBarFirst == "15" then
                return 15
            elseif stringBarFirst == "17" then
                return 17
            end
        end
    end
    return 0
end

function getGemAmountPerPerson(gemAmount)
    local playersIn = getNumberOfPlayersInRound()
    local timesIn = math.floor(gemAmount / playersIn,0)
    return timesIn
end

function getAmountOfGemsOnCard(gemAmount)
    local playersIn = getNumberOfPlayersInRound()
    if math.fmod(gemAmount,playersIn) == 0 then
        return 0
    else
        local timesIn = math.floor(gemAmount / playersIn,0)
        return gemAmount - (timesIn * playersIn);
    end
end

--THIS FUNCTION BREAKS EVERYTHING
function giveGemsToSeatedPlayers(gemAmount)
    if m_tbMoneyBags.gems == nil then
        printToAll("giveGemsToSeatedPlayers: No gem bag?")
        return false
    elseif m_tbMoneyBags.gems.getQuantity() <= -1 then
        printToAll("giveGemsToSeatedPlayers: Gem Bag not a bag")
        return false
    end
    if m_tbMoneyBags.gold == nil then
        printToAll("giveGemsToSeatedPlayers: No gold bag?")
        return false
    elseif m_tbMoneyBags.gold.getQuantity() <= -1 then
        printToAll("giveGemsToSeatedPlayers: Gold Bag not a bag")
        return false
    end
    if m_tbMoneyBags.obsidian == nil then
        printToAll("giveGemsToSeatedPlayers: No obsidian bag?")
        return false
    elseif m_tbMoneyBags.obsidian.getQuantity() <= -1 then
        printToAll("giveGemsToSeatedPlayers: Obsidian Bag not a bag")
        return false
    end
    local totalSoFar = 0
    local obsidianNumber = math.floor(gemAmount / 10,0)
    totalSoFar = obsidianNumber * 10
    local goldNumber = math.floor((gemAmount - totalSoFar) / 5,0)
    totalSoFar = totalSoFar + (goldNumber * 5)
    local gemNumber = gemAmount - totalSoFar
    local _colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    local vec
    local counterObj
    --Would love to do the below code... it's real nice.
    --But I keep getting "Tuple" errors.
    --for i, v in ipairs(_colorsInOrder) do
    --    if m_tbPlayerInformation[v].areInRound then
    --        counterObj = m_tbPlayerInformation[v].objOutsideTenCounter
    --        vec = counterObj.getPosition()
    --        vec[2] = vec[2] + 0.5
    --        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
    --        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
    --        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    --    end
    --end
    --Instead:
    if m_tbPlayerInformation[_colorsInOrder[1]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[1]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[2]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[2]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[3]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[3]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[4]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[4]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[5]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[5]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[6]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[6]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[7]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[7]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    if m_tbPlayerInformation[_colorsInOrder[8]].areInRound then
        counterObj = m_tbPlayerInformation[_colorsInOrder[8]].objOutsideTenCounter
        vec = counterObj.getPosition()
        vec[2] = vec[2] + 1
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gold,vec,goldNumber)
        takeObjectsAndMoveThemSlowly(m_tbMoneyBags.obsidian,vec,obsidianNumber)
    end
    return true
end

function takeObjectsAndMoveThemSlowly(bag,dest,qty)
    local objReuse
    local vec = Vector(dest[1],dest[2],dest[3])
    local j = 0
    --printToAll("Pre: " .. qty)
    for j = qty,1,-1 do
        objReuse = bag.takeObject()
        vec = getRandomVectorFromLocation(vec,-1,1)
        objReuse.setPositionSmooth(vec,false,false)
        --printToAll("Giving: " .. qty)
    end
end

function getRandomVectorFromLocation(vec,_lower,_upper)
    _lower = _lower * 100
    _upper = _upper * 100
    local outputVec = Vector(vec[1],vec[2],vec[3])
    math.randomseed(os.time())
    outputVec[1] = outputVec[1] + (math.random(_lower, _upper) / 100)
    outputVec[3] = outputVec[3] + (math.random (_lower, _upper) / 100)
    return outputVec
end

function createMoneyBagsTable()
    local path = getObjectFromGUID(m_tbGUIDinDescription[10])
    if path == nil then
        printToAll("createMoneyBagsTable: No 9th path")
        return false
    end
    local pathTags = getTags(path.getDescription())
    if pathTags == false then
        printToAll("createMoneyBagsTable: No path description" .. path.getDescription())
        return false
    end
    local moneyBagsTable = {}
    moneyBagsTable.gems = getObjectFromGUID(pathTags[2])
    if moneyBagsTable.gems == nil or moneyBagsTable.gems == false then
        printToAll("createMoneyBagsTable: Could not find Gems bag")
    end
    moneyBagsTable.gold = getObjectFromGUID(pathTags[3])
    if moneyBagsTable.gold == nil or moneyBagsTable.gold == false then
        printToAll("createMoneyBagsTable: Could not find Gold bag")
    end
    moneyBagsTable.obsidian = getObjectFromGUID(pathTags[4])
    if moneyBagsTable.obsidian == nil or moneyBagsTable.obsidian == false then
        printToAll("createMoneyBagsTable: Could not find Obsidian bag")
    end
    moneyBagsTable.artifact_1 = getObjectFromGUID(pathTags[5])
    if moneyBagsTable.artifact_1 == nil or moneyBagsTable.artifact_1 == false then
        printToAll("createMoneyBagsTable: Could not find artifact_0")
    end
    moneyBagsTable.artifact_2 = getObjectFromGUID(pathTags[6])
    if moneyBagsTable.artifact_2 == nil or moneyBagsTable.artifact_2 == false then
        printToAll("createMoneyBagsTable: Could not find artifact_1")
    end
    moneyBagsTable.artifact_3 = getObjectFromGUID(pathTags[7])
    if moneyBagsTable.artifact_3 == nil or moneyBagsTable.artifact_3 == false then
        printToAll("createMoneyBagsTable: Could not find artifact_2")
    end
    moneyBagsTable.artifact_4 = getObjectFromGUID(pathTags[8])
    if moneyBagsTable.artifact_4 == nil or moneyBagsTable.artifact_4 == false then
        printToAll("createMoneyBagsTable: Could not find artifact_4")
    end
    moneyBagsTable.artifact_5 = getObjectFromGUID(pathTags[9])
    if moneyBagsTable.artifact_5 == nil or moneyBagsTable.artifact_5 == false then
        printToAll("createMoneyBagsTable: Could not find artifact_5")
    end
    printToAll("createMoneyBagsTable: Found money bags")
    return moneyBagsTable
end

function copyVectorToVector(original,copy)
    copy[1] = original[1]
    copy[2] = original[2]
    copy[3] = original[3]
    return true
end