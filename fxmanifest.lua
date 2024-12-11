game 'rdr3'
fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'BLN Grenade'
description 'A grenade resource for RedM.'
authro 'BLN Studio <bln.tebex.io>'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'c/*.lua'
}

server_scripts {
    's/*.lua'
}