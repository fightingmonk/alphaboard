# Alphaboard

Drive an alphabet light board from an ESP8266.

This repo contains firmware for an [Adafruit Huzzah ESP8266](https://www.adafruit.com/product/2471) 
running the [NodeMCU Lua](https://learn.adafruit.com/adafruit-huzzah-esp8266-breakout/using-nodemcu-lua) runtime. 
It uses the ESP8266's SPI interface to control four 72HN595N 8-bit shift register ICs, which drive LEDs.

## Setup

1. Get your ESP8266 board connected to your computer and
[flashed](https://nodemcu.readthedocs.io/en/latest/en/flash/) with the
[latest Lua runtime](https://nodemcu-build.com/). (This code requires nodemcu built with the `bit`, `gpio`, and `spi` modules, plus `http`, `wifi`, and `tls` if you want to connect to a message server.)
1. Install [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader)
1. If you want to poll a server for messages to display, in `secrets.lua`:
    1. add your Wifi network SSID and password
    1. add the URL and shared secret for your message server
1. Run `upload.sh` to upload this code to your board
1. Reset the board for good measure and have fun!

## Hardware build

Follow the wiring diagram from [ESP8266 With 74HC595 LED and Matrix Driver](https://www.instructables.com/NODEMCU-LUA-ESP8266-With-74HC595-LED-and-Matrix-Dr/), with these changes:

1. This build uses four 72HN595N ICs. The third and fourth ICs follow the daisy chaining pattern: pin 9 from IC N is connected to pin 14 of IC N+1.
2. Outputs Q0-Q7 (pins 15 and 1-7) on each IC are individually wired to 220 ohm resistors which connect to the anodes of LEDs. The LED cathodes connect to ground.

## Interactive use

Once you've uploaded this code to your board, you can use a serial terminal to
run some of the functions interactively.

`setLight(lightIndex)` turns on a single output pin, specified by `lightIndex`.
1-8 map to the first IC, the one connected to GPIO 15. 9-16 map to the IC on GPIO 2. 17-24 map to GPIO 4, and 25-32 map to GPIO 5.

`displayLetter(letter)` turns on the output pin whose index corresponds to the alphabetical value
of the first character in string `letter`. e.g. `displayLetter("ABC")` turns on pin 1,
while `displayLetter("ZY")` turns on pin 26.

`animateLightsLinear()` and `animateLightsStripe()` cycle all 32 output pins, causing lights to blink in sequence. `stopAnimation()` stops the animation loop.

`displayMessage(message)` turns on output pins for each letter in the string `message` sequentially. Uses the same mapping logic as  `displayLetter()`.

## Setting up a message server

The message polling function in `messages.lua` makes a form-encoded HTTP POST that includes `FetchKey` with a shared secret in the request body for auth. It strips leading and trailing whitespace from the server response and, if not empty, passes the result to `displayMessage()`.

The `cgi` directory in this repo contains a simple CGI message server. It handles two POST requests:

1. Webhook callbacks from Twilio's SMS service that have a matching MessagingServiceSid and SMS message are stored in a tmp file on the server, and
1. POSTs containing a valid `FetchKey` param receive the current tmp file contents, and the tmp file is emptied.

The server code is based on [Pål Ruud's](https://github.com/ruudud) [Bash CGI Script](https://github.com/ruudud/cgi).

To set up this message server you'll need a web server with CGI functionality (I use Nginx w/ fcgi). Put the right values into `cgi/message-server.sh` for `TWILIO_MSG_SERVICE_SID` and `MESSAGE_FETCH_KEY`, and then upload both files from the `cgi` directory to your server's CGI directory and make them executable.

Once uploaded, create a programmable SMS service in Twilio. In the Twilio config screen for your service, enter the full URL to message-server.sh in the *Request URL* box under *Inbound Settings*, specify *POST*, and check the *Process Inbound Messages* checkbox.

At this point it should, as they say, _just work_. :)
