-- bcc-userlog API

UserLogAPI = {}
exports("getUserLogAPI", function()
    return UserLogAPI
end)

-- Core Player Info Queries

function UserLogAPI:GetTotalPlaytime(license)
    local result = MySQL.query.await("SELECT players_playTime FROM bcc_player_connections WHERE license = ?", { license })
    return result and result[1] and result[1].players_playTime or 0
end

function UserLogAPI:GetLastSessionTime(license)
    local result = MySQL.query.await("SELECT players_lastSessionTime FROM bcc_player_connections WHERE license = ?", { license })
    return result and result[1] and result[1].players_lastSessionTime or 0
end

function UserLogAPI:GetDailyPlaytime(license)
    local result = MySQL.query.await("SELECT players_dailyPlayTime FROM bcc_player_connections WHERE license = ?", { license })
    return result and result[1] and result[1].players_dailyPlayTime or 0
end

function UserLogAPI:GetWeeklyPlaytime(license)
    local result = MySQL.query.await("SELECT players_weeklyPlayTime FROM bcc_player_connections WHERE license = ?", { license })
    return result and result[1] and result[1].players_weeklyPlayTime or 0
end

function UserLogAPI:GetMonthlyPlaytime(license)
    local result = MySQL.query.await("SELECT players_monthlyPlayTime FROM bcc_player_connections WHERE license = ?", { license })
    return result and result[1] and result[1].players_monthlyPlayTime or 0
end

-- List & Search

function UserLogAPI:GetAllUsers()
    return MySQL.query.await("SELECT id, players_displayName FROM bcc_player_connections")
end

function UserLogAPI:SearchUsersByName(partialName)
    return MySQL.query.await("SELECT id, players_displayName FROM bcc_player_connections WHERE players_displayName LIKE ?", { "%" .. partialName .. "%" })
end

-- Player Details

function UserLogAPI:GetUserDetailsById(userID)
    local userResult = MySQL.query.await("SELECT * FROM bcc_player_connections WHERE id = ?", { userID })
    if not userResult or #userResult == 0 then return nil end

    local user = userResult[1]
    user.formattedLastConnection = os.date('%Y-%m-%d %H:%M:%S', user.players_tsLastConnection or 0)
    user.formattedJoined = os.date('%Y-%m-%d %H:%M:%S', user.players_tsJoined or 0)

    local steamIdentifier = 'steam:' .. (user.steam_id or "")
    local characterResult = MySQL.query.await("SELECT * FROM characters WHERE identifier = ?", { steamIdentifier })

    if characterResult and #characterResult > 0 then
        local character = characterResult[1]
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
            }
        }
    end

    return user
end

function UserLogAPI:GetUserBySteamID(steamID)
    -- Automatically strip "steam:" prefix if included
    if steamID:sub(1, 6) == "steam:" then
        steamID = steamID:sub(7)
    end

    local result = MySQL.query.await("SELECT * FROM bcc_player_connections WHERE steam_id = ?", { steamID })
    return result and result[1] or nil
end

function UserLogAPI:GetPlayerIdentifiers(userID)
    local result = MySQL.query.await("SELECT license, steam_id, discord_id, fivem_id, license2 FROM bcc_player_connections WHERE id = ?", { userID })
    return result and result[1] or nil
end

-- Leaderboards

function UserLogAPI:GetLeaderboardData(type)
    local validTypes = {
        daily = "players_dailyPlayTime",
        weekly = "players_weeklyPlayTime",
        monthly = "players_monthlyPlayTime"
    }
    local column = validTypes[type]
    if not column then return {} end

    local query = string.format("SELECT players_displayName, %s AS playtime FROM bcc_player_connections ORDER BY %s DESC LIMIT 30", column, column)
    return MySQL.query.await(query)
end

function UserLogAPI:GetTopTotalPlaytime()
    return MySQL.query.await("SELECT players_displayName, players_playTime FROM bcc_player_connections ORDER BY players_playTime DESC LIMIT 1")
end

function UserLogAPI:GetLeaderboardHistory(type)
    local validTypes = {
        daily = "daily",
        weekly = "weekly",
        monthly = "monthly"
    }
    local lbType = validTypes[type]
    if not lbType then return {} end

    return MySQL.query.await(
        [[SELECT player_displayName, playtime, recorded_at 
           FROM bcc_leaderboard_history 
           WHERE leaderboard_type = ? 
           ORDER BY recorded_at DESC, playtime DESC 
           LIMIT 30]],
        { lbType }
    )
end

function UserLogAPI:GetLeaderboardByDate(type, date)
    return MySQL.query.await(
        [[SELECT player_displayName, playtime 
          FROM bcc_leaderboard_history 
          WHERE leaderboard_type = ? AND DATE(recorded_at) = ? 
          ORDER BY playtime DESC]],
        { type, date }
    )
end

-- Utility

function UserLogAPI:GetRecentConnections(limit)
    limit = limit or 10
    return MySQL.query.await("SELECT players_displayName, players_tsLastConnection FROM bcc_player_connections ORDER BY players_tsLastConnection DESC LIMIT ?", { limit })
end

function UserLogAPI:GetTotalPlayerCount()
    local result = MySQL.query.await("SELECT COUNT(*) as total FROM bcc_player_connections")
    return result and result[1] and result[1].total or 0
end
