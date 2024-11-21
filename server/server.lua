local Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
discordWebhook = BccUtils.Discord.setup(Config.Webhook, Config.WebhookTitle, Config.WebhookAvatar)

local playerSessionStart = {}

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. tostring(message or "No message provided"))
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

-- Helper function to get player identifiers
local function GetPlayerIdentifiersData(_source)
    local identifiers = GetPlayerIdentifiers(_source)
    local data = { license = nil, discord = nil, steam = nil, live = nil, xbl = nil, license2 = nil, fivem = nil }

    -- Iterate through player identifiers and extract specific ones
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, string.len("license:")) == "license:" then
            data.license = string.gsub(id, "license:", "")
        elseif string.sub(id, 1, string.len("discord:")) == "discord:" then
            data.discord = string.gsub(id, "discord:", "")
        elseif string.sub(id, 1, string.len("steam:")) == "steam:" then
            data.steam = string.gsub(id, "steam:", "")
        elseif string.sub(id, 1, string.len("live:")) == "live:" then
            data.live = string.gsub(id, "live:", "")
        elseif string.sub(id, 1, string.len("xbl:")) == "xbl:" then
            data.xbl = string.gsub(id, "xbl:", "")
        elseif string.sub(id, 1, string.len("license2:")) == "license2:" then
            data.license2 = string.gsub(id, "license2:", "")
        elseif string.sub(id, 1, string.len("fivem:")) == "fivem:" then
            data.fivem = string.gsub(id, "fivem:", "")
        end
    end

    return data
end

function UpdateAllPlayerPlaytime()
    for license, sessionData in pairs(playerSessionStart) do
        local connectTime = sessionData.connectTime
        local _source = sessionData.source

        if connectTime then
            local currentTime = os.time()
            local sessionPlayTimeMinutes = math.floor((currentTime - connectTime) / 60)

            if sessionPlayTimeMinutes > 0 then
                -- Update the connect time for the next interval
                playerSessionStart[license].connectTime = currentTime

                -- Directly increment playtimes in one update query
                MySQL.update(
                    'UPDATE bcc_player_connections SET players_playTime = players_playTime + ?, players_dailyPlayTime = players_dailyPlayTime + ?, players_weeklyPlayTime = players_weeklyPlayTime + ?, players_monthlyPlayTime = players_monthlyPlayTime + ? WHERE license = ?',
                    { sessionPlayTimeMinutes, sessionPlayTimeMinutes, sessionPlayTimeMinutes, sessionPlayTimeMinutes, license },
                    function(affectedRows)
                                if affectedRows > 0 then
                            devPrint("Successfully updated playtime for license: " .. license)
                                else
                            devPrint("Failed to update playtime for license: " .. license)
                                end
                    end
                )
            else
                devPrint("No new playtime to update for license: " .. license)
            end
        else
            devPrint("No connect time found for license: " .. license)
        end
    end
end

-- Initialize connected players on script start
function ReinitializePlayers()
    devPrint("Reinitializing players on script start...")
    for _, playerId in ipairs(GetPlayers()) do
        local _source = tonumber(playerId)
        local identifiers = GetPlayerIdentifiersData(_source)
        if identifiers.license then
            playerSessionStart[identifiers.license] = { connectTime = os.time(), source = _source }
            devPrint("Initialized session for connected player with license: " .. identifiers.license)
        end
    end
end

-- Event triggered every minute to update playtime
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        UpdateAllPlayerPlaytime()
    end
end)

-- Update daily playtime for a specific license
function UpdateDailyPlaytime(license, playTime)
    MySQL.update('UPDATE bcc_player_connections SET players_dailyPlayTime = players_dailyPlayTime + ? WHERE license = ?',
        { playTime, license }, function(affectedRows)
        if affectedRows > 0 then
            devPrint("Successfully updated daily playtime for license: " .. license)
        else
            devPrint("Failed to update daily playtime for license: " .. license)
        end
    end)
end

