require "ApUI"

local archipelagoBtn = nil

local function onArchipelagoMenu()
    local ui = ApUI:getInstance()
    if ui:isVisible() then
        ui:setVisible(false)
        ui:removeFromUIManager()
        print("UI hidden")
        if archipelagoBtn and archipelagoBtn.iconOff then
            archipelagoBtn:setImage(archipelagoBtn.iconOff)
        end
    else
        ui:setVisible(true)
        ui:addToUIManager()
        ui:bringToTop()
        print("UI shown")
        if archipelagoBtn and archipelagoBtn.iconOn then
            archipelagoBtn:setImage(archipelagoBtn.iconOn)
        end
    end
end

local function addArchipelagoButton()
    local playerIndex = 0
    local playerData = getPlayerData(playerIndex)
    if not playerData then 
        print("No playerData")
        return
    end
    local equippedUI = playerData.equipped
    if not equippedUI then
        print("No equipped UI found")
        return
    end
    if archipelagoBtn then 
        print("Button already exists")
        return
    end
    local lowestY = 10
    local btnX = 5
    local btnSpacing = 5
    for _, child in pairs(equippedUI.children) do
        if child.Type == "ISButton" then
            local btnBottom = child:getY() + child:getHeight()
            if btnBottom > lowestY then
                lowestY = btnBottom
                btnX = child:getX()
            end
        end
    end
    local absoluteX = equippedUI:getAbsoluteX() + btnX - 5
    local absoluteY = equippedUI:getAbsoluteY() + lowestY + btnSpacing + 2
    local btnWidth = 50
    local btnHeight = 36
    archipelagoBtn = ISButton:new(absoluteX, absoluteY, btnWidth, btnHeight, "", nil, onArchipelagoMenu)
    archipelagoBtn:initialise()
    archipelagoBtn:instantiate()
    archipelagoBtn:addToUIManager()
    archipelagoBtn.isButton = true
    archipelagoBtn.enable = true
    archipelagoBtn.displayBackground = false
    archipelagoBtn.textureColor = {r=1, g=1, b=1, a=1}
    local iconOff = getTexture("media/textures/ui/archipelago_icon_2.png")
    local iconOn = getTexture("media/textures/ui/archipelago_icon.png")
    if iconOff and iconOn then
        archipelagoBtn.iconOff = iconOff
        archipelagoBtn.iconOn = iconOn
        archipelagoBtn:setImage(iconOff)
        print("Archipelago icons loaded")
    else
        print("Failed to load Archipelago icons")
    end
    archipelagoBtn.borderColor = {r=1, g=1, b=1, a=0}
    archipelagoBtn.backgroundColorMouseOver = {r=1, g=1, b=1, a=0.1}
    local ui = ApUI:getInstance()
    ui:setVisible(false)
    ui:removeFromUIManager()
    print("Archipelago button added successfully")
end

Events.OnGameStart.Add(addArchipelagoButton)