fx_version 'adamant'

game 'gta5'

version "1.0"

dependencies {
    '/server:4752',
}

shared_scripts {
    'CONFIG.lua',

    'api.lua',
    'utils.lua',
    'versionchecker.lua',
    'player.lua',
    'attachments.lua',
    'peds.lua',
    'nui.lua',
    'raycast.lua'
}

server_scripts {
    'modules/server.lua',

    'modules/helps/server.lua',
    'modules/newobject/server.lua',
    'modules/particle/server.lua',
    'modules/blips/server.lua',
    'modules/radarblips/server.lua',
    'modules/actionshape/server.lua',
    'modules/peds/server.lua',
    'modules/raycast/server.lua',

    -- This one should start the last.
    'main.lua',
}

client_scripts {
    'modules/client.lua',

    'modules/helps/client.lua',
    'modules/newobject/client.lua',
    'modules/particle/client.lua',
    'modules/blips/client.lua',
    'modules/radarblips/client.lua',
    'modules/actionshape/client.lua',
    'modules/peds/client.lua',
    'modules/raycast/client.lua',

    -- This one should start the last.
    'main.lua'
}

ui_page 'html/compiled/index.html'

files {
    'html/compiled/**',
}

-- av_resourcename "av_distillery"
