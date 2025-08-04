fx_version 'cerulean'
game 'gta5'

author 'Matias'
description 'Et simpelt hvidvask script med ox_lib, ox_target og ox_inventory'
version '1.0.0'

lua54 'yes'

client_scripts {
    'config.lua',
    'client.lua'
}
server_scripts {
    'config.lua',
}

shared_script '@ox_lib/init.lua'

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}