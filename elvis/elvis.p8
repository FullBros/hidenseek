pico-8 cartridge // http://www.pico-8.com
version 29
__lua__


elvis_msg = {
  "oh yeah",
  "that's right",
  "come on",
}


tick = 0
max_tick = 32
animate_each = 4




function _init()
  --pal(0,false)
  --pal(12,true)

  poke(0x5f42, 0b0100) --distort
  poke(0x5f41, 0b0100) --echo
  poke(0x5f43, 0b1111) --lowpass

  pal(11,128+10,1) --use lime green

  -- new hero
  elvis = player:create(56,80)

  music(0) -- go music!
end


delay_shoot = 0
function _update()

  tick = (tick + 1) % max_tick
  delay_shoot += 1

  elvis.animation = elvis.animations.idle
  elvis.hard = false

  if btn(4) then
    elvis.animation = elvis.animations.ready

    if (btn(0) or btn(1)) elvis.animation = elvis.animations.right
    if (btn(2)) elvis.animation = elvis.animations.up

    --playing diagonal
    if (btn(2) and btn(0)) or
       (btn(2) and btn(1)) then
        elvis.animation = elvis.animations.diagonal
    end

    -- new bullet
    local direction = 0

    if (btn(0)) direction = 1
    if (btn(1)) direction = 5
    if (btn(2)) direction = 3
    if (btn(0) and btn(2)) direction = 2
    if (btn(1) and btn(2)) direction = 4

    if (direction > 0 and delay_shoot > 10) then
      add(bullets, bullet:create(elvis.x+8, elvis.y+8, direction))
      delay_shoot = 0
    end


  else

    if (btn(0) or btn(1)) elvis.animation = elvis.animations.walk

    --moves
    if (btn(0)) elvis.x -= elvis.speed
    if (btn(1)) elvis.x += elvis.speed
  end


  -- flip sprite
  if (btn(0)) elvis.flip = true
  if (btn(1)) elvis.flip = false


  for b in all (bullets) do b:update() end
  for a in all (aliens)  do a:update() end

  select_checkpoint()

  if (current_checkpoint != nil) then
    current_checkpoint:update()
  end

  play_music()

end



function _draw()

  cls()
  palt(0,false) -- use dark in sprites


  draw_background(elvis.hard)

  palt(12, true) -- use cyan in map
  map(0,0,0,0,128,128)
  palt(12, true) -- but not for characters


  draw_title()
  text:indication("rock this way ➡️")

  elvis:draw()

  if (current_checkpoint != nil) then
    current_checkpoint:draw()
  end


  for a in all (aliens)  do a:draw() end
  for b in all (bullets) do b:draw() end

  cam:update()
  --print(elvis.x, cam.x, cam.y)

end



function draw_background (hard)

  hard = hard or false
  --pal(6, 6)

  if (not hard) then
    color(12)
    rectfill(cam.x - 84, cam.y + -20, cam.x + 128 + 20, cam.y + 188)
    return 1
  end

  -- hard mode
  local alternate = 0
  --local alternate = tick % 2 --psyche mode

  --pal(6, 14)

  for i = 0,256,16 do
    local col = (i%32 == alternate) and 8 or 2 --2 or 9

    local pts = {
      {x=cam.x-20, y=i-tick},
      {x=cam.x+64, y=i-83-tick},
      {x=cam.x + 128 + 20, y=i-tick},
    }

    color(col)
    polyfill(pts)
  end
end



--
-- splash
--

function draw_title ()

  -- shadow
  color(3)
  text:center("e l v i s", 14, 0, 1)
  text:center("e l v i s", 14, 1, 1)
  text:center("e l v i s", 14, 1, 0)

  color(11)
  text:center("e l v i s", 14)


  color(9)
  text:center("v s", 25, 0, 1)
  text:center("v s", 25, 1, 1)

  color (10)
  text:center("v s", 25)

  color(2)
  text:center("i n v a d e r s", 36, 0, 1)
  text:center("i n v a d e r s", 36, 1, 1)

  color(8)
  text:center("i n v a d e r s", 36)

  color(0)
end


--
-- game
--


checkpoints = {}

checkpoint = {}
checkpoint.__index = checkpoint
current_checkpoint = nil

