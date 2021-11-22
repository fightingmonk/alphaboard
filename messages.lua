dofile("secrets.lua")

local MESSAGE_TIMER = tmr.create() 
local LETTER_DURATION = 2000
local POLL_DELAY = 60000 -- how long to wait before checking for a message

-- check our message server for a queued message after a configured delay
-- if we receive a non-blank response body (after trimming whitespace) then 
--   display the message; otherwise re-invoke ourself
function checkForMessagesSoon()
    MESSAGE_TIMER:unregister()
    MESSAGE_TIMER:register(POLL_DELAY, tmr.ALARM_SINGLE, function()
        http.post(MESSAGE_SERVER_URL,
            'Content-Type: application/x-www-form-urlencoded\r\n',
            'FetchKey=' .. MESSAGE_SERVER_SECRET,
            function(code, data)
                if (code < 0) then
                    print("HTTP request failed", code)
                    checkForMessagesSoon()
                else
                    message = trim(data)
                    if string.len(message) > 0 then
                        print("got a message:", message)
                        displayMessage(message)
                    else
                        checkForMessagesSoon()
                    end
                end
            end)
    end)
    MESSAGE_TIMER:start()
end

-- display a message letter by letter
function displayMessage(message)
    stopAnimation()
    stopMessageTimer()
    setLight(0)

    local index = 1
    MESSAGE_TIMER:register(LETTER_DURATION, tmr.ALARM_AUTO, function()
        -- blank the board for a short time
        setLight(0)
        tmr.delay(300000)  -- 300 millisecond

        -- clean up our global timer if we're done
        if index > string.len(message) then
            stopMessageTimer()
            checkForMessagesSoon()
        else
            -- display the current letter of the message
            displayLetter(string.sub(message, index))
            index = index + 1
        end
    end)
    MESSAGE_TIMER:start()
end

-- unregister the NodeMCU timer we use for message polling and display
function stopMessageTimer()
    MESSAGE_TIMER:unregister()
end

-- string trimming
function trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
 end
 -- note: the '()' avoids the overhead of default string capture.
 -- This overhead is small, ~ 10% for successful whitespace match call
 -- alone, and may not be noticeable in the overall benchmarks here,
 -- but there's little harm either.  Instead replacing the first `match`
 -- with a `find` has a similar effect, but that requires localizing
 -- two functions in the trim7 variant below.