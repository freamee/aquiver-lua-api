fx_version 'adamant'

game 'gta5'

version "1.0"

dependencies {
    '/server:4752',
}

shared_scripts {
    'api.lua',
    'utils.lua',
    'radarblips.lua',
    'blips.lua',
    'eventhandler.lua',
    'versionchecker.lua',
    'player.lua',
    'attachments.lua',
    'peds.lua',
    'nui.lua',

    -- This one should start the last.
    'main.lua'
}

ui_page 'html/compiled/index.html'

files {
    'html/compiled/**',
}

-- av_resourcename "av_distillery"