function checkpoint:create (x, init, update, draw)

  c = {}
  setmetatable(c, checkpoint)

  c.x = x
  c.init = init
  c.update = update
  c.draw = draw

  return c

end

function select_checkpoint ()

  for k, c in ipairs(checkpoints) do

    if ( elvis.x > c.x ) then
      current_checkpoint = c
      c:init()
      checkpoints[k] = nil
      return
    end

  end
end

-- first checkpoint
add(checkpoints, checkpoint:create(
  230,

  -- init
  function (self)
    self.tutorial = true
    self.ennemies = false
  end,

  -- update
  function (self)

    -- if ( self.ennemies) then
    --   add(aliens, alien:create(280, 30))
    --   add(aliens, alien:create(320, 70))
    --   add(aliens, alien:create(330, 100))
    --   self.ennemies = true
    -- end
  end,

  -- draw
  function (self)

    if (self.tutorial and elvis.animation != elvis.animations.ready) then
       text:indication("press 🅾️ and be ready", self.x)
    end

    if (self.tutorial and elvis.animation == elvis.animations.ready) then
       text:indication("now use directions. good luck!", self.x)
    end

    if (self.tutorial and guitar.playing) then
       self.tutorial = false
    end


  end

))



--cp1.init("test plus long")
--stop()
--add(checkpoints, cp1)



--
-- music
--

bpm = 160
measure = 32

beat = 0

soundtrack = {}
soundtrack.measure = 0
soundtrack.basslines = {5,6}
soundtrack.drums = {0,1}

guitar = {}
guitar.playing = false




function play_music ()

   local hard

  if (elvis.animation == elvis.animations.right or
      elvis.animation == elvis.animations.diagonal or
      elvis.animation == elvis.animations.up
    ) then

    elvis.hard = (elvis.animation == elvis.animations.up)

    --if (guitar.playing == false or hard == 1) then
      -- guitarpart = stat(16)+8
      -- sfx(guitarpart, 2, stat(20), hard)
       guitar.playing = true
    -- end
  else
    --sfx(-1, 2)
    guitar.playing = false
  end


  if guitar.playing then

    if (stat(18) == -1 or elvis.hard) then
      guitarpart = stat(16)+8
      sfx(guitarpart, 2, stat(20), hard)
    end
  else
    sfx(-1, 2)
  end

end


--
-- player
--

player = {}
player.__index = player

function player:create (x, y)

  p = {}
  setmetatable(p, player)

  p.x = x
  p.y = y
  p.flip = false
  p.animation = {}
  p.speed = 2
  p.hard = false

  p.first = 64 --first position in sprite sheet
  p.animations = {
    idle = {0,1},
    walk = {2,3,4,5,6,4},
    ready = {7,8},
    right = {9,10,11},
    diagonal = {12,13,14},
    up = {15,16,17},
  }

  p.animation = p.animations.idle
  p.last_animation = {}
  p.sprite = 0
  p.step = 0

  return p
end


