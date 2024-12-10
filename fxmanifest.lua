fx_version 'adamant'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'BCC Scripts @iseeyoucopy'
description 'An in-depth and immersive user logging system for tracking player activity'

shared_scripts {
    'config.lua',
    'locale.lua',
    'languages/*.lua'

}
-- Define server and client scripts
client_scripts {
    'client/client.lua',
    --'client/clientAimandKill.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- oxmysql dependency
    'server/server.lua',
    'server/txAdminhandlers.lua'
    'server/dbUpdater.lua'
}

version '1.0.2'
