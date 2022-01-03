dofile("secrets.lua")
--dofile("animations.lua")

local MESSAGE_TIMER = tmr.create() 
local LETTER_DURATION = 2000

local ws = nil

function connectToMessageServer()
    if (MESSAGE_SERVER_URL == nil or MESSAGE_SERVER_URL == '') then
        return
    end

    if ws == nil then
        ws = websocket.createClient()
        ws:on("connection", function(ws)
          print('Connected to message server')
        end)
        ws:on("receive", function(_, msg, opcode)
          msg = trim(string.upper(msg))
          print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
          
          if msg == 'HALO' then
            -- ignore the hello
          elseif msg == 'LINEAR' then
            animateLightsLinear()
          elseif msg == 'STRIPE' then
            animateLightsStripe()
          else
            displayMessage(msg)
          end
        end)
        ws:on("close", function(_, status)
          print('message server disconnected', status)
          ws = nil -- required to lua gc the websocket client
          connectToMessageServer()
        end)
    end

    ws:connect(MESSAGE_SERVER_URL)
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