CreateThread(function()
    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_leaderboard_history` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `player_id` int(11) DEFAULT NULL,
            `player_displayName` varchar(255) DEFAULT NULL,
            `playtime` int(11) DEFAULT NULL,
            `leaderboard_type` enum('daily','weekly','monthly') DEFAULT NULL,
            `recorded_at` timestamp NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_player_connections` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `license` varchar(255) DEFAULT NULL,
            `discord_id` varchar(255) DEFAULT NULL,
            `fivem_id` varchar(255) DEFAULT NULL,
            `license2` varchar(255) DEFAULT NULL,
            `steam_id` varchar(255) DEFAULT NULL,
            `live_id` varchar(255) DEFAULT NULL,
            `xbl_id` varchar(255) DEFAULT NULL,
            `players_displayName` varchar(255) DEFAULT NULL,
            `players_playTime` int(11) DEFAULT 0,
            `players_tsLastConnection` int(11) DEFAULT 0,
            `players_tsJoined` int(11) DEFAULT 0,
            `players_lastSessionTime` int(11) DEFAULT 0,
            `players_dailyPlayTime` int(11) DEFAULT 0,
            `players_weeklyPlayTime` int(11) DEFAULT 0,
            `players_monthlyPlayTime` int(11) DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE KEY `license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print("Database tables for \x1b[35m\x1b[1m*bcc-leaderboard*\x1b[0m and \x1b[35m\x1b[1m*bcc-player-connections*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
end)
