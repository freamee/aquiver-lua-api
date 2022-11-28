fx_version 'adamant'

game 'gta5'

version "1.0"

dependencies {
    '/server:4752',
}

server_scripts {
    'CONFIG.lua',

    -- This api should start first.
    'modules/server_api.lua',

    'modules/shared_api.lua',
    'modules/utils/shared.lua',
    'modules/attachments/shared.lua',

    'modules/utils/server.lua',
    'modules/helps/server.lua',

    'modules/newobject/server.lua',

    'modules/particle/server.lua',
    'modules/blips/server.lua',
    'modules/radarblips/server.lua',
    'modules/actionshape/server.lua',
    'modules/peds/server.lua',
    'modules/raycast/server.lua',
    'modules/player/server.lua',
    'modules/versionchecker/server.lua',

    -- This one should start the last.
    'modules/server_main.lua',

    'globals/server_global_*.lua'
}

client_scripts {
    'CONFIG.lua',

    -- This api should start first.
    'modules/client_api.lua',

    'modules/shared_api.lua',
    'modules/utils/shared.lua',
    'modules/attachments/shared.lua',

    'modules/utils/client.lua',
    'modules/helps/client.lua',

    'modules/newobject/client.lua',

    'modules/particle/client.lua',
    'modules/blips/client.lua',
    'modules/radarblips/client.lua',
    'modules/actionshape/client.lua',
    'modules/peds/client.lua',
    'modules/raycast/client.lua',
    'modules/player/client.lua',
    'modules/nui/client.lua',

    -- This one should start the last.
    'modules/client_main.lua',

    'globals/client_global_*.lua'
}

ui_page 'html/compiled/index.html'

files {
    'html/compiled/**',

    '_modules/config.lua',
    '_modules/client_*.lua',
    '_modules/shared_*.lua',
    '_modules/**/client.lua',
    '_modules/**/shared.lua'
}