-- Update weekly playtime for a specific license
function UpdateWeeklyPlaytime(license, playTime)
    MySQL.update('UPDATE bcc_player_connections SET players_weeklyPlayTime = players_weeklyPlayTime + ? WHERE license = ?',
        { playTime, license }, function(affectedRows)
        if affectedRows > 0 then
            devPrint("Successfully updated weekly playtime for license: " .. license)
        else
            devPrint("Failed to update weekly playtime for license: " .. license)
        end
    end)
end

-- Update monthly playtime for a specific license
function UpdateMonthlyPlaytime(license, playTime)
    MySQL.update('UPDATE bcc_player_connections SET players_monthlyPlayTime = players_monthlyPlayTime + ? WHERE license = ?',
        { playTime, license }, function(affectedRows)
        if affectedRows > 0 then
            devPrint("Successfully updated monthly playtime for license: " .. license)
        else
            devPrint("Failed to update monthly playtime for license: " .. license)
        end
    end)
end

-- Handle player connecting and check database for existing record
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local _source = source
    local playerName = GetPlayerName(_source)
    local identifiers = GetPlayerIdentifiersData(_source)
    local playerIp = GetPlayerEndpoint(_source)
    local playerPing = GetPlayerPing(_source)

    if not identifiers.license then
        local message23 = "❌ Unable to identify your license. Please restart your game."
        setKickReason(message23)
        discordWebhook:sendMessage("🚫 Player **" .. playerName .. "** was unable to connect: " .. message)
        CancelEvent()
        return
    end

    -- Store the connection time for session tracking
    playerSessionStart[identifiers.license] = { connectTime = os.time(), source = _source }
    devPrint("Player added to session with license:" .. (identifiers.license or "N/A"))

    local identifierInfo =
        "License: `" .. (identifiers.license or "N/A") .. "`\n" ..
        "Discord: `" .. (identifiers.discord or "N/A") .. "`\n" ..
        "Steam: `" .. (identifiers.steam or "N/A") .. "`\n" ..
        "FiveM: `" .. (identifiers.fivem or "N/A") .. "`\n" ..
        "IP: `" .. (playerIp or "N/A") .. "`\n" ..
        "Ping: `" .. tostring(playerPing or 0) .. "ms`"

    -- Wrap sendMessage in pcall to catch any errors
    local success, err = pcall(function()
        discordWebhook:sendMessage("✅ Player **" .. playerName .. "** added to session.\n" .. identifierInfo)
    end)

    if not success then
        print("Failed to send Discord message: " .. tostring(err))
    end

    -- Optional: print to console for confirmation
    devPrint("Player added to session with license:" .. (identifiers.license or "N/A"))

    MySQL.query('SELECT id FROM bcc_player_connections WHERE license = ?', { identifiers.license }, function(result)
        local tsLastConnection = os.time()

        if result and #result > 0 then
            MySQL.update('UPDATE bcc_player_connections SET players_tsLastConnection = ? WHERE id = ?',
                { tsLastConnection, result[1].id }, function(affectedRows)
                ---devPrint(message)
            end)
        else
            local playTime, tsJoined = 0, os.time()
            MySQL.insert('INSERT INTO bcc_player_connections (license, discord_id, steam_id, fivem_id, license2, live_id, xbl_id, players_displayName, players_playTime, players_tsJoined, players_tsLastConnection) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                {
                    identifiers.license, identifiers.discord, identifiers.steam, identifiers.fivem, identifiers.license2,
                    identifiers.live, identifiers.xbl, playerName, playTime, tsJoined, tsLastConnection
                }, function(id)
                --devPrint(message)
            end)
        end
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    local playerName = GetPlayerName(_source)
    local identifiers = GetPlayerIdentifiersData(_source)
    local playerIp = GetPlayerEndpoint(_source)
    local playerPing = GetPlayerPing(_source)

    if identifiers.license and playerSessionStart[identifiers.license] then
        -- Calculate session duration in seconds
        local sessionStartTime = playerSessionStart[identifiers.license].connectTime
        local sessionEndTime = os.time()
        local sessionDuration = sessionEndTime - sessionStartTime

        -- Convert session duration to hours, minutes, and seconds for logging
        local hours = math.floor(sessionDuration / 3600)
        local minutes = math.floor((sessionDuration % 3600) / 60)
        local seconds = sessionDuration % 60
        local sessionTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

        -- Update only the last session time and total playtime in the database
        MySQL.update('UPDATE bcc_player_connections SET players_lastSessionTime = ?, players_playTime = players_playTime + ?, players_tsLastConnection = ? WHERE license = ?',
            { sessionDuration, sessionDuration, sessionEndTime, identifiers.license }, 
            function(affectedRows)
                if affectedRows > 0 then
                    devPrint("Successfully logged session time for license: " .. identifiers.license)
                else
                    devPrint("Failed to log session time for license: " .. identifiers.license)
                end
            end)

        -- Prepare identifier info for Discord message
        local identifierInfo = string.format(
            "License: `%s`\nDiscord: `%s`\nSteam: `%s`\nFiveM: `%s`\nIP: `%s`\nPing: `%d`ms",
            tostring(identifiers.license),
            tostring(identifiers.discord),
            tostring(identifiers.steam),
            tostring(identifiers.fivem),
            tostring(playerIp),
            tonumber(playerPing) or 0)

        -- Construct and send the session end message to Discord
        local message = string.format("👋 Player **%s** disconnected. Reason: %s\n%s\nSession Duration: `%s`",
            playerName or "Unknown", reason, identifierInfo, sessionTime)
        discordWebhook:sendMessage(message)
        
        -- Remove the player from session tracking
        playerSessionStart[identifiers.license] = nil
    end
