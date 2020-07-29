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
--The last tag is a scriptable area over just the cards: 713538

-- rotations
no_rotation = {x = 0, y = 0, z = 0}
flip_y = {x = 0, y = 180, z = 0}
flip_y_z = {x = 0, y = 180, z = 180}

--Overall Vars
m_objMainDeck = nil -- The Main Deck
m_objArtifcatDeck= nil -- The Main Deck
m_tbPlayerInformation = nil -- Information on the Players in play
m_tbMoneyBags = nil -- Money Bags
m_objCardArea = nil -- Area with the cards

m_btnNumberOfButtons = 0
m_iBtnDeal = -1 --Deal Button


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
m_bMoveOnFromStayLeave = false
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
m_tbGemsOnCards = {} --Holds objs for the gems
m_tbGemsOnCardsNumbersUsed = {} --Holds objs for the gems
m_iMaxGemsInFrontOfPlayer = 0
m_iNumberOfGemsInTable = 0 --How many gems in above

--Deck Recovery
m_bNeedRecovery = false

--Options
m_bDeckHidden = false --State of Deck
m_bSmoothMovement = false--Movecards smoothly
m_bOverflowShown = false
m_bUtilityLocationsOn = false

--Buttons
m_vecDebugButtonLocation = Vector(0,0,0)
m_vecDebugButtonRotation = Vector(0,0,0)
m_sDebugColor = ""

m_iBtnDebugButton = -1 --ID for the Debug Button
m_iBtnShowHideButton = -1 --ID for the Show Hide Button
m_iBtnOverflowShowHideButton = -1 --Show Hide Overflow
m_iBtnSmoothMovementButton = -1 --SmoothMovement
m_iBtnDeckInteractable = -1 --SmoothMovement
m_iBtnUtilityInteractable = -1 --Utility Button
m_iBtnCardsInteract = -1 --Interact Cards

m_iBtnPlayerDebugMoveButtons = -1 --Color debug option: Move player
m_iBtnPlayerInDebugButtons = -1 --Color debug option: Players in

m_iBtnDebugGreen = -1 --Colors: Green
m_iBtnDebugBlue = -1 --Colors: Blue
m_iBtnDebugPurple = -1 --Colors: Purple
m_iBtnDebugPink = -1 --Colors: Pink
m_iBtnDebugWhite = -1 --Colors: White
m_iBtnDebugRed = -1 --Colors: Red
m_iBtnDebugOrange = -1 --Colors: Orange
m_iBtnDebugYellow = -1 --Colors: Yellow

function onLoad()
    createButtons()
    createMainButton()
    --createShowHideButton()
    --createSmoothMovementButton()
    --createOverflowShowHideButton()
    --createInteractableDeckButton()
    --createUtilityLocationsToggleButton()
    
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
    
    gemsOnCards_setupArea()
    --obj.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Grey"})
    
    local obj
    for _,obj in ipairs(getAllObjects()) do
        if obj.tag == 'Fog' then
            --printToAll(obj.getValue())
            --if obj.getValue() == "Red" then
            --    obj.setValue("White")
            --end
            obj.interactable = false
            -- obj is a hidden zone, do stuff with it
        end
    end
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
            if m_bMoveOnFromStayLeave then
                if playersLeavingActionPlayers_OnDeal() == false then
                    return false
                end
            elseif m_bShuffleBeforeDeal then
                updateInPlayers()
                artifactDeckShuffle()
                dealArtifactToMainDeck()
                m_bShuffleBeforeDeal = false
                createPreRoundTimer()
                return true
            end
            hideLeaveCardsOfNotInPlayers()--HidesAnyLeftOverCards
            if dealCardInRound() >= 5 then
                moveToNextRound() --Sets up next round.
                --Above is only really called here or if all players leave.
            else
                setDeckButtonLabel("Deal")
                if m_iMaxGemsInFrontOfPlayer > 0 or m_iNumberOfGemsInTable >  0 then
                    givePlayersStayLeave()
                end
            end
        else
            printToAll("Wooah there buddy. Slow that click down a little.")
        end
    elseif m_bWaitingForPlayerResponce then
        printToAll("Things might get dangerous...")
        printPlayersWhoWereWaitingFor()
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

function moveToNextRound()
    m_bRoundIsOn = false
    m_iRoundNumber = m_iRoundNumber + 1
    if m_iRoundNumber >= 6 then
        setDeckButtonLabel("Setup next game")
        m_iRoundNumber = 0
    else
        m_bAreInOverflow = false
        setDeckButtonLabel("Start new round")
    end
    m_iNumberOfGemsInTable = 0
    m_iMaxGemsInFrontOfPlayer = 0
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
    
    local gemValue = 0
    local valueForPlayers = 0
    local valueForCards = 0
    if cardType ~= false and cardType ~= "" then
        if cardType == "hazard" then
            --true in the below adds the hazzard to round totals
            m_sRoundOverDueToHazzard = roundHazzardSpecificCheck(card.getDescription(), true)
            local hazzardEnder = roundHazzardUpdate()
            if hazzardEnder ~= "" then
                gemsOnCards_destroyAll()
                markDoubleHazzards(m_sRoundOverDueToHazzard)
                printToAll("Two " .. hazzardEnder .. " cards")
                m_bRoundOverDueToHazzards = true
                return 5
            end
        elseif cardType == "gem" then
            printToAll("-----------GEM-----------")
            gemValue = getGemAmountFromDesc(card.getDescription())
            valueForPlayers = getGemAmountPerPerson(gemValue)
            valueForCards = getAmountOfGemsOnCard(gemValue)
            printToAll("Gem Card value: " .. gemValue)
            printToAll("Per Person: "..valueForPlayers)
            printToAll("On Card: "..valueForCards)
            
            giveGemsToSeatedPlayers(valueForPlayers)
            giveGemsToCards(valueForCards,card)
            
            m_iMaxGemsInFrontOfPlayer = m_iMaxGemsInFrontOfPlayer + valueForPlayers
            m_iNumberOfGemsInTable = m_iMaxGemsInFrontOfPlayer + valueForCards
            printToAll("---------------------")
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
        gemsOnCards_destroyAll()
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
    m_iNumberOfGemsInTable = 0
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

