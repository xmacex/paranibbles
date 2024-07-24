-- paranibbles
--
-- 0100 1011
--
-- by xmacex
-- inspired by oskar's video
-- on paradiddles
-- https://www.youtube.com/watch?v=EZBpxkxJg0o

er = require 'er'
s  = require 'sequins'


if not tab then
   tab = require("tab")
end

screen.width = 128
screen.height = 64

nibble  = 4
giggle  = nil
accents = nil
accent  = false
current_value = "000"

function init()
   init_params()
   giggle  = s(nibbleToParadiddle(params:get('nibble')))
   accents = s(er.gen(3, 8))

   params:set('clock_tempo', 145)

   midi_dev = midi.connect(params:get('midi_dev'))

   -- redraw_clock = clock.run(redraw)
   ui_clock = clock.run(tick)
end

function init_params()
   params:add_number('midi_dev', "midi dev", 1, 16, 3)
   params:set_action('midi_dev', function(v) midi_dev=midi.connect(v) end)
   params:add_number('midi_ch', "midi ch", 1, 16, 1)

   params:add_number('nibble', "nibble", 0, 2^4-1, 4)
   params:set_action('nibble', function()
			giggle:settable(nibbleToParadiddle(params:get('nibble')))
   end)

   -- params:add_number('0', "sound 0", 0, 127, 63)
   params:add_control('0', "sound 0", controlspec.MIDINOTE)
   -- params:add_number('1', "sound 1", 0, 127, 64)
   params:add_control('1', "sound 1", controlspec.MIDINOTE)
   params:delta('1', 1)
   params:add_number('accent_rot', "accent rotate", 0, 7)
   params:set_action('accent_rot', function(v)
			accents = s(er.gen(3, 8, v))
   end)
end

-- From https://stackoverflow.com/a/9080080
function toBits(num, bits)
   -- returns a table of bits, most significant first.
   -- local bits = bits or math.max(1, select(2, math.frexp(num)))
   local bits = bits or 16
   local t = {} -- will contain the bits
   for b = bits, 1, -1 do
      t[b] = math.fmod(num, 2)
      num = math.floor((num - t[b]) / 2)
   end
   return t
end

function toNibbleBits(num)
   return toBits(num, 4)
end

local function invertNibble(num)
   local bits = toNibbleBits(num)
   local t = {}
   for b = 1, 4 do
      t[b] = 1 + bits[b] * -1
   end
   return t
end

function nibbleToParadiddle(num)
   local p = {}
   local bits = toNibbleBits(num)
   local ibits = invertNibble(num)
   for b=1,4 do
      p[b] = bits[b]
   end
   for b=1,4 do
      p[b+4] = ibits[b]
   end
   return p
end

function tick()
   while true do
      clock.sync(1/4)
      current_value = giggle()
      accent = accents()
      if accent then
        vel = 120
      else
        vel = 64
      end
      if current_value == 0 then
         midi_dev:note_on(params:get('0'), vel, params:get('midi_ch'))
      else
         midi_dev:note_on(params:get('1'), vel, params:get('midi_ch'))
      end
      redraw()
   end
end

function redraw()
   screen.clear()
   draw_nibble()
   draw_music()
   screen.update()
end

function draw_nibble()
  local bitstring=""
   local bits = nibbleToParadiddle(params:get('nibble'))
   for b=1,8 do
      bitstring=bitstring..bits[b]
   end
   screen.move(10, 10)
   screen.level(2)
   screen.font_size(8)
   screen.text(bitstring)
end

function draw_music()
   -- screen.move(screen.width/2, screen.height/2-(screen.height/4)*2*current_value)
   screen.move(screen.width/2, screen.height - screen.height*0.8*current_value)
   screen.level(10)
   if accent then
     screen.font_size(20)
   else
     screen.font_size(15)
   end
   screen.text('*')
end

function enc(k, d)
   if k == 2 then
      -- FIXME: argh becomes integer at max value.
      params:delta('nibble', d)
   end

   if k == 3 then
      params:delta('accent_rot', d)
   end
end
