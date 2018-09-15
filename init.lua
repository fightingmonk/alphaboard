
-- we use pin 13 for serial input (DS) and 14 for storage reset clock (SHCP)
--   on all four chips, and a separate GPIO pin for each 595's shift register clock (STCP)
--   which allows us to write to any one chip at a time using the SPI bus

-- we use the 8266's GPIO pins to control each of 4 shift register chips
-- note that NodeMCU's pin numbering differs from the pinout on the board ¯\_(ツ)_/¯
--     https://nodemcu.readthedocs.io/en/master/en/modules/gpio/
CHIP_IO_PINS = {8, 4}--, 2, 1} -- corresponds to GPIO pins 15, 2, 4, 5 on the 8266 board

-- initialize SPI, set our GPIO control pins to output mode, and zero out the attached shift registers
function setupController()
  spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_LOW, spi.DATABITS_8, 0)

  for i = 1, #CHIP_IO_PINS do
    gpio.mode(CHIP_IO_PINS[i], gpio.OUTPUT)
    sendData(i, 0)
  end
end

-- shift register bit patterns for turning on individual output pins
LIGHT_BYTE = {1,2,4,8,16,32,64,128}

-- write 8 bits to one of the shift register chips by flipping the selected chip's STCP pin
function sendData(chip, byte)
    gpio.write(CHIP_IO_PINS[chip], gpio.LOW)
    spi.send(1,byte)
    gpio.write(CHIP_IO_PINS[chip], gpio.HIGH)
end

-- turn on a single pin on a single 595, and turn off all other pins
-- note this writes to all chips in serial so it's slow; keeping state is faster
function setLight(lightId)
    local chip = math.ceil(lightId / 8)
    local light = ((lightId-1) % 8) + 1
    for i = 1, #CHIP_IO_PINS do
        if i == chip then
            sendData(i, LIGHT_BYTE[light])
        else
            sendData(i, 0)
        end
    end
end

-- Use NodeMCU timer id 1 for animations
TIMER_ID = 1

-- cycle through all lights in order, ascending then descending, forever and ever
function animateLights()
    local light = 0
    local ascending = true
    local maxLight = 8 * #CHIP_IO_PINS

    stopAnimation()
    tmr.alarm(TIMER_ID, 100, tmr.ALARM_AUTO, function()
        if light == 1 then
            ascending = true
        elseif light == maxLight then
            ascending = false
        end

        if ascending == true then
            light = light + 1
        else
            light = light - 1
        end

        setLight(light)
    end)
end

-- same as animateLights, but optimized to avoid resetting all 4 chips each cycle
function animateLightsOpt()
    local chip = 1
    local light = 0
    local ascending = true

    stopAnimation()
    tmr.alarm(TIMER_ID, 100, tmr.ALARM_AUTO, function()
        -- switch directions at each end
        if (chip == #CHIP_IO_PINS and light == 8 and ascending == true) then
            ascending = false
        elseif (chip == 1 and light == 1 and ascending == false) then
            ascending = true
        end

        -- increment or decrement the active light
        --   when transitioning to a different chip, first zero out the previous chip
        if ascending == true then
            light = light + 1
            if light > 8 then
                sendData(chip, 0)
                chip = chip + 1
                light = 1
            end
        else
            light = light - 1
            if light < 1 then
                sendData(chip, 0)
                chip = chip - 1
                light = 8
            end
        end

        sendData(chip, LIGHT_BYTE[light])
    end)
end

-- unregister the NodeMCU timer we use for animations
function stopAnimation()
    tmr.unregister(TIMER_ID)
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

-- display a message letter by letter
LETTER_DURATION = 1000 -- how long to illuminate each letter when displaying a message
function displayMessage(message)
    stopAnimation()

    local index = 1
    tmr.alarm(TIMER_ID, LETTER_DURATION, tmr.ALARM_AUTO, function()
        -- blank the board for a short time
        setLight(0)
        tmr.delay(300000)

        -- clean up our global timer if we're done
        if index > string.len(message) then
            stopAnimation()
            return
        end

        -- display the current letter of the message
        displayLetter(string.sub(message, index))
        index = index + 1
    end)
end

setupController()
animateLightsOpt()
