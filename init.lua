dofile("spi-lights.lua")
dofile("animations.lua")

MESSAGE_TIMER_ID = 2 -- Use NodeMCU timer id 2 for our message timer loop
LETTER_DURATION = 1000 -- how long to illuminate each letter when displaying a message

-- display a message letter by letter
function displayMessage(message)
    stopAnimation()

    local index = 1
    tmr.alarm(MESSAGE_TIMER_ID, LETTER_DURATION, tmr.ALARM_AUTO, function()
        -- blank the board for a short time
        setLight(0)
        tmr.delay(300000)

        -- clean up our global timer if we're done
        if index > string.len(message) then
            stopMessageTimer()
            return
        end

        -- display the current letter of the message
        displayLetter(string.sub(message, index))
        index = index + 1
    end)
end

-- unregister the NodeMCU timer we use for messages
function stopMessageTimer()
    tmr.unregister(MESSAGE_TIMER_ID)
end

setupController()
animateLightsOpt()
