fx_version 'adamant'

game 'gta5'

version "1.02"

dependencies {
    '/server:4752',
}

server_scripts {
    'globals/server_global_*.lua'
}

client_scripts {
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
