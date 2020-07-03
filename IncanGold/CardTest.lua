function onLoad()
    local button_parameters = {}

    button_parameters.click_function = "buttonClick"
    button_parameters.function_owner = self

button_parameters.position = {2,0,0}
    button_parameters.label = "Press Me"
    button_parameters.width = 300

    self.createButton(button_parameters) 
end

function buttonClick()
    print("There are ",getNumberOfSeatedPlayers()," players")
end

function getNumberOfSeatedPlayers()
    numberOfPlayers = 0
    if Player["Blue"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["Red"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["Pink"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["White"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["Orange"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["Yellow"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["Green"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    if Player["Purple"].seated == true then
        numberOfPlayers = numberOfPlayers + 1
    end
    return numberOfPlayers
end