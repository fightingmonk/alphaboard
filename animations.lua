local ANIM_TIMER = tmr.create()
local ANIM_DELAY = 500

-- cycle through all lights in order, ascending then descending, forever and ever
function animateLightsLinear()
    local light = 0
    local ascending = true
    local maxLight = 28

    ANIM_TIMER:unregister()
    ANIM_TIMER:register(ANIM_DELAY, tmr.ALARM_AUTO, function()
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
    ANIM_TIMER:start()
end

-- cycle through all lights in order, ascending then descending, forever and ever
function animateLightsStripe()
    local light = 0
    local waxing = true
    local maxLight = 32

    ANIM_TIMER:unregister()
    ANIM_TIMER:register(ANIM_DELAY, tmr.ALARM_AUTO, function()
        if light == maxLight then
            waxing = not waxing
            light = 0
        end

        light = light + 1

        if waxing == true then
            addLight(light)
        else
            removeLight(light)
        end
    end)
    ANIM_TIMER:start()
end

-- unregister the NodeMCU timer we use for animations
function stopAnimation()
    ANIM_TIMER:unregister()
end