--
--
--  FLIPPING CARDS
--
--

function flipCardFaceUp(_card, _isMainDeckCard)
    if _card == nil then
        return false
    end
    --Seems the wrong way around.
    --It's this way for the main deck.
    --if _isMainDeckCard then
    --    return flipCardFaceDown(_card)
    --end
    local rot = _card.getRotation()
    local goalrotation = Vector(rot[1],rot[2],0)
    
    if rot[3] > 90 and rot[3] < 270 then --face down
    --if _card.is_face_down then  --Mean card is face down
        --_card.flip()
        _card.setRotationSmooth(goalrotation,false,false)
        printToAll("flipCardFaceUp:" .. _card.getName() .. ":" .. rot[3])
        --_card.setRotationSmooth(no_rotation,false)
    else
        printToAll("flipCardFaceUp: else" .. _card.getName() .. ":" .. rot[3])
    end
    return true
end

function flipCardFaceDown(_card, _isMainDeckCard)
    if _card == nil then
        return false
    end
    --if _isMainDeckCard then
    --    return flipCardFaceUp(_card)
    --end
    --if _card.is_face_down == false then --Mean card is face up
    local rot = _card.getRotation()
    local goalrotation = Vector(rot[1],rot[2],180)
    
    if rot[3] < 90 or rot[3] > 270 then --face up
        --_card.flip()
        _card.setRotationSmooth(goalrotation,false,false)
        --_card.setRotationSmooth(no_rotation,false)
        printToAll("flipCardFaceDown:" .. _card.getName() .. ":" .. rot[3])
    else
        printToAll("flipCardFaceDown: else" .. _card.getName() .. ":" .. rot[3])
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
                --printToAll("Found the deck! Thank you. Clicking too quickly can cause me to lose it.")
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
                --printToAll(j)--Debugging
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

