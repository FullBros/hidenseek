pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

tick = 0
max_tick = 32
animate_each = 4

function _init()
  --pal(0,false)
  --pal(12,true)

  graphics.palette()

  poke(0x5f42, 0b0000) --distort
  poke(0x5f41, 0b0100) --echo
  poke(0x5f43, 0b1111) --lowpass


  -- first level
  game.level = levels[1]

  -- new hero
  elvis = hero:new({ x = 62, y = 104})
  rachel = dog:new({ x = elvis.x + 100, y = elvis.y+4})


  music(0) -- go music!
end


delay_shoot = 0

function _update()

  tick = (tick + 1) % max_tick
  delay_shoot += 1

  if (not game.pause) then
    game.level:update()
    elvis:update()
    for b in all (bullets) do b:update() end
    for a in all (aliens)  do a:update() end
    play_music()
  end

  rachel:update()

end



function _draw()

  cls()
  palt(0,false) -- use dark in sprites


  graphics.background(elvis.hard)

  palt(12, true) -- use cyan in map
  map(0,0,0,0,128,128)
  palt(12, true) -- but not for characters


  elvis:draw()

  for a in all (aliens)  do a:draw() end
  for b in all (bullets) do b:draw() end

  rachel:draw()

  cam:update()
  --print(elvis.x, cam.x, cam.y)


  graphics.infos()
  game.level:draw()

  --debug.log(game.level.number)
  debug.show ()

  --graphics.dialog({"elvis, you good?", "i feel some kind of", "tension"})

end



--
-- game
--

game = {}
game.level = nil
game.pause = false
game.infos = false -- lives & level
game.debug = false

game.max_lives = 3
game.lives = 3



--
-- entities
--

entity = {}
entity.x = 0
entity.y = 0
entity.width = 8
entity.height = 8
entity.flip = false

entity.animation = {} -- current animation
entity.animations = {} -- all animations

entity.sprite_first = 0 -- first sprite number in spritesheet
entity.sprite_size = 1