end)

-- Show player's playtime command
RegisterCommand(Config.playTimeCommad, function(source, args, rawCommand)
    local _source = source
    local identifiers = GetPlayerIdentifiersData(_source)

    MySQL.query('SELECT players_playTime FROM bcc_player_connections WHERE license = ?', { identifiers.license },
        function(result)
            if result and #result > 0 then
                local totalPlayTimeMinutes = result[1].players_playTime

                -- Calculate current session time if player is still connected
                local sessionStart = playerSessionStart[identifiers.license] and
                playerSessionStart[identifiers.license].connectTime
                local currentSessionTime = 0

                if sessionStart then
                    currentSessionTime = math.floor((os.time() - sessionStart) / 60) -- convert session time from seconds to minutes
                end

                -- Add session time to the total playtime
                local combinedPlayTime = totalPlayTimeMinutes + currentSessionTime

                -- Convert playtime to days, hours, and minutes
                local days = math.floor(combinedPlayTime / 1440)
                local hours = math.floor((combinedPlayTime % 1440) / 60)
                local minutes = combinedPlayTime % 60

                Core.NotifyObjective(_source, _U('total_playtime_message') .. days .. _U('totalDays') .. hours .. _U('totalHours').. minutes.. _U('totalMintutes'), 4000)
            else
                Core.NotifyObjective(_source, _U("playtime_not_found_message"), 4000)
            end
        end)
end, false)

RegisterCommand(Config.lastSessioncommand, function(source, args, rawCommand)
    local _source = source
    local identifiers = GetPlayerIdentifiersData(_source)

    -- Query the last session time for the player
    MySQL.query('SELECT players_lastSessionTime FROM bcc_player_connections WHERE license = ?', { identifiers.license }, function(result)
        if result and #result > 0 then
            local lastSessionTime = result[1].players_lastSessionTime or 0

            -- Convert the session time from seconds to hours, minutes, and seconds
            local hours = math.floor(lastSessionTime / 3600)
            local minutes = math.floor((lastSessionTime % 3600) / 60)
            local seconds = lastSessionTime % 60

            local formattedTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            -- Send the formatted session time to the player
            Core.NotifyObjective(_source, "Your last session playtime was: " .. formattedTime, 4000)
        else
            Core.NotifyObjective(_source, "Could not retrieve your last session time. Please ensure you are registered in the database.", 4000)
        end
    end)
end, false)