function setupDebugTimer()
    timerID = self.getGUID()..math.random(9999999999999)
    --Start timer which repeats forever, running countItems() every second
    Timer.create({
        identifier=timerID,
        function_name="findItemsWhereMainDeckShouldBe", function_owner=self,
        repetitions=1, delay=1
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
        --printToAll(j .. ": " .. w)
        if getCardTypeFromSingleTag(w) ~= false then
            --Basically there is a playing card which we think
            --is part of the main deck in this deck
            m_objArtifcatDeck = obj
            --printToAll("Found the artifcat deck!")
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
        repetitions=1, delay=2
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
        repetitions=1, delay=2
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
        repetitions=1, delay=2
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
    singlePlayer.objHiddenZone = nil
    singlePlayer.objCardStay = nil
    singlePlayer.objCardStayInDrop = false
    singlePlayer.objCardLeave = nil
    singlePlayer.objCardLeaveInDrop = false
    singlePlayer.objOutsideTenCounter = nil
    singlePlayer.objLeaveOutsideTent = nil
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
    destTable.objHiddenZone = getObjectFromGUID(pathTags[5])
    if destTable.objHiddenZone == nil then
        return false
    end
    destTable.objLeaveOutsideTent = getObjectFromGUID(pathTags[6])
    if destTable.objLeaveOutsideTent == nil then
        return false
    end
end

function hideAllStayLeaveCards()
    if m_tbPlayerInformation == nil then
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
            m_tbPlayerInformation[v].objCardLeave.interactable = false
        end
        if m_tbPlayerInformation[v].objLeaveOutsideTent ~= nil then
            m_tbPlayerInformation[v].objLeaveOutsideTent.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
            m_tbPlayerInformation[v].objLeaveOutsideTent.interactable = false
        end
    end
end

function showStayLeaveCardsForInPlayers()
    if m_tbPlayerInformation == nil then
        printToAll("showStayLeaveCardsForInPlayers: PlayerInformation is blank")
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
    if m_tbPlayerInformation == nil then
        printToAll("hideAllLocationsForPlayers: PlayerInformation is blank")
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
    if m_tbPlayerInformation == nil then
        printToAll("showAllLocationsForPlayers: PlayerInformation is blank")
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
    
    if m_bPlayersInOverride_Green then
        m_tbPlayerInformation["Green"].areInRound = true
    end
    if m_bPlayersInOverride_Blue then
        m_tbPlayerInformation["Blue"].areInRound = true
    end
    if m_bPlayersInOverride_Purple then
        m_tbPlayerInformation["Purple"].areInRound = true
    end
    if m_bPlayersInOverride_Pink then
        m_tbPlayerInformation["Pink"].areInRound = true
    end
    if m_bPlayersInOverride_White then
        m_tbPlayerInformation["White"].areInRound = true
    end
    if m_bPlayersInOverride_Red then
        m_tbPlayerInformation["Red"].areInRound = true
    end
    if m_bPlayersInOverride_Orange then
        m_tbPlayerInformation["Orange"].areInRound = true
    end
    if m_bPlayersInOverride_Yellow then
        m_tbPlayerInformation["Yellow"].areInRound = true
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

function getGemAmountSplit(gemAmount, splitBetween)
    local playersIn = splitBetween
    if playersIn == 0 then
        return 0
    end
    local timesIn = math.floor(gemAmount / playersIn,0)
    return timesIn
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

function giveGemsToCards(gemAmount, card)
    if gemAmount <= 0 then
        return false
    end
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
    local vec = card.getPosition()
    vec[2] = vec[2] + 0.5
    takeObjectsAndMoveThemSlowly(m_tbMoneyBags.gems,vec,gemAmount,true)
    return true
end

function takeObjectsAndMoveThemSlowly(bag,dest,qty,onCards)
    local lowerSend = -1
    local upperSend = 1
    if onCards == nil or onCards == false then
        lowerSend = -0.5
        upperSend = 0.5
    end
    local vec = Vector(dest[1],dest[2],dest[3])
    local j = 0
    --printToAll("Pre: " .. qty)
    for j = qty,1,-1 do
        takeObjectsAndMoveThemSlowly_actuallyDoTheMoving(vec,bag,onCards,lowerSend,upperSend)
    end
    return true
end

function takeObjectsAndMoveThemSlowly_actuallyDoTheMoving(dest, bag, onCards, _lower,_upper)
    --So because with cards we want to store the objects
    --We can't just use a reusable var
    --because lua we can't just keep refering to a local var (scope is not a thing like in C)
    --So you need to use a function scrope:
    local objReuse = bag.takeObject()
    local vec = getRandomVectorFromLocation(dest,_lower,_upper)
    objReuse.setPositionSmooth(vec,false,false)
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
    else
        moneyBagsTable.gems.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey","Black"})
        moneyBagsTable.gems.interactable = false
    end
    moneyBagsTable.gold = getObjectFromGUID(pathTags[3])
    if moneyBagsTable.gold == nil or moneyBagsTable.gold == false then
        printToAll("createMoneyBagsTable: Could not find Gold bag")
    else
        moneyBagsTable.gold.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey","Black"})
        moneyBagsTable.gold.interactable = false
    end
    moneyBagsTable.obsidian = getObjectFromGUID(pathTags[4])
    if moneyBagsTable.obsidian == nil or moneyBagsTable.obsidian == false then
        printToAll("createMoneyBagsTable: Could not find Obsidian bag")
    else
        moneyBagsTable.obsidian.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey","Black"})
        moneyBagsTable.obsidian.interactable = false
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
    --printToAll("createMoneyBagsTable: Found money bags")
    return moneyBagsTable
end

function copyVectorToVector(original,copy)
    copy[1] = original[1]
    copy[2] = original[2]
    copy[3] = original[3]
    return true
end

--
--
--  STORE GEMS ON CARDS
--
--

function gemsOnCards_setupArea()
    m_objCardArea = getObjectFromGUID(m_tbGUIDinDescription[33])
    if m_objCardArea == nil then
        printToAll("Could not find card scriptable zone")
    end
end

function gemsOnCards_count()
    if m_objCardArea == nil then
        printToAll("gemsOnCards_count: Zone not set.")
        return false
    end
    local number = 0
    for i, v in ipairs(m_objCardArea.getObjects()) do
        local desc = v.getDescription()
        local tags = getTags(desc,"")
        if tags ~= false then
            if gemsOnCards_isGem(tags) then
                number = number + 1
            end
        end
    end
    return number
end

function gemsOnCards_getAll()
    if m_objCardArea == nil then
        printToAll("gemsOnCards_count: Zone not set.")
        return false
    end
    local output = {}
    for i, v in ipairs(m_objCardArea.getObjects()) do
        local desc = v.getDescription()
        local tags = getTags(desc,"")
        if tags ~= false then
            if gemsOnCards_isGem(tags) then
                table.insert(output,v)
            end
        end
    end
    return output
end

function gemsOnCards_destroyAll()
    local allGems = gemsOnCards_getAll()
    if gemsOnCards_getAll() == false then
        return false
    end
    for i, v in ipairs(allGems) do
        v.destroy()
    end
    return true
end

function gemsOnCards_isGem(tags)
    for i, v in ipairs(tags) do
        if v == "1" then
            return true
        end
    end
    return false
end

--
--
--  COLOR FUNCTIONS
--
--

function getColorWhite()
    return {1, 1, 1}
end

function getColorBrown()
    return {0.443, 0.231, 0.09}
end

function getColorRed()
    return {0.856, 0.1, 0.094}
end

function getColorOrange()
    return {0.956, 0.392, 0.113}
end

function getColorYellow()
    return {0.905, 0.898, 0.172}
end

function getColorGreen()
    return {0.192, 0.701, 0.168}
end

function getColorTeal()
    return {0.129, 0.694, 0.607}
end

function getColorBlue()
    return {0.118, 0.53, 1}
end

function getColorPurple()
    return {0.627, 0.125, 0.941}
end

function getColorPink()
    return {0.96, 0.439, 0.807}
end

function getColorGrey()
    return {0.5, 0.5, 0.5}
end

function getColorBlack()
    return {0.25, 0.25, 0.25}
end

--
--
--  GENERIC BUTTON FUNCTIONS
--
--

function setButtonLabel(buttonIndex, buttonLabel)
    local button_parameters = {}
    button_parameters.index = buttonIndex
    
    button_parameters.label = buttonLabel
    
    self.editButton(button_parameters)
end

function setButtonColor(buttonIndex, backgroundColor, fontColor, hoverColor, pressColor)
    local button_parameters = {}
    button_parameters.index = buttonIndex
    
    if backgroundColor ~= nil then
        button_parameters.color = {}
        button_parameters.color[1] = backgroundColor[1]
        button_parameters.color[2] = backgroundColor[2]
        button_parameters.color[3] = backgroundColor[3]
        button_parameters.color[4] = backgroundColor[4]
    end
    if fontColor ~= nil then
        button_parameters.font_color = {}
        button_parameters.font_color[1] = fontColor[1]
        button_parameters.font_color[2] = fontColor[2]
        button_parameters.font_color[3] = fontColor[3]
        button_parameters.font_color[4] = fontColor[4]
    end
    if hoverColor ~= nil then
        button_parameters.hover_color = {}
        button_parameters.hover_color[1] = hoverColor[1]
        button_parameters.hover_color[2] = hoverColor[2]
        button_parameters.hover_color[3] = hoverColor[3]
        button_parameters.hover_color[4] = hoverColor[4]
    end
    if pressColor ~= nil then
        button_parameters.press_color = {}
        button_parameters.press_color[1] = pressColor[1]
        button_parameters.press_color[2] = pressColor[2]
        button_parameters.press_color[3] = pressColor[3]
        button_parameters.press_color[4] = pressColor[4]
    end
    
    self.editButton(button_parameters)
end

function setButtonClickableColors(buttonIndex)
    setButtonColor(buttonIndex,getColorWhite(),getColorBlack())
end

function setButtonDisabledColors(buttonIndex)
    setButtonColor(buttonIndex,getColorGrey(),getColorWhite())
end

--
--
--  DEBUG BUTTONS
--
--

function createButtons()
    m_vecDebugButtonLocation = {-27,0,25}
    m_vecDebugButtonRotation = {0,0,0}
    createDebugOnOrOff()
    createShowHideButton()
    createSmoothMovementButton()
    createOverflowShowHideButton()
    createInteractableDeckButton()
    createUtilityLocationsToggleButton()
    createCardsInteractToggleButton()
    
    createPlayerOptionMoveDebugToggle()
    createPlayerOptionPlayersInDebugToggle()
    
    createPlayerButtonColorGreen()
    createPlayerButtonColorBlue()
    createPlayerButtonColorPurple()
    createPlayerButtonColorPink()
    
    createPlayerButtonColorWhite()
    createPlayerButtonColorRed()
    createPlayerButtonColorOrange()
    createPlayerButtonColorYellow()
    
    moveDebugButtons("Red")
    debugSetPlayerInSetup()
    debugSetPlayerWithButtonsSetup()
end

function createDebugOnOrOff()
    local button_parameters = {}

    button_parameters.click_function = "BTNCLICK_Debug"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3]
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Debug On/Off"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    button_parameters.tooltip = "Turns on or off debuging options"
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updateDebugOnOrOffTransform()
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugButton
    
    if m_sDebugColor == "Red" then
        button_parameters.position = {}
        button_parameters.position[1] = m_vecDebugButtonLocation[1]
        button_parameters.position[2] = m_vecDebugButtonLocation[2]
        button_parameters.position[3] = m_vecDebugButtonLocation[3]
    elseif m_sDebugColor == "White" then
        button_parameters.position = {}
        button_parameters.position[1] = m_vecDebugButtonLocation[1]
        button_parameters.position[2] = m_vecDebugButtonLocation[2]
        button_parameters.position[3] = m_vecDebugButtonLocation[3]
    end
    
    self.editButton(button_parameters)
end

function createShowHideButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleDeckVisibility"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] - 12
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 3
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    button_parameters.tooltip = "Shows or hides the deck"
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnShowHideButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updateShowHideTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnShowHideButton
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3]
    
    self.editButton(button_parameters)
