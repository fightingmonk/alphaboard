-- Set output state on 4 cascaded 74HC595s using the ESP8266's HSPI (hardware SPI bus id 1)
--
--    Connect Nodemcu D7 (GPIO13) to 74HC595 Data (pin 14)
--    Connect Nodemcu D5 (GPIO14) to 74HC595 Clock (pin 11)
--    Connect Nodemcu D8 (GPIO15) to 74HC595 Latch (pin 12)

-- NodeMCU's pin numbering differs from the pinout on the board ¯\_(ツ)_/¯
--     https://nodemcu.readthedocs.io/en/master/en/modules/gpio/

local bit = require("bit")
local LATCH_GPIO = 8

local CURRENT_OUTPUT_STATE = 0

-- initialize SPI, set our GPIO control pins to output mode, and zero out the attached shift registers
function setupController()
  spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_LOW, 32, 0)
  gpio.mode(LATCH_GPIO, gpio.OUTPUT)

  CURRENT_OUTPUT_STATE = 0
  updateOutputPins()
end


-- write 32 bits to the shift register chips via SPI
function updateOutputPins()
    gpio.write(LATCH_GPIO, gpio.LOW)
    tmr.delay(100)

    spi.send(1, CURRENT_OUTPUT_STATE)

    tmr.delay(100)
    gpio.write(LATCH_GPIO, gpio.HIGH)
end

-- turn on a single pin on a single 595, and turn off all other pins
function setLight(lightId)
    --CURRENT_OUTPUT_STATE = (lightId ~= 0) and bit.lshift(1, lightId - 1) or 0
    CURRENT_OUTPUT_STATE = (lightId ~= 0) and bit.set(0, lightId - 1) or 0

    updateOutputPins()
end

-- turn on a pin, leave all other pins as-is
function addLight(lightId)
    --CURRENT_OUTPUT_STATE = bit.bor(CURRENT_OUTPUT_STATE, (lightId ~= 0) and bit.lshift(1, lightId - 1) or 0)
    CURRENT_OUTPUT_STATE = (lightId ~= 0) and bit.set(CURRENT_OUTPUT_STATE, lightId - 1) or CURRENT_OUTPUT_STATE
    updateOutputPins()
end

-- turn off a pin, leave all other pins as-is
function removeLight(lightId)
    --CURRENT_OUTPUT_STATE = (lightId == 0) and CURRENT_OUTPUT_STATE or bit.band(CURRENT_OUTPUT_STATE, bit.bnot(bit.lshift(1, lightId - 1)))
    CURRENT_OUTPUT_STATE = (lightId == 0) and CURRENT_OUTPUT_STATE or bit.clear(CURRENT_OUTPUT_STATE, lightId - 1)
    updateOutputPins()
end

-- illuminates the light corresponding to the first character in the string `letter`
function displayLetter(letter)
    local asciiCode = string.byte(string.upper(letter))
    local asciiA = string.byte('A')
    local light = asciiCode - asciiA + 1
    if light < 1 or light > 26 then
        light = 0
    end

    setLight(light)
end
