pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

--- vars

--
-- game
--

function _init()

end

function _update()
  player_move()
end

function _draw()
 cls()
 map_display()
 player_display()
 camera_follow()
 print_debug()

end


-->8

--
-- players
--

player = 1
sprite_start = (player == 1) and 1 or 17

velx = 0
vely = 0
vel_max = 3
vel_ths = .3
friction = .8

pos = { x = 30, y = 30}

running = false
flipped = false

animate = 0


function player_move()
  if( btn(0) ) then velx -= 1 end
  if( btn(1) ) then velx += 1 end
  if( btn(2) ) then vely -= 1 end
  if( btn(3) ) then vely += 1 end


  if (abs(velx) < vel_ths) velx = 0
  if (abs(vely) < vel_ths) vely = 0

  -- move
  ok = fget(mget(flr(pos["x"] + velx)/8, flr(pos["y"] + vely)/8), 1)

  --debug[0] = mget(pos["x"] + velx, pos["y"] + vely)

  if ok then
    pos["x"] += velx
    pos["y"] += vely
  end

   -- friction
   velx *= friction
   vely *= friction
end

function player_display()
  sprite = running and sprite_start + 1 or sprite_start
  spr(sprite, pos["x"], pos["y"], 1, 1, flipped)
end


-->8

---
--- map
---

function map_display()
  map(0,0,0,0,128,128)
end


---
--- camera
---

camx = pos["x"] - 64
camy = pos["y"] - 64
stiffness = .1

function camera_follow()

   camx += ((pos["x"]-64) - camx) * stiffness
   camy += ((pos["y"]-64) - camy) * stiffness
   camera(camx, camy)
end





-->8

--
-- utilities
--

-- debug
debug = {}

function print_debug()
  for i in all(debug) do
    print(debug[i])
    printh(debug[i])
  end
end


-- dark
dpal={0,1,1,2,1,13,6,2,4,9,3,13,5,2,9}
function dark(l)
 l=l or 0
 if l>0 then
  for i=0,15 do
   col=dpal[i] or 0
   for a=1,l-0.5 do
    col=dpal[col]
   end
   pal(i,col)
  end
 end
end




__gfx__
000000000009990000099900000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
00000000009fff900099ff90000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
007007000993f30009993f00000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
00077000999fff000999ff00000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
00077000099888f0009888f0000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
007007000009f80000088f00000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
000000000008880000088800000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
000000000005050000005500000000000000000000000000000000000000000000000000ddddddddffffffff0000000000000000000000000000000000000000
__gff__
0000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0a09090a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0a09090a0a0a0a0a0a0a000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000909090909090909090909000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000090909090909090909090900090909090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000090909090909090909090909090909090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000090909090909090909090909090909090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000090909090909090909090900090909090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000090909090909090909090900090909090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000090900000000000000090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000a0a0a0a0a09090a0a0a0a00000a09090a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000a0a0a0a0a09090a0a0a0a00000a09090a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000909090909090909090909000009090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000180500e0500e0500e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000080025000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000040000000000134110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01024344

