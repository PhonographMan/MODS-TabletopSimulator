function onLoad()
    local button_parameters = {}

    button_parameters.click_function = "buttonClick"
    button_parameters.function_owner = self

button_parameters.position = {0,0,-21}
    button_parameters.label = "Deal"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    self.createButton(button_parameters) 
    
    deck = getObjectFromGUID(self.getDescription())
    
    deck.setInvisibleTo(getSeatedPlayers())
end

function buttonClick()
    deck = getObjectFromGUID(self.getDescription())
    card = deck.takeObject()
    vec = getObjectFromGUID("3a7ba4").getPosition()
    vec[2] = vec[2] + 0.5
    card.setPositionSmooth(vec,  false,  true)
    
    deck.setInvisibleTo(getSeatedPlayers())
end
--de1e9e
--getSnapPoints() --Returns Table