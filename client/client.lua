Core = exports.vorp_core:GetCore()
local FeatherMenu = exports["feather-menu"].initiate()

BCCUserLogMenu = FeatherMenu:RegisterMenu("bcc:bcc-userlog:mainmenu",
    {
        top = '3%',
        left = '3%',
        ['720width'] = '400px',
        ['1080width'] = '500px',
        ['2kwidth'] = '600px',
        ['4kwidth'] = '800px',
        style = {},
        contentslot = {
            style = {
                ['height'] = '350px',
                ['min-height'] = '250px'
            }
        },
        draggable = true,
        canclose = true
    },
    {
        opened = function()
            DisplayRadar(false)
        end,
        closed = function()
            DisplayRadar(true)
        end
    }
)

local AdminAllowed, userListRequested, currentUsersList = false, false, {}

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    TriggerServerEvent('bcc-userlog:AdminCheck')
end)

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(1000)
    end
    devPrint("Player fully loaded, triggering server event.")
    TriggerServerEvent('playerFullyLoaded')

    if Config.devMode then
        TriggerServerEvent('bcc-userlog:AdminCheck')
    end
end)

RegisterNetEvent('bcc-userlog:sendUserList')
AddEventHandler('bcc-userlog:sendUserList', function(users)
    devPrint("Received user list from server.")
    currentUsersList = users
    openUserLogMenu()
    userListRequested = false -- Reset flag after receiving the user list
end)

RegisterNetEvent('bcc-userlog:sendUserDetails')
AddEventHandler('bcc-userlog:sendUserDetails', function(userDetails)
    devPrint("Received user details for user: " .. (userDetails.players_displayName or _U("unknown_user")))
    openUserDetailsMenu(userDetails) -- Open detailed view with the received data
end)

RegisterNetEvent('bcc-userlog:AdminClientCheck')
AddEventHandler('bcc-userlog:AdminClientCheck', function(isAdmin)
    AdminAllowed = isAdmin
    devPrint("AdminAllowed set to: " .. tostring(AdminAllowed))
end)

RegisterCommand(Config.AdminManagementMenuCommand, function()
    devPrint("AdminAllowed: " .. tostring(AdminAllowed))
    devPrint("userListRequested: " .. tostring(userListRequested))

    if AdminAllowed then
        if not userListRequested then
            devPrint("Requesting user list from server...")
            userListRequested = true
            TriggerServerEvent('bcc-userlog:fetchUsers')
        else
            devPrint("Opening user log menu directly.")
            openUserLogMenu()
        end
    else
        devPrint("User does not have admin permissions.")
    end
end)

function formatPlaytime(playTimeMinutes)
    local days = math.floor(playTimeMinutes / 1440)
    local remainingMinutesAfterDays = playTimeMinutes % 1440
    local hours = math.floor(remainingMinutesAfterDays / 60)
    local minutes = remainingMinutesAfterDays % 60
    return string.format("%d" .. _U("totalDays") .. "%d" .. _U("totalHours") .. "%d" .. _U("totalMintutes"), days, hours, minutes)
end

function openUserLogMenu()
    devPrint("Opening user log main menu.")

    local userLogMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:MainPage")

    -- Set up header
    userLogMenu:RegisterElement('header', {
        value = _U("user_log_system"),
        slot = 'header',
        style = {}
    })

    userLogMenu:RegisterElement('line', {
        style = {},
        slot = 'header'
    })
    
    -- Button to open Player List
    userLogMenu:RegisterElement('button', {
        label = _U('playerList'),
        style = {},
    }, function()
        openPlayerListMenu() -- Opens the player list menu
    end)

    -- Footer instructions
    userLogMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    TextDisplay = userLogMenu:RegisterElement('textdisplay', {
        value = _U('selectAnOption'),
        style = { fontSize = '20px', textAlign = 'center', padding = '10px' },
        slot = "footer"
    })

    devPrint("Opening user log main menu.")
    BCCUserLogMenu:Open({ startupPage = userLogMenu })
end