function player:animate()

  local sprite

  if (self.animation != self.last_animation) then
    self.step = 1
    self.last_animation = self.animation
  end

  sprite = self.animation[self.step]

  sprite = self.first + --page
          (sprite) * 2 + --numero de sprite
          ((sprite < 8) and 0 or 16) + --saut de ligne
          ((sprite < 16) and 0 or 16) --saut de ligne


  if(tick % animate_each == 0) self.step = (self.step % #self.animation) + 1

  self.sprite = sprite
end


function player:draw()
  self:animate()
  spr(self.sprite, self.x, self.y, 2,2, self.flip)
end


---
--- aliens
---

aliens = {}
alien = {}
alien.__index = alien

function alien:create (x, y)

  a = {}
  setmetatable(a,alien)

  a.x = x
  a.y = y
  a.flip = false
  a.w = 1
  a.h = 1

  a.first = 224 --first position in sprite sheet
  a.animations = {
    fly = {0,1},
    die = {2}
  }

  a.animation = a.animations.fly
  a.last_animation = {}
  a.sprite = 0
  a.step = 0

  return a
end

function alien:animate()

  local sprite

  if (self.animation != self.last_animation) then
    self.step = 1
    self.last_animation = self.animation
  end

  sprite = self.animation[self.step]

  -- sprite = self.first + --page
  --         (sprite) * 2 + --numero de sprite
  --         ((sprite < 8) and 0 or 16) + --saut de ligne
  --         ((sprite < 16) and 0 or 16) --saut de ligne

  sprite = self.first + --page
          (sprite)--numero de sprite
          -- + ((sprite < 8) and 0 or 16) + --saut de ligne
          --((sprite < 16) and 0 or 16) --saut de ligne

  if (tick % animate_each == 0) self.step = (self.step % #self.animation) + 1

  self.sprite = sprite
end


function alien:update ()

  local target = {}
  target.x = elvis.x + 4
  target.y = elvis.y + 4


  if (target.x > self.x) self.x+=1
  if (target.x < self.x) self.x-=1
  if (target.y > self.y) self.y+=1
  if (target.y < self.y) self.y-=1

  -- collisions
  for b in all(bullets) do

  end

  self.flip = (elvis.x > self.x)

end

function alien:draw()
  self:animate()
  spr(self.sprite, self.x, self.y, self.w, self.h, self.flip)
end



--
-- bullet
--

bullets = {} -- all bullets
bullet = {}
bullet.__index = bullet



function bullet:create (x, y, direction)

  b = {}
  setmetatable(b,bullet)

  b.x = x
  b.y = y
  b.radius = 2
  b.direction = direction
  b.speed = 3
  b.color = 0

  return b
end

function bullet:update()

  local x,y = 0,0

  if (1 == self.direction) x -= self.speed
  if (2 == self.direction) x -= self.speed y -= self.speed
  if (3 == self.direction) y -= self.speed
  if (4 == self.direction) x += self.speed y -= self.speed
  if (5 == self.direction) x += self.speed


  -- normalize diagonal moves
  if (abs(x) + abs(y) > self.speed) then
    local dist = sqrt(2)
    x /= dist
    y /= dist
  end

  self.x += x
  self.y += y
end


function bullet:draw ()
  --color(8)
  --circfill(self.x, self.y, self.radius + 1)

  --alt color
  self.color = (self.color + 1) % 2
  local c = (self.color == 1) and 14 or 9

  color(c)
  circfill(self.x, self.y, self.radius)
  circfill(self.x, self.y, self.radius - 1)

end



--
-- camera
--

cam = {}
cam.x = 0
cam.y = 0
cam.threeshold = 5

function cam:update()

  local target = {}

  target.x = elvis.x - 64 -- halfscreen
  target.x = max(target.x, 0 - cam.threeshold) -- left boundary

  local direction = (cam.x > target.x) and 1 or -1

  if abs(cam.x - target.x) > cam.threeshold then
    cam.x = target.x + cam.threeshold * direction
  end

  camera(cam.x, cam.y)
end




--
-- utils
--

text = {}

function text:center (t, y, offx, offy)

  offx = offx or 0
  offy = offy or 0

  print(t, 64-flr(#t*4/2)+offx, y+offy)
end


function text:blink (t, y, offx, offy)
  if (tick % 16 < 5) return
  text:center(t, y, offx, offy)
end


function text:indication (t, offx)
  offx = offx or 0

  -- shadow()
  color(13)
  text:blink(t, 50, offx, 1)
  text:blink(t, 50, offx + 1, 1)

  color(7)
  text:blink(t, 50, offx)
end



-- define polygon edges
local function polyf_edge(a, b, xls, xrs)
 local ax,ay=a.x,a.y
 local bx,by=b.x,b.y
 if (ay==by) return

 local x,dx=ax,(bx-ax)/abs(by-ay)
 if ay<by then
  for y=ay,by do
   xrs[y]=x;x+=dx
  end
 else
  for y=ay,by,-1 do
   xls[y]=x;x+=dx
  end
 end
end


-- draw a polygon
function polyfill(pts)
 local i, x, y, xl
 local xleft, xright = {}, {}
 local npts = #pts

 -- if there is less than 2 pts
 -- there is nothing to draw
 if #pts < 3 then return end

 for i=1, npts do
  polyf_edge(pts[i],
             pts[i%npts+1],
             xleft, xright)
 end
 for y, xl in pairs(xleft) do
  line(xl, y, xright[y], y)
 end
end






__gfx__
00000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc5000050500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccc5500505050000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc5500555550005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc0000055550055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccc0000555500055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc6666000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc5555006655066506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555500655065506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550000005506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550066660006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550655550006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550655550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000055500655550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000055500666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005500066000000655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005550655550000655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005500655550000655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005506555550660055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005506555550655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000655550055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000555500055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006666000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555006655066506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555500655065506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550000005506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550066660006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550655550006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555550655550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000055500655550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000055500666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005500066000000655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccc0ccccccccccccccccccccccccccccccccccccccccccccccc0ccccccccccccccccccccccccccccccc0cccccccc
cccccc00c0cccccccccccc00c0ccccccccccc00cccccccccccccccccccccccccccccccccc0ccccccccccc00cccccccccccccccccccccccccccccc00ccccccccc
cccccc0f0ccccccccccccc0f0cccccccccccc0f0ccccccccccccc0000cccccccccccccc00cccccccccccc0f0ccccccccccccc0000cccccccccccc0f0cccccccc
ccccccfff99cccccccccccfff99ccccccccccfffccccccccccccc0f0ccccccccccccccc0f0cccccccccccfffccccccccccccc0f0cccccccccccccfffcccccccc
cccccccff999cccccccccccff999cccccc999cffcccccccccccccfffcccccccccccccccfffccccccccccccffcccccccccccccfffcccccccccccc00ffcccccccc
ccccc00000999cccccccc00000999ccccc9400000ccccccccc9990ffcccccccccccc9900ffccccccccc900000cccccccccc990ffccccccccccc000000ccccccc
cccc00000009cccccccc00000009cccccc9000000ccccccccc9000000ccccccccccc90000cccccccccc000000cccccccccc900000ccccccccc00c00000cccccc
ccc000000000ccccccc000000000cccccc90000000fccccccc00900000ccccccccc990000ccccccccc9000000cccccccccc0000000cccccccc099909c00ccccc
ccc00c0000c0ccccccc00c0000c0cccccc900000cccccccccc009000c00fccccccc9490000cccccccc90000000fcccccccc00000000fcccccc009999cc0ccfcc
cccc00f00f0ccccccccc00f00f0cccccccc40f0ccccccccccc90f00cccccccccccc4490000fccccccc44000cccccccccccc9000ccccccccccc90ff44444f4ffc
ccccc4777cccccccccccc4777cccccccccc4c77cccccccccccc4c77cccccccccccc4cc77cccccccccc4cc77ccccccccccccc476ccccccccccc99f999cccccccc
cccc4c7777cccccccccc4c7777cccccccccff677ccccccccccc4c677ccccccccccffcc777ccccccccffcc776cccccccccccc4776ccccccccccc999797ccccccc
cccfcc7cc77ccccccccfcc7cc77ccccccccf76c77ccccccccccff677ccccccccccfcc77c7ccccccccfcc77c67cccccccccccf776ccccccccccccc7cc77cccccc
ccffc77ccc7cccccccffc77ccc7ccccccccc7ccc7cccccccccc0067cccccccccccccc770cccccccccccc7ccc7cccccccccc0076ccccccccccccc77ccc7cccccc
ccccc0ccc0ccccccccccc0ccc00cccccccc00ccc0cccccccccc0cc0cccccccccccccc0ccccccccccccc00ccc0cccccccccc0cc0ccccccccccccc0ccc0ccccccc
ccccc00cc00cccccccccc00cc0ccccccccc0cccc00cccccccccccc00ccccccccccccc00cccccccccccc0cccc00cccccccccccc00cccccccccccc00cc00cccccc
ccccccc0ccccccccccccccc0ccccccccccccccccccccccccccccccccccccccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccfcccccc
ccccc00cccccccccccccc00cccccccccccccc000cccccccccccccccc0cccccccccccc00cccccccccccccc00c0ccccccccccccccccccccccccccc0cccffcccccc
ccccc0f0ccccccccccccc0f0ccccccccccccc0ff0ccccccccccccc00ccccccccccccc0f0ccccffccccccc0f0ccccffcccccccc0000cccccccccc0cccc4cccccc
cccccfffcccccccccccccfffcccccccccccccff0cccccccccccccc0f0ccccccccccccfffccccfccccccccfffccccfccccccccc0f0cccffccccc0f0cccfcccccc
cccc00ffcccccccccccc00ffcccccccccccc00ffccccccccccccccfffccccccccccc00ffcccfcccccccc00ffcccfccccccccccfffcccfcccccc0fffcc40ccccc
ccc000000cccccccccc000000cccccccccc000000cccccccccccc00ffcccccccccc000000c40ccccccc000000c40ccccccccc00ffccfcccccccc0ffcc400cccc
cc00c00000cccccccc00c00000cccccccc00c00000cccccccccc000000cccccccc0000990400cccccc000099040ccccccccc00000040cccccccc0000040ccccc
cc099909c00ccccccc099909c00cccccc009909000ccccccccc00c00000ccccccc00c099400ccccccc00c099400cccccccc00099040cccccccc000099499cccc
cc009999cc0ccfcccc009999cc00cfccc0099990c0ccfccccc009909000ccccccc00999499cccccccc00999499ccccccccc00c9940ccccccccc00000949ccccc
cc90ff44444f4ffccc90ff44444f4ffcc90f944444f4ffcccc0099990c00cfccccc0ff9999ccccccccc0ff9999ccccccccc0099499cccccccccc00099999cccc
cc99f999cccccccccc99f999ccccccccc9ff999ccccccccccc90f944444f4ffcccc9f499ccccccccccc9f499cccccccccccc0f9999ccccccccccc000ff99cccc
ccc999797cccccccccc999797ccccccccc999797cccccccccc9ff999cccccccccccc99997ccccccccccc9999ccccccccccc9ff99cccccccccccccc70f499cccc
ccccc7cc77ccccccccccc7cc77ccccccccccc7c77cccccccccc9997977ccccccccccc99c77ccccccccccc9977ccccccccccc999977cccccccccccc779997cccc
cccc77ccc7cccccccccc77ccc7cccccccccc77cc7cccccccccccc77cc7cccccccccc77ccc7cccccccccc77cc7cccccccccccc99cc7ccccccccccc777c777cccc
cccc0cccc00ccccccccc0ccc0ccccccccccc0ccc00ccccccccccc0ccc0cccccccccc0ccc0ccccccccccc0ccc00ccccccccccc0ccc0cccccccccc0c7c0c7ccccc
cccc00ccc0cccccccccc00cc00cccccccccc00cc0cccccccccccc00cc00ccccccccc00cc00cccccccccc00cc0cccccccccccc00cc00ccccccccc00cc00cccccc
ccccccccfcccccccccccccccfccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccc0cffccccccccccccccffccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc00ccc4ccccccccccc00004ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc0f0ccfccccccccccc0f0cfccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc0fffc40ccccccccccfffc40cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc0ffc400cccccccccfffc400ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc000040cccccccccc000040cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc00099499cccccccc00099499ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc0000949ccccccccc0000949cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc00099999cccccccc00099999ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc000ff99ccccccccc000f999ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc0f499ccccccccccc0ff99ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc799977cccccccccc799977cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccc777c777ccccccccc777c777cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc0c7cc00ccccccccc0c7c0c7ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc00ccc0cccccccccc00cc00cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccbbbbccccccccccccbbbbccccccccccccbbbbcccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc3cbbbbb3ccccccccccbbbbbbcccccccc3cbbbbb3ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
cc333bbbb333ccccccc3bbbbbb3bcccccc333bbbb333cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
cc773bbbb377bccccc333bbbb333bccccc773bbbb377bccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
cc707bbbb707bccccc703bbbb307bccccc707bbbb707bccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
cc707bbbb707bccccc707bbbb707bccccc707bbbb707bccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc7bbbbbb7bbcccccc7bbbbbb7bbcccccc7bbbbbb7bbccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
cccbbbbbbbbbbccccccbbbbbbbbbbccccccbbbbbbbbbbccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
cccb7373737bbcc3cccb7373737bbccc3ccb7373737bbccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
3ccb3333333bbc3ccccb7373737bbccc33cb7373737bbccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
c33bb33333bbb33c333bb37373bbb333c33bb33333bbb33300000000000000000000000000000000000000000000000000000000000000000000000000000000
cc33bb737bbb33cc3c33bb737bbb33c3cc33bb737bbb33c300000000000000000000000000000000000000000000000000000000000000000000000000000000
3cc33bbbbbb33cc3ccc33bbbbbb33cccccc33bbbbbb33cc300000000000000000000000000000000000000000000000000000000000000000000000000000000
333ccbbbbbbcc333333ccbbbbbbc333c333ccbbbbbbc333300000000000000000000000000000000000000000000000000000000000000000000000000000000
cc33333bb33333cc3c33333bb3333c333c33333bb3333ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
c499e4ccc499e4ccc77977cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9494eecc9494eec7079707c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
977977ee977977ee7779777e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
907907ee907907ee999999ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999ee999999ee999899ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
998899ee998899ee999999ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cecece8ccececceccecececc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8c8cc8c8c8c88c88c8c8c8cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccqqq3ccccq3ccccccq3q3ccccqqq3cccccqq3cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccq333ccccq3ccccccq3q3cccc3q33ccccq333cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccqq3cccccq3ccccccq3q3cccccq3cccccqqq3cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccq33cccccq3ccccccqqq3cccccq3ccccc33q3cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccqqq3ccccqqq3cccc3q33ccccqqq3ccccqq33cccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc3333cccc3333ccccc33ccccc3333cccc333ccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccacaccccccaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccca9a9cccca999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccca9a9ccccaaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa9cccc99a9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9a99ccccaa99cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc99ccccc999ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc888ccccc88cccccc8c8ccccc888ccccc88cccccc888ccccc888cccccc88ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc2822cccc828ccccc8282cccc8282cccc828ccccc8222cccc8282cccc8222cccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc82ccccc8282cccc8282cccc8882cccc8282cccc88cccccc8822cccc888ccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc82ccccc8282cccc8882cccc8282cccc8282cccc822ccccc828ccccc2282cccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc888ccccc8282cccc2822cccc8282cccc8882cccc888ccccc8282cccc8822cccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc2222cccc2222ccccc22ccccc2222cccc2222cccc2222cccc2222cccc222ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc777cc77cc77c7c7ccccc777c7c7c777cc77ccccc7c7c777c7c7cccccc77777cccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc7d7d7d7d7ddd7d7dccccd7dd7d7dd7dd7dddcccc7d7d7d7d7d7dcccc77dd777ccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc77dd7d7d7dcc77ddccccc7dc777dc7dc777ccccc7d7d777d777dcccc77dcd77dcccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc7d7c7d7d7dcc7d7cccccc7dc7d7dc7dcdd7dcccc777d7d7ddd7dcccc77dc777dcccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc7d7d77ddd77c7d7dccccc7dc7d7d777c77ddcccc777d7d7d777dccccd77777ddcccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccdddddddccdddddddcccccddcdddddddddddcccccddddddddddddcccccddddddccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00c0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0f0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfff99ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccff999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000999ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000009cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00c0000c0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00f00f0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4c7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfcc7cc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccffc77ccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0ccc00ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00cc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000505000000505000050500000050500005050000005050000505000000505000050500000050500005050000005050000505000000505000050500000050
55005050500000555500505050000055550050505000005555005050500000555500505050000055550050505000005555005050500000555500505050000055
55005555500050005500555550005000550055555000500055005555500050005500555550005000550055555000500055005555500050005500555550005000
00000555500555000000055550055500000005555005550000000555500555000000055550055500000005555005550000000555500555000000055550055500
00005555000555000000555500055500000055550005550000005555000555000000555500055500000055550005550000005555000555000000555500055500
66660000060000006666000006000000666600000600000066660000060000006666000006000000666600000600000066660000060000006666000006000000
55550066550665065555006655066506555500665506650655550066550665065555006655066506555500665506650655550066550665065555006655066506
55555006550655065555500655065506555550065506550655555006550655065555500655065506555550065506550655555006550655065555500655065506
55555500000055065555550000005506555555000000550655555500000055065555550000005506555555000000550655555500000055065555550000005506
55555500666600065555550066660006555555006666000655555500666600065555550066660006555555006666000655555500666600065555550066660006
55555506555500065555550655550006555555065555000655555506555500065555550655550006555555065555000655555506555500065555550655550006
55555506555500005555550655550000555555065555000055555506555500005555550655550000555555065555000055555506555500005555550655550000
00555006555500000055500655550000005550065555000000555006555500000055500655550000005550065555000000555006555500000055500655550000
00000000555006660000000055500666000000005550066600000000555006660000000055500666000000005550066600000000555006660000000055500666
55000660000006555500066000000655550006600000065555000660000006555500066000000655550006600000065555000660000006555500066000000655
55506555500006555550655550000655555065555000065555506555500006555550655550000655555065555000065555506555500006555550655550000655
55006555500006555500655550000655550065555000065555006555500006555500655550000655550065555000065555006555500006555500655550000655
55065555506600555506555550660055550655555066005555065555506600555506555550660055550655555066005555065555506600555506555550660055
55065555506550005506555550655000550655555065500055065555506550005506555550655000550655555065500055065555506550005506555550655000
00006555500555000000655550055500000065555005550000006555500555000000655550055500000065555005550000006555500555000000655550055500
00005555000555000000555500055500000055550005550000005555000555000000555500055500000055550005550000005555000555000000555500055500
66660000060000006666000006000000666600000600000066660000060000006666000006000000666600000600000066660000060000006666000006000000
55550066550665065555006655066506555500665506650655550066550665065555006655066506555500665506650655550066550665065555006655066506
55555006550655065555500655065506555550065506550655555006550655065555500655065506555550065506550655555006550655065555500655065506
55555500000055065555550000005506555555000000550655555500000055065555550000005506555555000000550655555500000055065555550000005506
55555500666600065555550066660006555555006666000655555500666600065555550066660006555555006666000655555500666600065555550066660006
55555506555500065555550655550006555555065555000655555506555500065555550655550006555555065555000655555506555500065555550655550006
55555506555500005555550655550000555555065555000055555506555500005555550655550000555555065555000055555506555500005555550655550000
00555006555500000055500655550000005550065555000000555006555500000055500655550000005550065555000000555006555500000055500655550000
00000000555006660000000055500666000000005550066600000000555006660000000055500666000000005550066600000000555006660000000055500666
55000660000006555500066000000655550006600000065555000660000006555500066000000655550006600000065555000660000006555500066000000655

__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213121312131213121312131213121312131213121312131213121312131213121312131213121312131213121312131213121312131213121312131213121312131213121300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2223222322232223222322232223222322232223222322232223222322232223222322232223222322232223222322232223222322232223222322232223222322232223222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3233323332333233323332333233323332333233323332333233323332333233323332333233323332333233323332333233323332333233323332333233323332333233323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001000001d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00200504300203006150020304665046150020300615050430020300615002030466504615002030061505043002030061500203046650461500203006150504300203006150020304665046150020300615
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00200015500115001550011503155031150015500115001550014500115001550315503115001150015500155001150015500115031550311500155001150015500145001150015503155031150011500155
010e00000515505115051550511508155081150515505115051550514505115051550815508115051150515505155051150515505115081550811505155051150515505145051150515508155081150511505155
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000013145131451f14513145131452914513145131452714513145131451f1451d1451b1451d1451314513145131451f14513145131452914513145131452714513145131451f1451d1451b1451d14513145
010e000018145181452414518145181452e14518145181452c1451814518145241452214520145221451814518145181452414518145181452e14518145181452c14518145181452414522145201452214518145
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100020305423052230512005022b5422b5140050200502305422b542305422b541005020050200502005022754227512275422751224542245122454224512225462251622542225121b5411b5121d5411d542
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00000015500115001550011503155031150015500115051550511507155071150515505115071550711500135001350015500115031550311500155001150515505115071550711505155051150715507115
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0112002037552345522d55237552345522d55237552345522d55237552345522d5512d5512b551395510050237552345522d55237552345522d55237552345522d55237552345522d5512d5512b5513955100502
__music__
01 10484344
01 11484344
01 10085844
02 11084344
00 41424344
00 41424344
00 41424344
00 41424344
00 08424344
00 0a070b44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41420d44

