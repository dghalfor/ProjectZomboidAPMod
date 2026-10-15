require "ISUI/ISPanel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

ApUI = ISPanel:derive("ApUI")

local instance = nil

function ApUI:initialise()
    ISPanel.initialise(self)
    self.isConnected = false
end

function ApUI:createChildren()
    ISPanel.createChildren(self)

    local btnWidth = 100
    local btnHeight = 25
    local padding = 10

    self.logText = ISRichTextPanel:new(padding, padding, self.width - (padding * 2), self.height - btnHeight - (padding * 3))
    self.logText:initialise()
    self.logText:instantiate()
    self.logText.autosetheight = false
    self.logText.clip = true
    self.logText.text = ""
    self.logText:paginate()
    self:addChild(self.logText)

    self.connectBtn = ISButton:new(padding, self.height - btnHeight - padding, btnWidth, btnHeight, "Connect", self, ApUI.onConnect)
    self.connectBtn:initialise()
    self.connectBtn:instantiate()
    self.connectBtn.borderColor = {r=1, g=1, b=1, a=0.4}
    self:addChild(self.connectBtn)

    self.disconnectBtn = ISButton:new(padding * 2 + btnWidth, self.height - btnHeight - padding, btnWidth, btnHeight, "Disconnect", self, ApUI.onDisconnect)
    self.disconnectBtn:initialise()
    self.disconnectBtn:instantiate()
    self.disconnectBtn.borderColor = {r=1, g=1, b=1, a=0.4}
    self.disconnectBtn:setEnable(false)
    self:addChild(self.disconnectBtn)
end

function ApUI:onConnect()
    self.connectBtn:setEnable(false)
    self:addLog("Attempting to connect to ap client...")
    local success = self:attemptConnection()
    if success then
        self.isConnected = true
        self:addLog("AP Connected successfully")
        self.disconnectBtn:setEnable(true)
    else
        self.isConnected = false
        self:addLog("Failure to connect to ap, please retry again when ap client is started")
        self.connectBtn:setEnable(true)
    end
end
function ApUI:onDisconnect()
    self.disconnectBtn:setEnable(false)
    self:addLog("Disconnecting from ap client...")
    self:doDisconnect()
    self.isConnected = false
    self:addLog("AP Disconnected successfully")
    self.connectBtn:setEnable(true)
end

function ApUI:attemptConnection()
    local ap = require("apclient")
    if ap and ap.connect then
        if ap.connect() == 0 then
            return true
        else
            return false
        end
    else
        return false
    end
end

function ApUI:doDisconnect()
    local ap = require("apclient")
    if ap and ap.disconnect then
        ap.disconnect()
    else
        print("Unable to disconnect")
    end
end

function ApUI:addLog(text)
    if self.logText.text ~= "" then
        self.logText.text = self.logText.text .. " <LINE> "
    end
    self.logText.text = self.logText.text .. text
    self.logText:paginate()
end

function ApUI:clearLog()
    self.logText.text = ""
    self.logText:paginate()
end

function ApUI:setConnectStat(connected)
    self.isConnected = connected
    if connected then
        self.connectBtn:setEnable(false)
        self.disconnectBtn:setEnable(true)
    else
        self.connectBtn:setEnable(true)
        self.disconnectBtn:setEnable(false)
    end
end

function ApUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.moveWithMouse = true
    return o
end

function ApUI:getInstance()
    if not instance then
        local width = 600
        local height = 400
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        instance = ApUI:new(x, y, width, height)
        instance:initialise()
        instance:addToUIManager()
    end
    return instance
end

function ApUI.addLogGlobal(text)
    local ui = ApUI:getInstance()
    if ui then
        ui:addLog(text)
    end
end

function ApUI.setConnectStatGlob(connected)
    local ui = ApUI:getInstance()
    if ui then
        ui:setConnectStat(connected)
    end
end

local function onExitSave()
    if instance then
        if instance.isConnected then
            instance:addLog("Exiting game disconnecting from ap client...")
            instance:doDisconnect()
            instance.isConnected = false
        end
        instance:clearLog()
        if instance:isVisible() then
            instance:setVisible(false)
            instance:removeFromUIManager()
        end
        instance = nil
    end
end

Events.OnPostSave.Add(onExitSave)