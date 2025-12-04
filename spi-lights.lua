-- Set output state on 4 cascaded 74HC595s using the ESP8266's HSPI (hardware SPI bus id 1)
--
--    Connect Nodemcu D7 (GPIO13) to 74HC595 Data (pin 14)
--    Connect Nodemcu D5 (GPIO14) to 74HC595 Clock (pin 11)
--    Connect Nodemcu D8 (GPIO15) to 74HC595 Latch (pin 12)

-- NodeMCU's pin numbering differs from the pinout on the board ¯\_(ツ)_/¯
--     https://nodemcu.readthedocs.io/en/master/en/modules/gpio/

local bit = require("bit")
local LATCH_GPIO = 8
local DATA_BITS = 8 * 4 -- 8 * # of daisy-chained shift registers
local SPI_FREQUENCY_DIVIDER = 160 -- f(SPI) = 80 Mhz / SPI_FREQUENCY_DIVIDER

local CURRENT_OUTPUT_STATE = 0

-- initialize SPI, set our GPIO control pins to output mode, and zero out the attached shift registers
function setupController()
    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, DATA_BITS, SPI_FREQUENCY_DIVIDER)
    gpio.mode(LATCH_GPIO, gpio.OUTPUT)

    setAndOutputState(0)
end

function setAndOutputState(value)
    CURRENT_OUTPUT_STATE = value
    updateOutputPins(CURRENT_OUTPUT_STATE)
end

function outputCurrentState()
    updateOutputPins(CURRENT_OUTPUT_STATE)
end

-- write 32 bits to the shift register chips via SPI
function updateOutputPins(value)
    gpio.write(LATCH_GPIO, gpio.LOW)
--    tmr.delay(10000) -- 10 millisecond

    spi.send(1, value)

--    tmr.delay(10000) -- 10 millisecond
    gpio.write(LATCH_GPIO, gpio.HIGH)
end

-- turn on a single pin on a single 595, and turn off all other pins
function setLight(lightId)
    if lightId > 0 then
        setAndOutputState(bit.bit(lightId-1))
    else
        setAndOutputState(0)
    end
end

-- turn on a pin, leave all other pins as-is
function addLight(lightId)
    if lightId > 0 then
        CURRENT_OUTPUT_STATE = bit.set(CURRENT_OUTPUT_STATE, lightId-1)
    end
    -- CURRENT_OUTPUT_STATE = bit.bor(CURRENT_OUTPUT_STATE, (lightId ~= 0) and bit.lshift(1, lightId - 1) or 0)
    -- CURRENT_OUTPUT_STATE = (lightId ~= 0) and bit.set(CURRENT_OUTPUT_STATE, lightId - 1) or CURRENT_OUTPUT_STATE
    outputCurrentState()
end

-- turn off a pin, leave all other pins as-is
function removeLight(lightId)
    if lightId > 0 then
        CURRENT_OUTPUT_STATE = bit.clear(CURRENT_OUTPUT_STATE, lightId - 1)
    end
    -- CURRENT_OUTPUT_STATE = (lightId == 0) and CURRENT_OUTPUT_STATE or bit.band(CURRENT_OUTPUT_STATE, bit.bnot(bit.lshift(1, lightId - 1)))
    -- CURRENT_OUTPUT_STATE = (lightId == 0) and CURRENT_OUTPUT_STATE or bit.clear(CURRENT_OUTPUT_STATE, lightId - 1)
    outputCurrentState()
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