-- Function to open the Player List menu
function openPlayerListMenu()
    devPrint("Opening player list menu.")

    local playerListMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:PlayerListPage")

    -- Header for Player List
    playerListMenu:RegisterElement('header', {
        value = _U('playerList'),
        slot = 'header',
        style = { fontSize = '24px', textAlign = 'center', color = '#FFD700' }
    })

    playerListMenu:RegisterElement('line', {
        style = {},
        slot = 'header'
    })

    -- Add each player in the list
    if #currentUsersList > 0 then
        for _, user in ipairs(currentUsersList) do
            local userName = user.name or _U("unknown_user")
            local userID = user.id or _U("na")

            playerListMenu:RegisterElement('button', {
                label = userName,
                style = {},
            }, function()
                devPrint("Fetching details for user ID: " .. userID)
                TriggerServerEvent('bcc-userlog:fetchUserDetails', userID)
            end)
        end
    else
        playerListMenu:RegisterElement('textdisplay', {
            value = _U('noUsersAvailable'),
            style = { fontSize = '18px', textAlign = 'center', padding = '10px' }
        })
    end

    -- Footer instructions
    playerListMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    TextDisplay = playerListMenu:RegisterElement('textdisplay', {
        value = _U('selectAPlayer'),
        style = { fontSize = '20px', textAlign = 'center', padding = '10px' },
        slot = "footer"
    })

    devPrint("Opening player list menu.")
    BCCUserLogMenu:Open({ startupPage = playerListMenu })
end

-- Function to open the Leaderboard History menu
function openLeaderboardHistoryMenu()
    devPrint("Opening leaderboard history menu.")

    -- Register and configure the leaderboard history page
    local leaderboardHistoryMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:LeaderboardHistoryPage")

    -- Register Header Element
    leaderboardHistoryMenu:RegisterElement('header', {
        value = _U('leaderboardHistory'),
        slot = 'header',
        style = {
            fontSize = '24px',
            textAlign = 'center',
            color = '#FFD700',
            padding = '10px'
        }
    })

    -- Daily leaderboard button
    leaderboardHistoryMenu:RegisterElement('button', {
        label = _U('yesterdayHistory'),
        style = {}
    }, function()
        devPrint("Daily history button clicked.")
        TriggerServerEvent('bcc-userlog:fetchLeaderboardHistory', "daily")
    end)

    -- Weekly leaderboard button
    leaderboardHistoryMenu:RegisterElement('button', {
        label = _U('weeklyHistory'),
        style = {}
    }, function()
        devPrint("Weekly history button clicked.")
        TriggerServerEvent('bcc-userlog:fetchLeaderboardHistory', "weekly")
    end)

    -- Monthly leaderboard button
    leaderboardHistoryMenu:RegisterElement('button', {
        label = _U('monthlyHistory'),
        style = {}
    }, function()
        devPrint("Monthly history button clicked.")
        TriggerServerEvent('bcc-userlog:fetchLeaderboardHistory', "monthly")
    end)

    -- Footer elements
    leaderboardHistoryMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    leaderboardHistoryMenu:RegisterElement('button', {
        label = _U("backToLeaderboard"),
        slot = "footer",
        style = {}
    }, function()
        devPrint("Back to leaderboard button clicked.")
        TriggerEvent('bcc-userlog:openMainLeaderboardMenu')
    end)

    leaderboardHistoryMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    -- Open the menu
    devPrint("Opening leaderboard history menu interface.")
    BCCUserLogMenu:Open({ startupPage = leaderboardHistoryMenu })
end