RegisterCommand(Config.leaderboard, function(source, args, rawCommand)
    TriggerClientEvent('bcc-userlog:openMainLeaderboardMenu', source)
end, false)

RegisterNetEvent('bcc-userlog:requestLeaderboardData')
AddEventHandler('bcc-userlog:requestLeaderboardData', function(leaderboardType)
    local source = source
    local query = ""
    local title = ""

    if leaderboardType == "daily" then
        query = 'SELECT players_displayName, players_dailyPlayTime FROM bcc_player_connections ORDER BY players_dailyPlayTime DESC LIMIT 30'
        title = "Daily Leaderboard"
    elseif leaderboardType == "weekly" then
        query = 'SELECT players_displayName, players_weeklyPlayTime FROM bcc_player_connections ORDER BY players_weeklyPlayTime DESC LIMIT 30'
        title = "Weekly Leaderboard"
    elseif leaderboardType == "monthly" then
        query = 'SELECT players_displayName, players_monthlyPlayTime FROM bcc_player_connections ORDER BY players_monthlyPlayTime DESC LIMIT 30'
        title = "Monthly Leaderboard"
    end

    -- Fetch and send leaderboard data to the client
    MySQL.query(query, {}, function(result)
        TriggerClientEvent('bcc-userlog:displayLeaderboard', source, result, title)
    end)
end)

RegisterNetEvent('bcc-userlog:fetchLeaderboardHistory')
AddEventHandler('bcc-userlog:fetchLeaderboardHistory', function(historyType)
    local source = source

    -- Ensure historyType is valid
    local query, title
    if historyType == "daily" then
        query = "SELECT player_displayName, playtime FROM bcc_leaderboard_history WHERE leaderboard_type = 'daily' AND DATE(recorded_at) = CURDATE() - INTERVAL 1 DAY ORDER BY playtime DESC LIMIT 30"
        title = "Yesterday's Daily Leaderboard"
    elseif historyType == "weekly" then
        query = "SELECT player_displayName, playtime FROM bcc_leaderboard_history WHERE leaderboard_type = 'weekly' AND recorded_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ORDER BY playtime DESC LIMIT 30"
        title = "Last Week's Weekly Leaderboard"
    elseif historyType == "monthly" then
        query = "SELECT player_displayName, playtime FROM bcc_leaderboard_history WHERE leaderboard_type = 'monthly' AND recorded_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) ORDER BY playtime DESC LIMIT 30"
        title = "Last Month's Monthly Leaderboard"
    else
        -- Log an error if historyType is not valid and return early
        print("Invalid historyType received:", historyType)
        TriggerClientEvent('bcc-userlog:displayLeaderboardHistory', source, {}, "Invalid Leaderboard History Type")
        return
    end

    -- Execute the query and send results to the client
    MySQL.insert(query, {}, function(results)
        if results and #results > 0 then
            -- Log results for debugging
            print("Sending leaderboard data to client:", json.encode(results))
            TriggerClientEvent('bcc-userlog:displayLeaderboardHistory', source, results, title)
        else
            print("No leaderboard data found for:", historyType)
            TriggerClientEvent('bcc-userlog:displayLeaderboardHistory', source, {}, title)  -- Send empty data if none found
        end
    end)
end)

