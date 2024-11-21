# bcc-userlog

> This script provides an in-depth and immersive user logging system for tracking player activity! With features like total playtime tracking, session times, leaderboards, and more, this script offers a quality experience for both players and administrators.

## Features

- **Playtime Tracking**: Accurately tracks total playtime and session durations for each player.
- **Leaderboards**: Provides daily, weekly, and monthly leaderboards to showcase the most active players.
- **Automatic Resets**: Leaderboards reset automatically at the end of each day, week, and month.
- **Historical Data**: Stores historical leaderboard data for administrative review.
- **Player Commands**:
  - `/ore` – Shows your total accumulated playtime.
  - `/ultimasesiune` – Displays details about your last game session.
  - `/clasament` – Opens the leaderboard menu to view top players.
- **Admin Commands**:
  - `/userlog` – Opens the user log system with detailed player information (admin access only).
- **Player Details**: Administrators can view detailed information about players, including identifiers, playtime, and account status.
- **Localization**: Easy to translate with support for multiple languages (English and Romanian included).
- **Discord Integration**: In-depth webhooks for player connection and disconnection notifications.
- **Version Checking**: Helps you keep the script up to date with automatic version checks.

## How It Works

- **Playtime Accumulation**: The script tracks when players connect and disconnect, calculating their session durations and adding them to their total playtime.
- **Leaderboards**: Players' playtimes are compiled into daily, weekly, and monthly leaderboards, which reset automatically at specified intervals.
- **Data Storage**: All player data and leaderboard histories are stored in the database, ensuring persistence and accuracy.
- **Admin Interface**: Administrators can access a dedicated menu to view player logs and leaderboard histories, manage player data, and more.
- **Player Interaction**: Players can use in-game commands to check their own playtime stats and view leaderboards to see how they rank among others.

## How to Install

1. **Download and Install Dependencies**: Ensure all required scripts and dependencies are installed and running.
2. **Add the Script**: Place the `bcc-userlog` script into your server's resources folder.
3. **Configure the Script**:
   - Edit the `config.lua` file to adjust settings such as command names, permissions, and other options.
   - Customize localization files if needed.
4. **Start the Script**:
   - Add `ensure bcc-userlog` to your server configuration file (`server.cfg`).
5. **Database Setup**:
   - The script will automatically create the necessary database tables upon first launch.
   - If required, run any provided SQL files to set up the database schema.
6. **Restart the Server**: Restart your server to load the new script and apply all changes.

## Commands

- **Player Commands**:
  - `/playtime` – Displays your total playtime on the server.
  - `/lastsession` – Shows information about your last game session, including duration.
  - `/leaderboard` – Opens the leaderboard menu to view daily, weekly, and monthly top players.
- **Admin Commands** (restricted to authorized staff):
  - `/userlog` – Accesses the user log system with detailed player information and leaderboard history.

## Requirements

- vorp_core
- vorp_character
- feather-menu
- bcc-utils
- MySQL database

## Side Notes

- **Feedback and Support**: This is a comprehensive project, and we welcome any suggestions or bug reports. Please share your feedback to help us improve!
- **Leaderboard History**: Currently, only administrators can view the leaderboard history to monitor player activity over time.
- **Data Privacy**: Ensure you handle player data responsibly and comply with any applicable privacy regulations.
- **Customization**: The script is designed to be easily customizable and translatable. Adjust settings and localization files to fit your server's needs.
- **Join Our Community**: Need assistance or want to stay updated? Join the BCC Discord community: [Discord Link](https://discord.gg/VrZEEpBgZJ)

---

Thank you for choosing `bcc-userlog`! We hope this script enhances your server's player engagement and management capabilities.