RegisterNetEvent('bcc-userlog:displayLeaderboardHistory', function(leaderboardData, title)
    local leaderboardMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:LeaderboardHistoryPage")

    -- Set the header/title for the menu
    leaderboardMenu:RegisterElement('header', {
        value = title or _U("leaderboard_history"),
        slot = 'header',
        style = { fontSize = '24px', textAlign = 'center', color = '#FFD700' }
    })

    -- Define HTML content for the leaderboard history
    local leaderboardHTML = [[
    <div style="padding: 40px;">
        <table style="width: 100%; border-collapse: collapse;">
            <tr style="text-align: left;">
                <th style="padding: 10px; color: #FFD700;">]] .. _U("rank") .. [[</th>
                <th style="padding: 10px; color: #FFD700;">]] .. _U("player") .. [[</th>
                <th style="padding: 10px; text-align: right; color: #FFD700;">]] .. _U("playtime") .. [[</th>
            </tr>
    ]]

    if leaderboardData and #leaderboardData > 0 then
        for i, player in ipairs(leaderboardData) do
            local playerName = player.player_displayName or _U("unknown_user")
            local playtime = tonumber(player.playtime) or 0

            -- Format playtime as hours, minutes, and seconds
            local hours = math.floor(playtime / 3600)
            local minutes = math.floor((playtime % 3600) / 60)
            local seconds = playtime % 60
            local formattedPlaytime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            -- Alternate row colors with opacity
            local rowColor = i % 2 == 0 and "rgba(249, 249, 249, 0.3)" or "rgba(239, 239, 239, 0.3)"

            -- Add each player's row to the table
            leaderboardHTML = leaderboardHTML .. string.format([[<tr style="background-color: %s;">
                <td style="padding: 8px;">%d</td>
                <td style="padding: 8px;">%s</td>
                <td style="padding: 8px; text-align: right;">%s</td>
            </tr>]], rowColor, i, playerName, formattedPlaytime)
        end
    else
        leaderboardHTML = leaderboardHTML .. [[
        <tr>
            <td colspan="3" style="padding: 10px; text-align: center; color: #999;">]] .. _U("no_data_available") .. [[</td>
        </tr>
    ]]
    end

    -- Close the table and div
    leaderboardHTML = leaderboardHTML .. "</table></div>"

    -- Register HTML content in Feather Menu
    leaderboardMenu:RegisterElement("html", {
        value = { leaderboardHTML },
        slot = 'content',
        style = { padding = '10px' }
    })

    -- Add footer elements
    leaderboardMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    -- Register the "Back to Main Menu" button
    leaderboardMenu:RegisterElement('button', {
        label = _U("backToLeaderboard"),
        slot = "footer",
        style = {}
    }, function()
        openLeaderboardHistoryMenu()
    end)

    leaderboardMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    leaderboardMenu:RegisterElement('textdisplay', {
        value = _U("additionalInfo"),
        style = { fontSize = '20px', textAlign = 'center', padding = '10px' },
        slot = "footer"
    })

    -- Open the leaderboard history menu
    BCCUserLogMenu:Open({ startupPage = leaderboardMenu })
end)