-- Daily Reset Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(86400000)  -- 24-hour interval for daily reset

        -- Record daily leaderboard to history
        MySQL.insert("INSERT INTO bcc_leaderboard_history (player_id, player_displayName, playtime, leaderboard_type) " ..
                    "SELECT id, players_displayName, players_dailyPlayTime, 'daily' FROM bcc_player_connections WHERE players_dailyPlayTime > 0")

        -- Reset daily playtime
        MySQL.update("UPDATE bcc_player_connections SET players_dailyPlayTime = 0")

        print("Daily playtime reset and snapshot completed.")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)  -- Check every minute

        local currentDate = os.date("*t")
        
        -- Daily Reset at Midnight
        if currentDate.hour == 0 and currentDate.min == 0 then
            MySQL.insert("INSERT INTO bcc_leaderboard_history (player_id, player_displayName, playtime, leaderboard_type) " ..
                        "SELECT id, players_displayName, players_dailyPlayTime, 'daily' FROM bcc_player_connections WHERE players_dailyPlayTime > 0")
            MySQL.update("UPDATE bcc_player_connections SET players_dailyPlayTime = 0")
            print("Daily playtime reset and snapshot completed.")
        end

        -- Weekly Reset on Monday at Midnight
        if currentDate.wday == 2 and currentDate.hour == 0 and currentDate.min == 0 then  -- wday 2 = Monday
        MySQL.insert("INSERT INTO bcc_leaderboard_history (player_id, player_displayName, playtime, leaderboard_type) " ..
                    "SELECT id, players_displayName, players_weeklyPlayTime, 'weekly' FROM bcc_player_connections WHERE players_weeklyPlayTime > 0")
        MySQL.update("UPDATE bcc_player_connections SET players_weeklyPlayTime = 0")
        print("Weekly playtime reset and snapshot completed.")
    end

        -- Monthly Reset on the First of the Month at Midnight
        if currentDate.day == 1 and currentDate.hour == 0 and currentDate.min == 0 then
        MySQL.insert("INSERT INTO bcc_leaderboard_history (player_id, player_displayName, playtime, leaderboard_type) " ..
                    "SELECT id, players_displayName, players_monthlyPlayTime, 'monthly' FROM bcc_player_connections WHERE players_monthlyPlayTime > 0")
        MySQL.update("UPDATE bcc_player_connections SET players_monthlyPlayTime = 0")
        print("Monthly playtime reset and snapshot completed.")
        end
    end
end)

-- Event triggered on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        devPrint("Resource " .. resourceName .. " started.")
        ReinitializePlayers()
    end
end)

-- Server: Event to handle fetching the full user list
RegisterNetEvent('bcc-userlog:fetchUsers')
AddEventHandler('bcc-userlog:fetchUsers', function()
    local source = source
    devPrint("Received fetchUsers request from player: " .. source)

    MySQL.query('SELECT id, players_displayName AS name FROM bcc_player_connections', {}, function(users)
        if users and #users > 0 then
            -- Send user list back to the client once
            TriggerClientEvent('bcc-userlog:sendUserList', source, users)
            devPrint("Sent user list to client for player: " .. source)
        else
            devPrint("No users found in the database.")
            TriggerClientEvent('bcc-userlog:sendUserList', source, {}) -- Send empty list if no users found
        end
    end)
end)

RegisterNetEvent('bcc-userlog:fetchUserDetails')
AddEventHandler('bcc-userlog:fetchUserDetails', function(userID)
    local source = source

    -- Fetch user details from the database
    MySQL.query('SELECT * FROM bcc_player_connections WHERE id = ?', { userID }, function(results)
        if results and #results > 0 then
            local user = results[1]

            -- Format dates on the server
            user.formattedLastConnection = os.date('%Y-%m-%d %H:%M:%S', user.players_tsLastConnection or 0)
            user.formattedJoined = os.date('%Y-%m-%d %H:%M:%S', user.players_tsJoined or 0)
            
            -- Add 'steam:' prefix to steam_id when querying characters table
            local steamIdentifier = 'steam:' .. user.steam_id

            -- Fetch character details from the characters table based on the prefixed steam identifier
            MySQL.query('SELECT * FROM characters WHERE identifier = ?', { steamIdentifier }, function(characterResults)
                if characterResults and #characterResults > 0 then
                    local character = characterResults[1]

                    -- Include character information with user details
                    user.characterDetails = {
                        charIdentifier = character.charidentifier,
                        steamName = character.steamname,
                        group = character.group,
                        money = character.money,
                        gold = character.gold,
                        job = character.job,
                        jobLabel = character.joblabel,
                        firstname = character.firstname,
                        lastname = character.lastname,
                        age = character.age,
                        gender = character.gender,
                        xp = character.xp,
                        health = {
                            outer = character.healthouter,
                            inner = character.healthinner
                        },
                        stamina = {
                            outer = character.staminaouter,
                            inner = character.staminainner
                        },
                        -- Add other fields as needed
                    }

                    -- Send the user and character details to the client
                    TriggerClientEvent('bcc-userlog:sendUserDetails', source, user)
                else
                    devPrint("Character not found in database for identifier: " .. steamIdentifier)
                end
            end)
        else
            devPrint("User not found in database.")
        end
    end)
end)

