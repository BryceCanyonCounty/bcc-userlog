-- Cache player names every second
names = {}
CreateThread(function()
    while true do
        Wait(1000)
        for k, v in pairs(GetPlayers()) do
            names[v] = GetPlayerName(v)
        end
    end
end)

-- Scheduled restart event
AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    local message = ("⏰ The server will restart in %s"):format(SecondsToClock(data.secondsRemaining))
    discordWebhook:sendMessage(message)
end)

-- Skipped scheduled restart event
AddEventHandler('txAdmin:events:skippedNextScheduledRestart', function()
    local message = "⚠️ The server skipped the scheduled restart."
    discordWebhook:sendMessage(message)
end)

-- Player kicked event
AddEventHandler('txAdmin:events:playerKicked', function(data)
    local message = ("🚫 **%s** kicked **%s**\n📝 Reason: `%s`"):format(data.author, names[data.target] or "Unknown", data.reason)
    discordWebhook:sendMessage(message)
end)

-- Player warned event
AddEventHandler('txAdmin:events:playerWarned', function(data)
    local message = ("⚠️ **%s** warned **%s**\n🔹 Action ID: `%s`\n📝 Reason: `%s`"):format(data.author, GetPlayerName(data.target) or "Unknown", data.actionId, data.reason)
    discordWebhook:sendMessage(message)
end)

-- Player banned event
AddEventHandler('txAdmin:events:playerBanned', function(data)
    local expiration = data.expiration == false and "Permanent" or data.expiration
    local message = ("⛔ **%s** banned **%s**\n🔹 Action ID: `%s`\n📝 Reason: `%s`\n🕒 Expiration: `%s`"):format(data.author, names[data.target] or "Unknown", data.actionId, data.reason, expiration)
    discordWebhook:sendMessage(message)
end)

-- Player whitelisted event
AddEventHandler('txAdmin:events:playerWhitelisted', function(data)
    local message = ("✅ **%s** whitelisted `%s`\n🔹 Action ID: `%s`"):format(data.author, data.target, data.actionId)
    discordWebhook:sendMessage(message)
end)

-- Config changed event
AddEventHandler('txAdmin:event:configChanged', function()
    local message = "⚙️ The `server.cfg` file has been updated."
    discordWebhook:sendMessage(message)
end)

-- Healed player event
AddEventHandler('txAdmin:events:healedPlayer', function(data)
    local message
    if data.id == -1 then
        message = "🌍 The whole server was healed"
    else
        local playerName = GetPlayerName(data.id) or "Unknown Player"
        message = "💉 " .. playerName .. " was healed by `txAdmin`"
    end
    discordWebhook:sendMessage(message)
end)

-- Announcement event
AddEventHandler('txAdmin:events:announcement', function(data)
    local message = ("📢 **%s** created an announcement:\n`%s`"):format(data.author, data.message)
    discordWebhook:sendMessage(message)
end)

-- Server shutting down event
AddEventHandler('txAdmin:events:serverShuttingDown', function(data)
    local message = ("🔌 Server will shut down in `%s`\n🔹 Requested by: `%s`\n📜 Message: `%s`"):format(SecondsToClock(data.delay / 1000), data.author, data.message)
    discordWebhook:sendMessage(message)
end)

-- Utility function to format seconds into minutes and seconds
function SecondsToClock(sec)
    local minutes = math.floor(sec / 60)
    local seconds = sec - minutes * 60
    if minutes == 0 then
        return string.format("%d seconds", seconds)
    else
        return string.format("%d minutes, %d seconds", minutes, seconds)
    end
end