function openUserDetailsMenu(user)
    devPrint("User object received: " .. json.encode(user))
    local formattedPlaytime = formatPlaytime(user.players_playTime or 0)
    local htmlContent = string.format([[
        <div style="padding: 20px; margin: 0 auto;">
            <div style="display: flex; align-items: center; gap: 15px; padding-bottom: 15px; border-bottom: 2px solid #8B4513;">
                <div style="flex-grow: 1; color: #4E342E;">
                    <p style="font-size: 22px; margin: 5px 0; color: #8B4513;"><strong>%s</strong></p>
                    <p style="font-size: 16px; margin: 3px 0;"><strong style="color: #B22222;">%s:</strong> %s</p>
                    <p style="font-size: 16px; margin: 3px 0;"><strong style="color: #FFD700;">%s:</strong> %s</p>
                    <p style="font-size: 16px; margin: 3px 0;"><strong style="color: #228B22;">%s:</strong> %s</p>
                    <p style="font-size: 16px; margin: 3px 0;"><strong style="color: #8B4513;">%s:</strong> %s</p>
                    <p style="font-size: 16px; margin: 3px 0;"><strong style="color: #556B2F;">%s:</strong> $%s</p>
                    <p style="font-size: 16px; margin: 3px 0;"><strong style="color: #FFD700;">%s:</strong> %s</p>
                </div>
            </div>
            <div style="padding-top: 15px;">
                <h3 style="font-size: 18px; color: #4B0082; text-transform: uppercase; font-weight: bold; border-bottom: 1px solid #8B4513; padding-bottom: 5px; margin-bottom: 10px;">%s</h3>
                <ul style="list-style: none; padding: 0; font-size: 16px; color: #4E342E; line-height: 1.6;">
                    <li><strong style="color: #DAA520;">%s:</strong> %s</li>
                    <li><strong style="color: #8B0000;">%s:</strong> %s</li>
                    <li><strong style="color: #8B0000;">%s:</strong> %s</li>
                    <li><strong style="color: #2F4F4F;">%s:</strong> %s</li>
                    <li><strong style="color: #556B2F;">%s:</strong> %s</li>
                    <li><strong style="color: #8B4513;">%s:</strong> %s</li>
                    <li><strong style="color: #4682B4;">%s:</strong> %s</li>
                </ul>
            </div>
        </div>
    ]],
        user.players_displayName or _U("unknown_user"),
        _U("playtime"), formattedPlaytime,
        _U("last_connection"), user.formattedLastConnection or _U("na"),
        _U("joined"), user.formattedJoined or _U("na"),
        _U("character_id"), user.characterDetails.charIdentifier or _U("na"),
        _U("money"), user.characterDetails.money or "0.00",
        _U("gold"), user.characterDetails.gold or "0.00",
        _U("identifiers"),
        _U("discord_id"), user.discord_id or _U("na"),
        _U("license"), user.license or _U("na"),
        _U("fivem_id"), user.fivem_id or _U("na"),
        _U("license2"), user.license2 or _U("na"),
        _U("steam_id"), user.steam_id or _U("na"),
        _U("live_id"), user.live_id or _U("na"),
        _U("xbl_id"), user.xbl_id or _U("na")
    )

    local detailsMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:DetailsPage")

    detailsMenu:RegisterElement('header', {
        value = _U("user_details"),
        slot = 'header',
        style = {}
    })

    detailsMenu:RegisterElement("html", {
        value = { htmlContent },
        slot = 'content',
        style = {}
    })

    detailsMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    detailsMenu:RegisterElement('button', {
        label = _U("back_to_users"),
        slot = "footer",
        style = {}
    }, function()
        devPrint("Returning to main user log menu.")
        openUserLogMenu()
    end)

    detailsMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    TextDisplay = detailsMenu:RegisterElement('textdisplay', {
        value = _U('detailed_user_information'),
        style = { fontSize = '20px', textAlign = 'center', padding = '10px' },
        slot = "footer"
    })

    devPrint("Opening details menu for user: " .. (user.players_displayName or _U("unknown_user")))
    BCCUserLogMenu:Open({ startupPage = detailsMenu })
end
RegisterNetEvent('bcc-userlog:displayLeaderboard')
AddEventHandler('bcc-userlog:displayLeaderboard', function(leaderboardData, leaderboardTitle)
    displayLeaderboardMenu(leaderboardData, leaderboardTitle)
end)

RegisterNetEvent('bcc-userlog:openMainLeaderboardMenu')
AddEventHandler('bcc-userlog:openMainLeaderboardMenu', function()
    local mainLeaderboardMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:LeaderbordMainPage")

    -- Set the header/title for the menu
    mainLeaderboardMenu:RegisterElement('header', {
        value = _U("selectLeaderboardType"),
        slot = 'header',
        style = { fontSize = '24px', textAlign = 'center', color = '#FFD700' }
    })

    -- Daily leaderboard button
    mainLeaderboardMenu:RegisterElement('button', {
        label = _U("dailyLeaderboard"),
        style = {}
    }, function()
        TriggerServerEvent('bcc-userlog:requestLeaderboardData', "daily")
    end)

    -- Weekly leaderboard button
    mainLeaderboardMenu:RegisterElement('button', {
        label = _U("weeklyLeaderboard"),
        style = {}
    }, function()
        TriggerServerEvent('bcc-userlog:requestLeaderboardData', "weekly")
    end)

    -- Monthly leaderboard button
    mainLeaderboardMenu:RegisterElement('button', {
        label = _U("monthlyLeaderboard"),
        style = {}
    }, function()
        TriggerServerEvent('bcc-userlog:requestLeaderboardData', "monthly")
    end)

    mainLeaderboardMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    -- Button to open Leaderboard History
    mainLeaderboardMenu:RegisterElement('button', {
        label = _U('leaderboardHistory'),
        slot = "footer",
        style = {},
    }, function()
        openLeaderboardHistoryMenu() -- Opens the leaderboard history menu
    end)

    mainLeaderboardMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    -- Open the main leaderboard menu
    BCCUserLogMenu:Open({ startupPage = mainLeaderboardMenu })
end)

