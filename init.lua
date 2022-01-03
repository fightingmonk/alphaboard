dofile("secrets.lua")
dofile("spi-lights.lua")
dofile("animations.lua")
dofile("messages.lua")

print("OHAI")

local wifi_conf = {}
wifi_conf.ssid = WIFI_SSID
wifi_conf.pwd =  WIFI_PASSWORD
if string.len(wifi_conf.ssid) > 0 then -- connect to wifi, if configured
    print(string.format("Connecting to WIFI ssid '%s'", wifi_conf.ssid))
    wifi.setmode(wifi.STATION)
    wifi.sta.config(wifi_conf)
end

setupController()      -- init SPI

animateLightsLinear()  -- animate the lights to show we're alive

if string.len(MESSAGE_SERVER_URL) > 0 then
    connectToMessageServer() -- start looking for messages from the server, if configured
end