end

function createSmoothMovementButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleSmoothMovement"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] - 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 3
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnSmoothMovementButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updateSmoothMovementTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnSmoothMovementButton
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3]
    
    self.editButton(button_parameters)
end

function createOverflowShowHideButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleOverflowPaths"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 3
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnOverflowShowHideButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updateOverflowShowHideTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnOverflowShowHideButton
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 12
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3]
    
    self.editButton(button_parameters)
end

function createInteractableDeckButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleDeckInteractable"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 6
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Interactable"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDeckInteractable = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updateInteractableDeckTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDeckInteractable
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 3
    
    self.editButton(button_parameters)
end

function createUtilityLocationsToggleButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleUtilityLocations"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] - 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 6
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnUtilityInteractable = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updateUtilityLocationsToggleTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnUtilityInteractable
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 3
    
    self.editButton(button_parameters)
end

function createCardsInteractToggleButton()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_CardsInteract"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] - 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 6
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Cards Inter"
    button_parameters.tooltip = "Make cards in hand interactable"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnCardsInteract = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createPlayerOptionMoveDebugToggle()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugSelectDebugger"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 6
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnPlayerDebugMoveButtons = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerOptionMoveDebugTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnPlayerDebugMoveButtons
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 6
    
    self.editButton(button_parameters)
end

function createPlayerOptionPlayersInDebugToggle()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugPlayerIn"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 6
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnPlayerInDebugButtons = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerOptionPlayersInDebugTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnPlayerInDebugButtons
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 6
    
    self.editButton(button_parameters)
end

--
--  DEBUG COLORS
--

function createPlayerButtonColorGreen()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorGreen"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 9
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Green"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugGreen = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorGreenTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugGreen
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 9
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorBlue()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorBlue"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 9
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Blue"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugBlue = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorBlueTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugBlue
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 9
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorPurple()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorPurple"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 12
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 9
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Purple"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugPurple = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorPurpleTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugPurple
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 12
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 9
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorPink()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorPink"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 18
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 9
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Pink"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugPink = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorPinkTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugPink
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 18
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 9
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorWhite()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorWhite"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 12
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "White"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugWhite = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorWhiteTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugWhite
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1]
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 12
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorRed()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorRed"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 12
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Red"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugRed = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorRedTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugRed
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 6
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 12
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorOrange()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorOrange"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 12
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 12
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Orange"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugOrange = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorOrangeTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugOrange
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 12
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 12
    
    self.editButton(button_parameters)
end