function displayLeaderboardMenu(leaderboardData, leaderboardTitle)
    local leaderboardMenu = BCCUserLogMenu:RegisterPage("bcc-userlog:leaderBoardMenu")

    -- Set the header/title for the menu
    leaderboardMenu:RegisterElement('header', {
        value = leaderboardTitle,
        slot = 'header',
        style = { fontSize = '24px', textAlign = 'center', color = '#FFD700' }
    })

    -- Define HTML content for the leaderboard
    local leaderboardHTML = [[
    <div style="padding: 40px;">
        <table style="width: 100%; border-collapse: collapse;">
            <tr style="text-align: left;">
                <th style="padding: 10px; color: #FFD700;">]] .. _U("rank") .. [[</th>
                <th style="padding: 10px; color: #FFD700;">]] .. _U("player") .. [[</th>
                <th style="padding: 10px; text-align: right; color: #FFD700;">]] .. _U("playtime") .. [[</th>
            </tr>
    ]]

    if #leaderboardData > 0 then
        for i, player in ipairs(leaderboardData) do
            local playerName = player.players_displayName or _U("unknown_user")
            local playTime = player.players_dailyPlayTime or player.players_weeklyPlayTime or player.players_monthlyPlayTime or 0

            -- Format playtime as hours, minutes, and seconds
            local hours = math.floor(playTime / 3600)
            local minutes = math.floor((playTime % 3600) / 60)
            local seconds = playTime % 60
            local formattedPlayTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            -- Alternate row colors with opacity
            local rowColor = i % 2 == 0 and "rgba(249, 249, 249, 0.3)" or "rgba(239, 239, 239, 0.3)"

            -- Add each player's row to the table
            leaderboardHTML = leaderboardHTML .. string.format([[<tr style="background-color: %s;">
                <td style="padding: 8px;">%d</td>
                <td style="padding: 8px;">%s</td>
                <td style="padding: 8px; text-align: right;">%s</td>
            </tr>]], rowColor, i, playerName, formattedPlayTime)
        end
    else
        leaderboardHTML = leaderboardHTML .. [[
        <tr>
            <td colspan="3" style="padding: 10px; text-align: center; color: #999;">]] .. _U("no_data_available") .. [[</td>
        </tr>
    ]]
    end

    -- Close the table and div
    leaderboardHTML = leaderboardHTML .. "</table></div>"

    -- Register HTML content in Feather Menu
    leaderboardMenu:RegisterElement("html", {
        value = { leaderboardHTML },
        slot = 'content',
        style = { padding = '10px' }
    })
    leaderboardMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    leaderboardMenu:RegisterElement('button', {
        label = _U("backToLeaderboard"),
        slot = "footer",
        style = {}
    }, function()
        TriggerEvent('bcc-userlog:openMainLeaderboardMenu')
    end)

    leaderboardMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    TextDisplay = leaderboardMenu:RegisterElement('textdisplay', {
        value = _U("additionalInfo"),
        style = { fontSize = '20px', textAlign = 'center', padding = '10px' },
        slot = "footer"
    })

    -- Open the leaderboard menu
    BCCUserLogMenu:Open({ startupPage = leaderboardMenu })
end
--- Cleanup/ deletion on leave ----
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        BCCUserLogMenu:Close()
    end
end)