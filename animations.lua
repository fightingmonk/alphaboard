ANIM_TIMER_ID = 1 -- Use NodeMCU timer id 1 for animations

-- cycle through all lights in order, ascending then descending, forever and ever
function animateLights()
    local light = 0
    local ascending = true
    local maxLight = 8 * #CHIP_IO_PINS

    stopAnimation()
    tmr.alarm(ANIM_TIMER_ID, 100, tmr.ALARM_AUTO, function()
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
    tmr.alarm(ANIM_TIMER_ID, 100, tmr.ALARM_AUTO, function()
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
    tmr.unregister(ANIM_TIMER_ID)
end