function createPlayerButtonColorYellow()
    local button_parameters = {}
    
    button_parameters.click_function = "BTNCLICK_DebugColorYellow"
    button_parameters.function_owner = self
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + 18
    button_parameters.position[2] = m_vecDebugButtonLocation[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + 12
    
    button_parameters.rotation = m_vecDebugButtonRotation
    button_parameters.label = "Yellow"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDebugYellow = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function updatePlayerButtonColorYellowTransform(leftTopMostOffset)
    if leftTopMostOffset == nil or leftTopMostOffset == false then
         return false
    end
    local button_parameters = {}
    button_parameters.index = m_iBtnDebugYellow
    
    
    button_parameters.position = {}
    button_parameters.position[1] = m_vecDebugButtonLocation[1] + leftTopMostOffset[1] + 18
    button_parameters.position[2] = m_vecDebugButtonLocation[2] + leftTopMostOffset[2]
    button_parameters.position[3] = m_vecDebugButtonLocation[3] + leftTopMostOffset[3] + 12
    
    self.editButton(button_parameters)
end

--
--  MOVEMENT
--

function moveDebugButtons(color)
    local leftTopMostOffset = Vector(0,0,0)
    
    m_sDebugColor = color;
    if color == "Red" then
        m_vecDebugButtonLocation = {-27,0,25}
        m_vecDebugButtonRotation = {0,0,0}
        
        leftTopMostOffset[1] = leftTopMostOffset[1] - (6 * 3)
        leftTopMostOffset[3] = leftTopMostOffset[3] + 3
    elseif color == "White" then
        m_vecDebugButtonLocation = {27,0,25}
        m_vecDebugButtonRotation = {0,0,0}
        
        leftTopMostOffset[3] = leftTopMostOffset[3] + 3
    end
    updateDebugOnOrOffTransform()
    
    updateShowHideTransform(leftTopMostOffset)
    updateSmoothMovementTransform(leftTopMostOffset)
    updateOverflowShowHideTransform(leftTopMostOffset)
    
    updateInteractableDeckTransform(leftTopMostOffset)
    updateUtilityLocationsToggleTransform(leftTopMostOffset)
    
    updatePlayerOptionMoveDebugTransform(leftTopMostOffset)updatePlayerOptionPlayersInDebugTransform(leftTopMostOffset)
    
    updatePlayerButtonColorGreenTransform(leftTopMostOffset)
    updatePlayerButtonColorBlueTransform(leftTopMostOffset)
    updatePlayerButtonColorPurpleTransform(leftTopMostOffset)
    updatePlayerButtonColorPinkTransform(leftTopMostOffset)
    
    updatePlayerButtonColorWhiteTransform(leftTopMostOffset)
    updatePlayerButtonColorRedTransform(leftTopMostOffset)
    updatePlayerButtonColorOrangeTransform(leftTopMostOffset)
    updatePlayerButtonColorYellowTransform(leftTopMostOffset)
end



--
--
--  PLAYING BUTTONS
--
--

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

--
--
--  DEBUG METHODS
--
--

m_iDebugSettingsPlayer = 0
m_bPlayersInOverride_Green = false
m_bPlayersInOverride_Blue = false
m_bPlayersInOverride_Purple = true
m_bPlayersInOverride_Pink = true
m_bPlayersInOverride_White = true
m_bPlayersInOverride_Red = true
m_bPlayersInOverride_Orange = false
m_bPlayersInOverride_Yellow = false


--setButtonColor(buttonIndex, backgroundColor, fontColor, hoverColor, pressColor)

--obj: The Object the button is attached to.
--player_clicker_color: Player Color of the player that pressed the button.
--alt_click: True if a button other than left-click was used to click the button.
function BTNCLICK_DebugSelectDebugger(obj, player_clicker_color, alt_click)
    debugSetPlayerWithButtonsSetup()
end

function debugSetPlayerWithButtonsSetup()
    m_iDebugSettingsPlayer = 0
    setButtonLabel(m_iBtnPlayerDebugMoveButtons,"Select Debugger")
    --Make this button highlighted
    setButtonClickableColors(m_iBtnPlayerDebugMoveButtons)
    --Make other buttons not
    setButtonDisabledColors(m_iBtnPlayerInDebugButtons)
    updateColorsForDebugLocation()
end

function BTNCLICK_DebugPlayerIn(obj, player_clicker_color, alt_click)
    debugSetPlayerInSetup()
end


function debugSetPlayerInSetup()
    m_iDebugSettingsPlayer = 1
    setButtonLabel(m_iBtnPlayerInDebugButtons,"Players in")
    --Make this button highlighted
    setButtonClickableColors(m_iBtnPlayerInDebugButtons)
    --Make other buttons not
    setButtonDisabledColors(m_iBtnPlayerDebugMoveButtons)
    --Update Colors
    updateColorsForPlayersIn()
end


function BTNCLICK_DebugColorGreen(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Green then
            m_bPlayersInOverride_Green = false
            setButtonColor(m_iBtnDebugGreen,getColorGrey())
        else
            m_bPlayersInOverride_Green = true
            setButtonColor(m_iBtnDebugGreen,getColorGreen())

        end
    end
end

function BTNCLICK_DebugColorBlue(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Blue then
            m_bPlayersInOverride_Blue = false
            setButtonColor(m_iBtnDebugBlue,getColorGrey())
        else
            m_bPlayersInOverride_Blue = true
            setButtonColor(m_iBtnDebugBlue,getColorBlue())

        end
    end
end

function BTNCLICK_DebugColorPurple(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Purple then
            m_bPlayersInOverride_Purple = false
            setButtonColor(m_iBtnDebugPurple,getColorGrey())
        else
            m_bPlayersInOverride_Purple = true
            setButtonColor(m_iBtnDebugPurple,getColorPurple())

        end
    end
end

function BTNCLICK_DebugColorPink(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Pink then
            m_bPlayersInOverride_Pink = false
            setButtonColor(m_iBtnDebugPink,getColorGrey())
        else
            m_bPlayersInOverride_Pink = true
            setButtonColor(m_iBtnDebugPink,getColorPink())

        end
    end
end

function BTNCLICK_DebugColorWhite(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_White then
            m_bPlayersInOverride_White = false
            setButtonColor(m_iBtnDebugWhite,getColorGrey())
        else
            m_bPlayersInOverride_White = true
            setButtonColor(m_iBtnDebugWhite,getColorWhite())

        end
    end
end

function BTNCLICK_DebugColorRed(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Red then
            m_bPlayersInOverride_Red = false
            setButtonColor(m_iBtnDebugRed,getColorGrey())
        else
            m_bPlayersInOverride_Red = true
            setButtonColor(m_iBtnDebugRed,getColorRed())

        end
    end
end

function BTNCLICK_DebugColorOrange(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Orange then
            m_bPlayersInOverride_Orange = false
            setButtonColor(m_iBtnDebugOrange,getColorGrey())
        else
            m_bPlayersInOverride_Orange = true
            setButtonColor(m_iBtnDebugOrange,getColorOrange())

        end
    end
end

function BTNCLICK_DebugColorYellow(obj, player_clicker_color, alt_click)
    if m_iDebugSettingsPlayer == 1 then
        if m_bPlayersInOverride_Yellow then
            m_bPlayersInOverride_Yellow = false
            setButtonColor(m_iBtnDebugYellow,getColorGrey())
        else
            m_bPlayersInOverride_Yellow = true
            setButtonColor(m_iBtnDebugYellow,getColorYellow())

        end
    end
end

function BTNCLICK_CardsInteract(obj, player_clicker_color, alt_click)
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].objCardStay ~= nil then
            m_tbPlayerInformation[v].objCardStay.interactable = true
        end
        if m_tbPlayerInformation[v].objCardLeave ~= nil then
            m_tbPlayerInformation[v].objCardLeave.interactable = true
        end
    end
end

function updateColorsForDebugLocation()
    local color = string.lower(m_sDebugColor)
    setButtonColor(m_iBtnDebugGreen,getColorGrey())
    setButtonColor(m_iBtnDebugBlue,getColorGrey())
    setButtonColor(m_iBtnDebugPurple,getColorGrey())
    setButtonColor(m_iBtnDebugPink,getColorGrey())
    setButtonColor(m_iBtnDebugWhite,getColorGrey())
    setButtonColor(m_iBtnDebugRed,getColorGrey())
    setButtonColor(m_iBtnDebugOrange,getColorGrey())
    setButtonColor(m_iBtnDebugYellow,getColorGrey())
    
    if color == "green" then
        setButtonColor(m_iBtnDebugGreen,getColorGreen())
    end
    if color == "blue" then
        setButtonColor(m_iBtnDebugBlue,getColorBlue())
    end
    if color == "purple" then
        setButtonColor(m_iBtnDebugPurple,getColorPurple()) 
    end
    if color == "pink" then
        setButtonColor(m_iBtnDebugPink,getColorPink()) 
    end
    if color == "white" then
        setButtonColor(m_iBtnDebugWhite,getColorWhite())
    end
    if color == "red" then
        setButtonColor(m_iBtnDebugRed,getColorRed())
    end
    if color == "orange" then
        setButtonColor(m_iBtnDebugOrange,getColorOrange())
    end
    if color == "yellow" then
        setButtonColor(m_iBtnDebugYellow,getColorYellow())
    end
end

function updateColorsForPlayersIn()
    if m_bPlayersInOverride_Green then
        setButtonColor(m_iBtnDebugGreen,getColorGreen())
    else
        setButtonColor(m_iBtnDebugGreen,getColorGrey())
    end
    if m_bPlayersInOverride_Blue then
        setButtonColor(m_iBtnDebugBlue,getColorBlue())
    else
        setButtonColor(m_iBtnDebugBlue,getColorGrey())
    end
    if m_bPlayersInOverride_Purple then
        setButtonColor(m_iBtnDebugPurple,getColorPurple())
    else
        setButtonColor(m_iBtnDebugPurple,getColorGrey())
    end
    if m_bPlayersInOverride_Pink then
        setButtonColor(m_iBtnDebugPink,getColorPink())
    else 
        setButtonColor(m_iBtnDebugPink,getColorGrey())
    end
    if m_bPlayersInOverride_White then
        setButtonColor(m_iBtnDebugWhite,getColorWhite())
    else
        setButtonColor(m_iBtnDebugWhite,getColorGrey())
    end
    if m_bPlayersInOverride_Red then
        setButtonColor(m_iBtnDebugRed,getColorRed())
    else
        setButtonColor(m_iBtnDebugRed,getColorGrey())
    end
    if m_bPlayersInOverride_Orange then
        setButtonColor(m_iBtnDebugOrange,getColorOrange())
    else
        setButtonColor(m_iBtnDebugOrange,getColorGrey())
    end
    if m_bPlayersInOverride_Yellow then
        setButtonColor(m_iBtnDebugYellow,getColorYellow())
    else
        setButtonColor(m_iBtnDebugYellow,getColorGrey())
	end
end

--
--
--  PLAYER CARDS
--
--
function givePlayersStayLeave()
    m_bWaitingForPlayerResponce = true
    giveStayLeaveCardsToPlayers()
    TIMER_startPlayerCardTimer()
    setDeckButtonLabel("Danger!")
end

function giveStayLeaveCardsToPlayers()
    if m_tbPlayerInformation == nil then
        printToAll("giveStayLeaveCardsToPlayers: PlayerInformation is blank")
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound then
            if m_tbPlayerInformation[v].objCardStay ~= nil then
                --Deal to player
                m_tbPlayerInformation[v].objCardStay.deal(1,v)
                m_tbPlayerInformation[v].objCardStayInDrop = true
                
                --Flip Face Up only leave card
                flipCardFaceUp(m_tbPlayerInformation[v].objCardStay)
                --Make visible / Interactable
                m_tbPlayerInformation[v].objCardStay.setInvisibleTo()
                m_tbPlayerInformation[v].objCardStay.interactable = true
            end
            if m_tbPlayerInformation[v].objCardLeave ~= nil then
                --Deal to Player
                m_tbPlayerInformation[v].objCardLeave.deal(1,v)
                 m_tbPlayerInformation[v].objCardLeaveInDrop = true
                 m_tbPlayerInformation[v].objCardLeave.registerCollisions()
                --Flip Face Down only leave card
                flipCardFaceDown(m_tbPlayerInformation[v].objCardLeave)
                --Make visible / Interactable
                m_tbPlayerInformation[v].objCardLeave.setInvisibleTo()
                m_tbPlayerInformation[v].objCardLeave.interactable = true
            end
            if m_tbPlayerInformation[v].objLeaveOutsideTent ~= nil then
                m_tbPlayerInformation[v].objLeaveOutsideTent.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
                m_tbPlayerInformation[v].objLeaveOutsideTent.interactable = false
            end
        end
    end
end

function areAllCardsOut(printToBlack)
    if m_tbPlayerInformation == nil then
        printToAll("areAllCardsOut: PlayerInformation is blank")
        return false
    end
    if printToBlack == nil then
        printToBlack = false
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound then
            --Players in Round
            if m_tbPlayerInformation[v].objCardStay ~= nil and m_tbPlayerInformation[v].objCardLeave ~= nil then
                --Have Cards
                --if m_tbPlayerInformation[v].objCardStayInZone and m_tbPlayerInformation[v].objCardLeaveInZone then
                if isCardOutOfHiddenZone(m_tbPlayerInformation[v].objCardStay.guid) == false and isCardOutOfHiddenZone(m_tbPlayerInformation[v].objCardLeave.guid) == false then
                    --printToAll(v .. " in the zone")
                    --Both Cards are in the zone
                    return false
                end
                if m_tbPlayerInformation[v].objCardStayInDrop == false or  m_tbPlayerInformation[v].objCardLeaveInDrop == false then
                    --A card is in the hand
                    --printToAll(v .. " in the hands")
                    return false
                end
                if printToBlack then
                    printToColor(v .. " is fine","Black")
                end
            else
                printToAll("areAllCardsOut: Couldn't find" .. v .. " cards. Probably an issue")
            end
        end
    end
    return true
end

function isCardOutOfHiddenZone(guidOfCard) --true means it is out
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].objHiddenZone == nil then
            return true
        end
        for j, w in ipairs(m_tbPlayerInformation[v].objHiddenZone.getObjects()) do
            if w.guid == guidOfCard then
                return false
            end
        end
    end
    return true
end

function isCardOutOfHiddenZone_color(guidOfCard, color) --true means it is out
    if m_tbPlayerInformation[color].objHiddenZone == nil then
        return true
    end
    for j, w in ipairs(m_tbPlayerInformation[color].objHiddenZone.getObjects()) do
        if w.guid == guidOfCard then
            return false
        end
    end
    return true
end

function canFlipCardsOver()
    if m_tbPlayerInformation == nil then
        printToAll("canFlipCardsOver: PlayerInformation is blank")
        return false
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound then
            --Players in Round
            --if m_tbPlayerInformation[v].objCardStayInZone == false and m_tbPlayerInformation[v].objCardLeaveInZone == false then
            if isCardOutOfHiddenZone(m_tbPlayerInformation[v].objCardStay.guid) and isCardOutOfHiddenZone(m_tbPlayerInformation[v].objCardLeave.guid) then
                m_sWarningIsOn = v
                return false
            end
            
        end
    end
    m_sWarningIsOn = ""
    return true
end

function flipOverAllStayLeave()
    if m_tbPlayerInformation == nil then
        printToAll("flipOverAllStayLeave: PlayerInformation is blank")
        return false
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    --printToAll("Who's in and out?")
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound then
            if isCardOutOfHiddenZone(m_tbPlayerInformation[v].objCardStay.guid) then
                flipCardFaceUp(m_tbPlayerInformation[v].objCardStay)
            end
            if isCardOutOfHiddenZone(m_tbPlayerInformation[v].objCardLeave.guid) then
                flipCardFaceUp(m_tbPlayerInformation[v].objCardLeave)
                playersLeavingAddPlayers(v)
                playerLeavingShowLeavingCard(v)
            end
        end
    end
    return true
end

function hideLeaveCardsOfNotInPlayers()
    if m_tbPlayerInformation == nil then
        printToAll("hideLeaveCardsOfNotInPlayers: PlayerInformation is blank")
        return false
    end
    local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if m_tbPlayerInformation[v].areInRound == false then
            m_tbPlayerInformation[v].objCardLeave.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
                m_tbPlayerInformation[v].objCardLeave.interactable = false
            m_tbPlayerInformation[v].objCardStay.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
            m_tbPlayerInformation[v].objCardStay.interactable = false
            
            if m_tbPlayerInformation[v].objLeaveOutsideTent ~= nil then
                m_tbPlayerInformation[v].objLeaveOutsideTent.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
                m_tbPlayerInformation[v].objLeaveOutsideTent.interactable = false
            end
        end
    end
    return true
end

m_tbPlayerForRewards = {}
m_tbCurrentGems = {}
m_tbCurrentGems_current = 0

function playersLeavingAddPlayers(color)
    table.insert(m_tbPlayerForRewards,color)
end

function playersLeavingAddPlayers_count()
    local num = 0
    for i, v in ipairs(m_tbPlayerForRewards) do
        num = num + 1
    end
    return num
end

function playersLeavingActionPlayers()
    if playersLeavingAddPlayers_count() <= 0 then
        return false
    end
    local lowerSend = -1
    local upperSend = 1
    local vec = Vector(0,0,0)
    
    
    local numberOfGemsOnTable = gemsOnCards_count()
    local numberOfPlayers = playersLeavingAddPlayers_count()
    local gemsPerPlayer = getGemAmountSplit(numberOfGemsOnTable, numberOfPlayers)--Gems, Players
    printToAll("playersLeavingActionPlayers: Attempting to give gems: " .. gemsPerPlayer .. " numberOfGemsOnTable: " .. numberOfGemsOnTable .. " Players to give to: " .. numberOfPlayers) 
    if gemsPerPlayer > 0 then
        m_tbCurrentGems_current = 1
        m_tbCurrentGems = gemsOnCards_getAll()
        for i, v in ipairs(m_tbPlayerForRewards) do
            if m_tbPlayerInformation[v].objOutsideTenCounter ~= nil then
            vec = m_tbPlayerInformation[v].objOutsideTenCounter.getPosition()
            printToAll("Giving Stage 1: ".. v.. ": " .. gemsPerPlayer)
            playersLeavingActionPlayers_givingGems(gemsPerPlayer, vec,lowerSend,upperSend)
            else
                printToAll(v .. " doesn't have a tent location")
            end
        end
        m_tbCurrentGems = {}
    end
end

function playersLeavingActionPlayers_OnDeal()
    for i, v in ipairs(m_tbPlayerForRewards) do
        m_tbPlayerInformation[v].areInRound = false
    end
    m_bMoveOnFromStayLeave = false
    
    m_tbPlayerForRewards = {}
    
    if getNumberOfPlayersInRound() <= 0 then
        moveToNextRound()
        if m_iRoundNumber > 0 then --We're in the round then deal
            mainButton()
        end
        return false
    end
    return true
end

function playersLeavingActionPlayers_givingGems(gemsToGive, vec, _lower, _upper)
    local tbReuse = {}
    for j = gemsToGive,1,-1 do
        playersLeavingActionPlayers_givingGems_inner(vec,_lower, _upper)
    end
end

function playersLeavingActionPlayers_givingGems_inner(vec,_lower,_upper)
    local obj = m_tbCurrentGems[m_tbCurrentGems_current]
    m_tbCurrentGems_current = m_tbCurrentGems_current + 1
    vec = getRandomVectorFromLocation(vec,_lower,_upper)
    obj.setPositionSmooth(vec,false,false)
end

function playersLeavingMoveLeavingCard(color)
    --This would be fine but the cards have collision
    --for like a whole second after you move them
    --then freeze in place... it just didn't work.
    --Use playerLeavingShowLeavingCard instead.
    if m_tbPlayerInformation == nil then
        printToAll("hideLeaveCardsOfNotInPlayers: PlayerInformation is blank")
        return false
    end
    local counter = m_tbPlayerInformation[color].objOutsideTenCounter
    local leaveCard = m_tbPlayerInformation[color].objCardLeave
    leaveCard.unregisterCollisions()
    leaveCard.setPositionSmooth(counter.getPosition(),false,false)
    leaveCard.interactable = false
    local goalRot = Vector(0,0,0)
    if color == "Pink" or color == "Purple" then
        goalRot[2] = 270
    elseif color == "Green" or color == "Blue" then
        goalRot[2] = 180
    elseif color == "Orange" or color == "Yellow" then
        goalRot[2] = 90
    end
    leaveCard.setRotationSmooth(goalRot,false,false);
    
    m_tbPlayerInformation[color].objCardStay.deal(1,color)
    m_tbPlayerInformation[color].objCardStay.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
    m_tbPlayerInformation[color].objCardStay.interactable = false
    return true
end

function playerLeavingShowLeavingCard(color)
    if m_tbPlayerInformation == nil then
        printToAll("hideLeaveCardsOfNotInPlayers: PlayerInformation is blank")
        return false
    end
    m_tbPlayerInformation[color].objCardStay.deal(1,color)
    m_tbPlayerInformation[color].objCardStay.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
    m_tbPlayerInformation[color].objCardStay.interactable = false
    
    m_tbPlayerInformation[color].objCardLeave.deal(1,color)
    m_tbPlayerInformation[color].objCardLeave.setInvisibleTo({"Yellow","Orange","Blue","Green","Purple","Pink","White","Red","Grey"})
    m_tbPlayerInformation[color].objCardLeave.interactable = false
    
    if m_tbPlayerInformation[color].objLeaveOutsideTent ~= nil then
        m_tbPlayerInformation[color].objLeaveOutsideTent.setInvisibleTo()
        m_tbPlayerInformation[color].objLeaveOutsideTent.interactable = false
    end
end

function printPlayersWhoWereWaitingFor()
    areAllCardsOut(true)
end
--
--
--  PLAYER CARDS TIMERS
--
--

m_tmrPlayerCard = nil --Stores the ID for the timer
m_tmrPlayerCardWarning = nil --Stores the ID for the warning timer
m_sWarningIsOn = "" --Stores the ID for the warning timer

function TIMER_startPlayerCardTimer()
    m_tmrPlayerCard = self.getGUID()..math.random(9999999999999)
    --Start timer which repeats forever, running countItems() every second
    --This is repeating... stop it from doing that
    Timer.create({
        identifier=m_tmrPlayerCard,
        function_name="TIMERCALLBACK_PlayerCardTimer", function_owner=self,
        repetitions=0, delay=1
    })
    TIMER_startPlayerCardTimerWarning()
end

function TIMERCALLBACK_PlayerCardTimer()
    --printToAll("Attempt")
    if areAllCardsOut() then
        --printToAll("First step")
        if canFlipCardsOver() then
            --printToAll("S'all good")
            if flipOverAllStayLeave() then
                playersLeavingActionPlayers()
                
                Timer.destroy(m_tmrPlayerCard)
                Timer.destroy(m_tmrPlayerCardWarning)
                m_tmrPlayerCard = nil
                m_tmrPlayerCardWarning = nil
                m_sWarningIsOn = ""
                m_bWaitingForPlayerResponce = false
                
                m_bMoveOnFromStayLeave = true
                setDeckButtonLabel("Deal")
                --THIS IS THE END OF A CHOOSEN ROUND --
            end
        end
    end
end

function TIMER_startPlayerCardTimerWarning()
    m_tmrPlayerCardWarning = self.getGUID()..math.random(9999999999999)
    --Start timer which repeats forever, running countItems() every second
    --This is repeating... stop it from doing that
    Timer.create({
        identifier=m_tmrPlayerCardWarning,
        function_name="TIMERCALLBACK_PlayerCardTimerWarning", function_owner=self,
        repetitions=0, delay=3
    })
end

function TIMERCALLBACK_PlayerCardTimerWarning()
    if m_sWarningIsOn ~= "" then
        printToAll("Woooow... " .. m_sWarningIsOn .. " is eger. Try choosing one card")
    end
end

--
--
--  OBJECT CALLS
--
--

--
--singlePlayer.objCardStay = nil
--singlePlayer.objCardStayInZone = false
--singlePlayer.objCardStayInDrop = false
--

function onObjectDrop(colorName, obj)
     local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if obj.guid == m_tbPlayerInformation[v].objCardStay.guid then
            m_tbPlayerInformation[v].objCardStayInDrop = true
            --printToAll(v .. " stay drop ")
        end
        if obj.guid == m_tbPlayerInformation[v].objCardLeave.guid then
            m_tbPlayerInformation[v].objCardLeaveInDrop = true
            --printToAll(v .. " leave drop ")
        end
    end
end

function onObjectPickUp(colorName, obj)
     local colorsInOrder = {"Green","Blue","Purple","Pink","White","Red","Orange","Yellow"}
    for i, v in ipairs(colorsInOrder) do
        if obj.guid == m_tbPlayerInformation[v].objCardStay.guid then
            m_tbPlayerInformation[v].objCardStayInDrop = false
            
            if isCardOutOfHiddenZone_color(obj.guid, v) == false then
                flipCardFaceDown(m_tbPlayerInformation[v].objCardStay)
            end
            --printToAll(v .. " stay pickup ")
        end
        if obj.guid == m_tbPlayerInformation[v].objCardLeave.guid then
            m_tbPlayerInformation[v].objCardLeaveInDrop = false
            if isCardOutOfHiddenZone_color(obj.guid, v) == false then
                flipCardFaceDown(m_tbPlayerInformation[v].objCardLeave)
            end
            --printToAll(v .. " leave pickup ")
        end
    end
end