AddEventHandler('chatMessage', function(source, author, message)
    -- Check if the message is a command (starting with /)
    if message:sub(1, 1) == "/" then
        local command = message:sub(2) -- Get the command without the "/"
        local playerName = GetPlayerName(source) or "Unknown"
        local logMessage = ("💬 Command Used: **/%s** by **%s**"):format(command, playerName)

        -- Log the command to console for debugging
        devPrint(logMessage)

        -- Send the command log to Discord
        discordWebhook:sendMessage(logMessage)
    end
end)

RegisterServerEvent("bcc-userlog:AdminCheck", function()
    local _source, admin = source, false
    local character = Core.getUser(_source).getUsedCharacter
    if character.group == Config.adminGroup then
      TriggerClientEvent("bcc-userlog:AdminClientCheck", _source, true)
    end
  end)

--This is a TO DO
-- Log aiming at another player
--[[RegisterServerEvent('bcc-userlog:aimlogs')
AddEventHandler('bcc-userlog:aimlogs', function(pedId)
    -- Get player details
    local playerName = GetPlayerName(source)
    local playerId = source
    local playerCharacter = Core.getUser(playerId).getUsedCharacter
    local playerCharacterId = playerCharacter and playerCharacter.charIdentifier or "Unknown"
    local playerFirstName = playerCharacter and playerCharacter.firstname or "Unknown"
    local playerLastName = playerCharacter and playerCharacter.lastname or "Unknown"

    -- Get target details
    local targetName = GetPlayerName(pedId) or "Unknown"
    local targetCharacter = Core.getUser(pedId).getUsedCharacter
    local targetCharacterId = targetCharacter and targetCharacter.charIdentifier or "Unknown"
    local targetFirstName = targetCharacter and targetCharacter.firstname or "Unknown"
    local targetLastName = targetCharacter and targetCharacter.lastname or "Unknown"

    -- Log message with character IDs and names
    local logMessage = ("🎯 **Aim Logs**\nPlayer: %s `[ID: %s, Character ID: %s, Name: %s %s]`\nIs aiming at: %s `[ID: %s, Character ID: %s, Name: %s %s]`")
        :format(playerName, playerId, playerCharacterId, playerFirstName, playerLastName, targetName, pedId, targetCharacterId, targetFirstName, targetLastName)

    -- Send message to Discord
    discordWebhook:sendMessage(logMessage)
end)

-- Log player kills
RegisterServerEvent('bcc-userlog:killlogs')
AddEventHandler('bcc-userlog:killlogs', function(message, weapon)
    local time = os.date('*t')
    local hour = (time.hour - 2) % 24  -- Adjust for time zone if needed
    local minute = time.min

    local logMessage = ("💀 **Kill Logs**\n%s\nWeapon: %s\nTime: %02d:%02d"):format(message, weapon, hour, minute)
    discordWebhook:sendMessage(logMessage)
end)

-- Define the server event to log NPC aim actions
RegisterServerEvent('bcc-logs:npcAimLogs')
AddEventHandler('bcc-logs:npcAimLogs', function(npcType, weaponName)
    local playerId = source  -- Player who is being aimed at
    local playerName = GetPlayerName(playerId) or "Unknown Player"

    -- Construct a log message
    local logMessage = string.format("🔫 NPC Aiming Log: %s was aimed at by %s with weapon: %s", playerName, npcType, weaponName)
    discordWebhook:sendMessage(logMessage)
end)]] --

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-userlog')