-- get the correct sprite according to animation
function entity:get_sprite()

  local sprite

  self.previous_animation = self.previous_animation or {}
  self.step = self.step or 1 -- step on the current animation

  if (self.animation != self.previous_animation) then
    self.step = 1 -- new animation ? restart from beginning
    self.previous_animation = self.animation
  end

  -- get sprite position
  sprite = self.sprite_first + (self.animation[self.step] * self.sprite_size)

  -- for hero & double size sprite, skip a line for each new row
  sprite = sprite + ((self.animation[self.step]  < 8) and 0 or 16) + --saut de ligne
          ((self.animation[self.step]  < 16) and 0 or 16) --saut de ligne

  if (tick % animate_each == 0) self.step = (self.step % #self.animation) + 1

  return sprite
end


-- get default hitbox
function entity:hitbox()
  return {
    x = self.x - self.width/2,
    y = self.y - self.height/2,
    width  = self.width,
    height = self.height,
  }
end


-- draw the sprite
function entity:draw()

  -- show hitbox
  if game.debug then
    hitbox = self:hitbox()
    rect(hitbox.x, hitbox.y, hitbox.x + hitbox.width, hitbox.y + hitbox.height, 11)
  end

  spr( self:get_sprite(),
       self.x - self.width/2,
       self.y - self.height/2,
       self.sprite_size, self.sprite_size,
       self.flip)
end


--
-- hero
--

hero = {}
hero.__index = hero
setmetatable(hero, {__index = entity})

hero.width = 12
hero.height = 16
hero.speed = 2
hero.hard = false

hero.sprite_first = 64 --first position in sprite sheet
hero.sprite_size = 2

hero.animations = {
  idle = {0,1},
  walk = {2,3,4,5,6,4},
  ready = {7,8},
  right = {9,10,11},
  diagonal = {12,13,14},
  up = {15,16,17},
}
hero.animation = hero.animations.idle



function hero:new (object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end


function hero:update()

  -- check aliens collisions
  for a in all(aliens) do
    if collision(self:hitbox(), a:hitbox()) then
      game.lives -= 1
      a:delete()
    end
  end

  local special = controls:special()
  elvis.animation = elvis.animations.idle
  elvis.hard = false

  if controls:ready() then
    elvis.animation = elvis.animations.ready

    if (controls:left() or controls:right()) then elvis.animation = elvis.animations.right end
    if (controls:up()) then elvis.animation = elvis.animations.up end
    if controls:diagonal() then elvis.animation = elvis.animations.diagonal end

    local direction = controls:direction()
    if (direction > 0 and delay_shoot > 10) then
      add(bullets, bullet:create(elvis.x, elvis.y, direction))
      delay_shoot = 0
    end


  -- moves
  else

    if (btn(0) or btn(1)) elvis.animation = elvis.animations.walk

    --moves
    local vx = 0
    if (controls:left())  vx = -elvis.speed
    if (controls:right()) vx = elvis.speed

    -- level boundaries
    local hitbox = elvis:hitbox()
    if (hitbox.x + vx < game.level.limits[1]) vx = 0 -- left
    if (hitbox.x + hitbox.width + vx > game.level.limits[2]) vx = 0 -- right
    --posx = min(self.x + self.width/2 + posx, game.level.limits[2]) -- left

    -- move
    self.x += vx;
  end

  -- flip sprite
  if (btn(0)) elvis.flip = true
  if (btn(1)) elvis.flip = false

end


--
-- dog
--

dog = {}
dog.__index = dog
setmetatable(dog, {__index = entity})

dog.speed = 1
dog.sprite_first = 240
dog.sprite_size = 1

dog.animations = {
  idle = {0,1},
  running = {0,2}
}

dog.animation = dog.animations.idle
dog.show = true


function dog:new (object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end

function dog:update()
  local target

  self.animation = self.animations.idle

  if ( abs(self.x - elvis.x) > 16) then
    self.animation = self.animations.running
    self.flip = (elvis.x > self.x)
    self.x += (self.flip) and self.speed or -self.speed
  end
end

function dog:draw ()
  if (not self.show) return
  entity.draw(self) -- parent method
end


---
--- aliens
---

aliens = {} -- all aliens
alien = {}
alien.__index = alien
setmetatable(alien, {__index = entity})

alien.speed = .5
alien._hit = false
alien._die = false
alien.countdown = 3

alien.sprite_first = 224 --first position in sprite sheet
alien.animations = {
  fly = {0,1},
  die = {2}
}
alien.animation = alien.animations.fly




function alien:new (object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end

-- alias for constructor
function alien:create (x, y)
  return self:new({x = x, y = y})
end


function alien:update ()

  local target = {}
  target.x = elvis.x + 4
  target.y = elvis.y + 4


  local d = distance(self, target)
  vx = (target.x - self.x) * self.speed / d
  vy = (target.y - self.y) * self.speed / d

  self.x += vx
  self.y += vy

  -- if (target.x > self.x) self.x+= self.speed
  -- if (target.x < self.x) self.x-= self.speed
  -- if (target.y > self.y) self.y+= self.speed
  -- if (target.y < self.y) self.y-= self.speed

  self.flip = (elvis.x > self.x)


  if (self._die) self.countdown -= 1
  if (self.countdown == 0) self:delete()

end

function alien:hit()
  self._hit = true
  self.animation = self.animations.die
  self.countdown=8
end

function alien:delete()
  del(aliens, self)
end


function alien:draw()

  if (self._hit) then
    graphics.white()
    self._die = true
    self._hit = false
  end

  -- draw alien
  entity.draw(self)

  graphics.palette()

end



--
-- bullet
--

bullets = {} -- all bullets
bullet = {}
bullet.__index = bullet
setmetatable(alien, {__index = entity})


bullet.radius = 1
bullet.direction = direction
bullet.speed = 3
bullet.alternate = false


function bullet:new (object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end


function bullet:create (x, y, direction)
  return self:new({x = x, y = y, direction = direction})
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

  -- move
  self.x += x
  self.y += y

  self:collision()

end


function bullet:collision ()
  for a in all(aliens) do
    if collision(self:hitbox(), a:hitbox()) then
      a:hit()
      self:delete()
    end
  end
end


function bullet:hitbox()
  return {
    x = self.x - 1,
    y = self.y,
    width  = 2,
    height = 2,
  }
end

function bullet:delete()
  del(bullets, self)
end

function bullet:draw ()

  -- debug bullet hitbox
  if game.debug then
    hitbox = self:hitbox()
    rect(hitbox.x, hitbox.y, hitbox.x + hitbox.width, hitbox.y + hitbox.height, 11)
  end

  --alt color
  self.alternate = not self.alternate

  --local c = (self.color == 1) and 14 or 9
  --color(c)
  --circfill(self.x, self.y, self.radius)
  --circfill(self.x, self.y, self.radius - 1)

  local sprite = self.alternate and 17 or 33
  palt(0, true)
  spr(sprite, self.x-3, self.y-2)
  palt(0, false)
end







--
-- levels
--

levels = {}
level = {}
level.__index = level

-- function level:new (object)
--   object = object or {}
--   setmetatable(object, self)
--   self.__index = self

--   add(levels, object)
--   return object
-- end






function level:create (n, limits, init, update, draw)

  l = {}
  setmetatable(l, level)

  l.number = n
  l.limits = limits
  l.checkpoint = nil

  -- functions
  l.init = init
  l.update = update
  l.draw = draw


  return l
end

function level:next()

  -- checkpoint to the next level
  if not self.checkpoint then
    self.checkpoint = self.limits[2] + 64
    self.limits[2] += 127 -- let walk right
  end

  if (elvis.x > self.checkpoint) then
    del(levels, self)
    game.level = levels[1]
    game.level:init()
  end
end


-- first level
add(levels, level:create(
  0,
  {0, 128},

  -- init
  function (self)
  end,

  -- update
  function (self)
    self:next()
  end,

  -- draw
  function (self)
    graphics.title()
    graphics.tip("rock this way ➡️", 0, 12)
  end
))






add(levels, level:create(
  1,
  {128, 256},

  -- init
  function (self)
    self.tutorial = true
    self.message = ""
  end,

  -- update
  function (self)

    if self.tutorial then
      if (elvis.animation != elvis.animations.ready) self.message = "press 🅾️ or c to get ready"
      if (elvis.animation == elvis.animations.ready) self.message = "...and use direction to aim"
    end

    if (guitar.playing) then
      self.message = "you got it, elvis! ➡️"
      self.tutorial = false
      game.infos = true
    end

    if (not self.tutorial) self:next()

  end,

  -- draw
  function (self)
    graphics.tip(self.message, cam.x)
  end
))




add(levels, level:create(
  2,
  {256,384},

  -- init
  function (self)
      self.message = ""

      add(aliens, alien:create(elvis.x - 80, elvis.y + 4))
      add(aliens, alien:create(elvis.x + 100, elvis.y + 4))
      add(aliens, alien:create(elvis.x, -60))
      add(aliens, alien:create(elvis.x -90,  -30))
      add(aliens, alien:create(elvis.x +100, -40))
  end,

  -- update
  function (self)
    if (#aliens == 0) then
      self:next()
      self.message = "that was an easy one ➡️"
    end
  end,

  -- draw
  function (self)
    graphics.tip(self.message, cam.x)
  end
))


add(levels, level:create(
  3,
  {384,512},

  -- init
  function (self)

      self.message = ""

      add(aliens, alien:create(elvis.x - 80, elvis.y))
      add(aliens, alien:create(elvis.x - 100, elvis.y))
      add(aliens, alien:create(elvis.x + 90, elvis.y))
      add(aliens, alien:create(elvis.x + 110, elvis.y))
      add(aliens, alien:create(elvis.x, -60))
      add(aliens, alien:create(elvis.x -80,  -20))
      add(aliens, alien:create(elvis.x -90,  -30))
      add(aliens, alien:create(elvis.x -110, -40))
      add(aliens, alien:create(elvis.x +100, -40))
  end,

  -- update
  function (self)
    if (#aliens == 0) then
      self:next()
      self.message = "well done! ➡️"
    end
  end,

  -- draw
  function (self)
    graphics.tip(self.message, cam.x)
  end
))




add(levels, level:create(
  4,
  {512,640},

  -- init
  function (self)

    self.step = 0
    self.steps = {
      ennemies = 0,
      animation = 1,
      dialog = 2,
    }

    self.dialog = nil

    local ennemies = {
      {-100, 0}, {-110, 0}, {-120, 0}, {-130, 0}, {-140, 0},
      {100, 0}, {110, 0}, {120, 0}, {130, 0}, {140, 0},
      {0, -100}, {0, -110}, {0, -120}, {0, -130}, {0, -140},
      {-90, -90}, {-95, -95}, {-100, -100}, {-105, -105}, {-110, -110},
      {90, -90}, {95, -95}, {100, -100}, {105, -105}, {110, -110}
    }

    for e in all(ennemies) do
      add(aliens, alien:create(elvis.x + e[1], elvis.y + e[2]))
    end

    --elvis.animation = elvis.animations.idle
    --game.pause = true

  end,


  -- update
  function (self)

    for a in all(aliens) do
      if (distance(elvis, a) < 40) then
          self.step = self.steps.animation
        end
    end

    if (self.step == self.steps.animation) then
        elvis.animation = elvis.animations.ready
        elvis.flip = false
        game.pause = true
        music(-1)
        rachel.animation = rachel.animations.running
        rachel.x = elvis.x + 100
        rachel.show = true
    end


    if (self.step == self.steps.animation and abs(rachel.x - elvis.x) < 20) then
      self.step = self.steps.dialog
    end

    if (self.step == self.steps.dialog) then
      self.dialog = {"elvis, you good?", "look tense"}
    end



  end,

  -- draw
  function (self)
    if (self.dialog != nil) graphics.dialog(self.dialog)
  end
))







--
-- dialog
--

dialog = {}
dialog.__index = dialog

function dialog:create ()

  d = {}
  setmetatable(d, dialog)
  return d
end

-- text or table (multiline)
function dialog:add (text)


end


---
--- graphics
---

graphics = {}
graphics.timer = 0


function graphics.palette ()
  for i=0,15 do pal(i, i) end
  pal(11,128+10,1) --use lime green
end

-- draw in white (for hits)
function graphics.white()
  for i=0,15 do pal(i, 7) end
end

function graphics.title ()

  local top = 30

  -- shadow
  color(3)
  text:center("e l v i s", top, 0, 1)
  text:center("e l v i s", top, 1, 1)
  --text:center("e l v i s", top, 1, 0)

  color(11)
  text:center("e l v i s", top)


  color(9)
  text:center("v s", top + 11, 0, 1)
  text:center("v s", top + 11, 1, 1)

  color (10)
  text:center("v s", top + 11)

  color(2)
  text:center("i n v a d e r s", top + 22, 0, 1)
  text:center("i n v a d e r s", top + 22, 1, 1)

  color(8)
  text:center("i n v a d e r s", top + 22)

  color(0)
end


function graphics.infos (offy)

  if (not game.infos) return

  local x,y = cam.x, cam.y
  offy = offy or 0

  --rectfill(x, y, x + 128, y + 8, 12)

  palt(0, true)

  -- display lives
  for i=1,game.max_lives do
    local sprite = (i <= game.lives) and 2 or 18
    spr(sprite,x + 3 + 9*(i-1),y + offy)
  end


  palt(0, false)


  local level = "level " .. game.level.number
  print(level, x + 128 - (#level)*4 - 4, y+2, 7)
end


function graphics.tip (t, offx, offy)
  offx = offx or 0
  offy = offy or 0

  -- shadow()
  color(13)
  text:blink(t, offy + 54, offx, 1)
  text:blink(t, offy + 54, offx + 1, 1)

  color(7)
  text:blink(t, offy + 54, offx)
end


function graphics.dialog (text)

  text = (type(text) == "table") and text or {text}

  local height = (#text + 1) * 9 + 8

  rrectfill(cam.x + 5, cam.y + 5, cam.x + 128 - 5, cam.y + height + 5, 1, 3)
  rrectfill(cam.x + 6, cam.y + 6, cam.x + 128 - 6, cam.y + height + 4, 7, 3)

  for i, t in ipairs(text) do
    print(text[i], cam.x + 10, cam.y + 5 + 5+(i-1)*9, 1)
  end

  print("press ❎", cam.x + 10, 4 + 9*(#text+1), 12)
end



function graphics.background (hard)

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
-- music
--

sound = {}

sound.basslines = {5,6}
sound.drums = {0,1}


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
-- controls
--

controls = {}
controls.sequence = {0}
controls.specials = {
  {3, 7, 3, 7, 1, 1, 5, 5} -- hard mode
}

function controls:direction()

    local direction = 0
    if (btn(0)) direction = 1
    if (btn(1)) direction = 5
    if (btn(2)) direction = 3
    if (btn(0) and btn(2)) direction = 2
    if (btn(1) and btn(2)) direction = 4

    return direction
end

function controls:left()
  return self:direction() == 1
end

function controls:right()
  return self:direction() == 5
end

function controls:up()
  return self:direction() == 3
end

function controls:diagonal()
  return self:direction() == 2 or self:direction() == 4
end

function controls:ready()
  return btn(4)
end

function controls:special()

  -- add current control to the sequence if different
  if (self.sequence[#self.sequence] != self:direction()) then
     add(self.sequence, self:direction())
  end

  --debug.log(tabletostr(self.sequence))
end


function tabletostr (table)
  local str = ""
  for v in all(table) do str = str .. v end
  return str
end


  -- elvis.animation = elvis.animations.idle
  -- elvis.hard = false

  -- if btn(4) then
  --   elvis.animation = elvis.animations.ready

  --   if (btn(0) or btn(1)) elvis.animation = elvis.animations.right
  --   if (btn(2)) elvis.animation = elvis.animations.up



  --   if (direction > 0 and delay_shoot > 10) then
  --     add(bullets, bullet:create(elvis.x, elvis.y, direction))
  --     delay_shoot = 0
  --   end


  -- -- moves
  -- else

  --   if (btn(0) or btn(1)) elvis.animation = elvis.animations.walk

  --   --moves
  --   local vx = 0
  --   if (btn(0)) vx = -elvis.speed
  --   if (btn(1)) vx = elvis.speed


  --   -- move
  --   self.x += vx;
  -- end










--
-- camera
--

cam = {}
cam.x = 0
cam.y = 0
cam.threeshold = 5
cam.speed = 2

function cam:update()

  local target = {}

  target.x = elvis.x - 64 -- to elvis position
  --target.x = max(target.x, 0 - cam.threeshold) -- left boundary

  -- level boundaries
  c = game.level

  target.x = max(target.x, c.limits[1]) --left
  target.x = min(target.x, c.limits[2] - 128) -- right

  local direction = (cam.x < target.x) and 1 or -1
  local dx = min(cam.speed, abs(target.x - cam.x))

  if abs(cam.x - target.x) > cam.threeshold then
    cam.x += dx * direction
  end

  camera(cam.x, cam.y)
end






--
-- utils
--

debug = {}
debug.logs = {}

function debug.log (text)
  add(debug.logs, text)
end

function debug.show ()

  if (not game.debug) return

  color(7)
  local line = 0
  for m in all(debug.logs) do
    print(m, cam.x+10, cam.y + line * 8)
    line += 1
  end

  debug.logs = {}
end



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



function collision (o1, o2)

  return (o1.x < o2.x + o2.width and
   o1.x + o1.width > o2.x and
   o1.y < o2.y + o2.height and
   o1.y + o1.height > o2.y)

end



function distance (p1, p2)

   local dx = (p2.x-p1.x)/64
   local dy = (p2.y-p1.y)/64

   -- get distance squared
   local dsq = dx*dx+dy*dy

  -- in case of overflow/wrap
  if(dsq<0) return 32767.99999

-- scale output back up by 6 bits
  return sqrt(dsq)*64
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

-- round rectangle
function rrectfill(x0, y0, x1, y1, col, radius)
  local radius = radius or 0

  local new_x0 = x0 + radius
  local new_y0 = y0 + radius
  local new_x1 = x1 - radius
  local new_y1 = y1 - radius

  rectfill(new_x0, new_y0, new_x1, new_y1, col)

  if radius > 0 then
    circfill(new_x0, new_y0, radius, col)
    circfill(new_x1, new_y0, radius, col)
    circfill(new_x0, new_y1, radius, col)
    circfill(new_x1, new_y1, radius, col)
  end

  rectfill(new_x0, y0, new_x1, new_y0, col)
  rectfill(x0, new_y0, new_x0, new_y1, col)
  rectfill(new_x1, new_y0, x1, new_y1, col)
  rectfill(new_x0, new_y1, new_x1, y1, col)
end





__gfx__
00000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc0e80e80000000000500005050000005000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccce88e888000000000550050505000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccce888888000000000550055555000500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc0888880000000000000005555005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccc0088800000000000000055550005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc0008000000000000666600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc0000000000000000555500665506650600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555550065506550600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000110110000000000555555000000550600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000900001111111000000000555555006666000600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009e90001111111000000000555555065555000600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000900000111110000000000555555065555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000011100000000000005550065555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001000000000000000000005550066600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000550006600000065500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000500005050000005000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000e0e0000000000000000000550050505000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000900000000000000000000550055555000500000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000e0e0000000000000000000000005555005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055550005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555500665506650600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555550065506550600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555000000550600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555006666000600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555065555000600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555065555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005550065555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550066600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000550006600000065500000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccc0ccccccccccccccccccccccccccccccccccccccccccccccc0cccccccccccccccccccccccccccccc0cccccccc
cccccc00c0cccccccccccc00c0cccccccccccc00cccccccccccccccccccccccccccccccccc0ccccccccccc00ccccccccccccccccccccccccccccc00ccccccccc
cccccc0f0ccccccccccccc0f0ccccccccccccc0f0ccccccccccccc0000cccccccccccccc00cccccccccccc0f0ccccccccccccc0000ccccccccccc0f0cccccccc
ccccccfff99cccccccccccfff99cccccccccccfffccccccccccccc0f0ccccccccccccccc0f0cccccccccccfffccccccccccccc0f0ccccccccccccfffcccccccc
cccccccff999cccccccccccff999ccccccc999cffcccccccccccccfffcccccccccccccccfffccccccccccccffcccccccccccccfffccccccccccc00ffcccccccc
ccccc00000999cccccccc00000999cccccc9400000ccccccccc9990ffcccccccccccc9900ffccccccccc900000cccccccccc990ffcccccccccc000000ccccccc
cccc00000009cccccccc00000009ccccccc9000000ccccccccc9000000ccccccccccc90000cccccccccc000000cccccccccc900000cccccccc00c00000cccccc
ccc000000000ccccccc000000000ccccccc90000000fccccccc00900000ccccccccc990000ccccccccc9000000cccccccccc0000000ccccccc099909c00ccccc
ccc00c0000c0ccccccc00c0000c0ccccccc900000cccccccccc009000c00fccccccc9490000cccccccc90000000fcccccccc00000000fccccc009999cc0ccfcc
cccc00f00f0ccccccccc00f00f0ccccccccc40f0ccccccccccc90f00cccccccccccc4490000fccccccc44000cccccccccccc9000cccccccccc90ff44444f4ffc
ccccc4777cccccccccccc4777ccccccccccc4c77cccccccccccc4c77cccccccccccc4cc77cccccccccc4cc77ccccccccccccc476cccccccccc99f999cccccccc
cccc4c7777cccccccccc4c7777ccccccccccff677ccccccccccc4c677ccccccccccffcc777ccccccccffcc776cccccccccccc4776cccccccccc999797ccccccc
cccfcc7cc77ccccccccfcc7cc77cccccccccf76c77ccccccccccff677ccccccccccfcc77c7ccccccccfcc77c67cccccccccccf776cccccccccccc7cc77cccccc
ccffc77ccc7cccccccffc77ccc7cccccccccc7ccc7cccccccccc0067cccccccccccccc770cccccccccccc7ccc7cccccccccc0076cccccccccccc77ccc7cccccc
ccccc0ccc0ccccccccccc0ccc00ccccccccc00ccc0cccccccccc0cc0cccccccccccccc0ccccccccccccc00ccc0cccccccccc0cc0cccccccccccc0ccc0ccccccc
ccccc00cc00cccccccccc00cc0cccccccccc0cccc00cccccccccccc00ccccccccccccc00cccccccccccc0cccc00cccccccccccc00ccccccccccc00cc00cccccc
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
cccccccccccccccc55cc55cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55cc55cc55cc55cc567665cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
567665cc567665ccc06606cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c06606ccc06606ccc65666cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c65666dcc65666dcc5e566dc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5e56d6cc5e56d65cc666d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc666665cc666665c6c666c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc6c6d6ccc6c6d6ccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405040504050405
1415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415141514151415
__sfx__
001000001d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00200504300203006150020304655046150020300615050430020300615002030567504605002030061505043002030061500203046550461500203006150504300203006150020305675046050020300615
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
03 10424344
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

