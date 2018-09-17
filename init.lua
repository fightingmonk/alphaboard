dofile("secrets.lua")
dofile("spi-lights.lua")
dofile("animations.lua")
dofile("messages.lua")

local wifi_conf = {}
wifi_conf.ssid = WIFI_SSID
wifi_conf.pwd =  WIFI_PASSWORD
wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_conf)

setupController()      -- init SPI
animateLightsOpt()     -- animate the lights to show we're alive
checkForMessagesSoon() -- start looking for messages from the server