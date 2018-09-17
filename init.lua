dofile("secrets.lua")
dofile("spi-lights.lua")
dofile("animations.lua")
dofile("messages.lua")

local wifi_conf = {}
wifi_conf.ssid = WIFI_SSID
wifi_conf.pwd =  WIFI_PASSWORD
if string.len(wifi_conf.ssid) > 0 then -- connect to wifi, if configured
    wifi.setmode(wifi.STATION)
    wifi.sta.config(wifi_conf)
end

setupController()      -- init SPI
animateLightsOpt()     -- animate the lights to show we're alive

if string.len(MESSAGE_SERVER_URL) > 0 then
    checkForMessagesSoon() -- start looking for messages from the server, if configured
end
