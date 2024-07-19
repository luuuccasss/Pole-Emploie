fx_version 'cerulean'
game 'gta5'

author 'FrenchGuys'
description 'Pole Emploi FiveM'
version '1.0.0'

shared_script '@es_extended/imports.lua'

dependencies {
    'es_extended'
}

client_scripts {
    '@es_extended/locale.lua',  -- Si tu utilises ESX
    'RageUI/RMenu.lua',
    'RageUI/menu/RageUI.lua',
    'RageUI/menu/Menu.lua',
    'RageUI/menu/MenuController.lua',
    'RageUI/components/*.lua',
    'RageUI/menu/elements/*.lua',
    'RageUI/menu/items/*.lua',
    'client/main.lua',
    'client/miner.lua',
    'client/bucheron.lua',
    'client/livreur.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/miner_server.lua',
    'server/bucheron_server.lua',
    'server/livreur_server.lua'

}

lua54 'yes'

files {
    'stream/commonmenu.ytd'
}

escrow_ignore {
    "stream/*ytd"
}
