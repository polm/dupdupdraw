"""
First take - like a shader, a function is called once for each point. 
The three values at the top of the stack become r g b.

Builtins: x y t (time) */+- sqrt exp dup drop

"""

is-func = -> \function == typeof it
is-num  = -> not isNaN it

class Parser
  (@x=0, @y=0, @t=0) ~>
    @s = [] # stack
    @mapping = {
      "+": \plus
      "-": \minus
      "*": \mult
      "/": \div
      "%": \mod
      "^": \exp
      ">": \greater-than
      "<": \greater-than
    }

  l: ~> @s[*-1]

  push: ~>
    if is-num it
      @s.push it
    else @s.push 0

  pop: ~> @s.pop!

  dup: ~> @push @l!
  dot: ~> @pop!
  sqrt: ~> @push Math.sqrt @pop!
  plus: ~> @push (@pop! + @pop!)
  minus: ~> a = @pop!; b = @pop!; @push b - a
  mult: ~> @push (@pop! * @pop!)
  div: ~> a = @pop!; b = @pop!; @push b / a
  mod: ~> a = @pop!; b = @pop!; @push b % a
  exp: ~> a = @pop!; b = @pop!; @push Math.pow b, a
  swap: ~> a = @pop!; b = @pop!; @push a; @push b
  greater-than: ~> a = @pop!; b = @pop!; @push ~~(b > a)
  less-than: ~> a = @pop!; b = @pop!; @push ~~(b < a)
  dist: ~> yy = @pop!; xx = @pop!; @push ~~Math.sqrt( ((@x - xx)^2) + ((@y - yy)^2))

  rgb: ~>
    b = @pop! or 0
    g = @pop! or 0
    r = @pop! or 0
    return [r, g, b]

  rgba: ~>
    a = @pop! or 0
    b = @pop! or 0
    g = @pop! or 0
    r = @pop! or 0
    return [r, g, b, a]

  parse: (code) ~>
    words = code.split ' '
    for word in words
      if word == '' then continue
      if @mapping[word] then word = @mapping[word]
      if @[word] or @[word] == 0
        if is-func @[word] then @[word]!
        else @push @[word] # x, y, t
      else if is-num word then @push (+word)
      else
        @mapping[word] = ~(255 * Math.random!)
        @push @mapping[word]
        #@push ~~(255 * Math.random!) # no errors, just noise

window.Parser = Parser
canvas = document.query-selector(\canvas)
ctx = canvas.get-context \2d
window.render = ->
  p = new Parser
  width = canvas.width
  height = canvas.height
  for xx from 0 til width
    for yy from 0 til height
      p.x = xx; p.y = yy
      p.parse it
      [r, g, b] = p.rgb!
      ctx.fill-style = "rgb(#r, #g, #b)"
      ctx.fill-rect xx, yy, 1, 1
      p.s = [] # reset the stack

# this is cool: 
# y x 64 / * y x 64 / * 255 - 128 mod 64 + 0
# 128 > * < * 256 y - - sqrt
# sqrt 256 dup dup sqrt swap y % + dup
# y sqrt < + 64 sqrt * 128 128 -
# > < 64 > y y 64 % - <
# < + x dist y y + % y %
# - sqrt 256 < 64 x + dist y 64 64 64 > x y 256 - % > 16
# 16 0 16 128 0 x 256 sqrt x x x 64 dist > + 256 128 > - y sqrt - 128 < dist
# 16 0 16 128 256 % 64 128 > 16 + > dist x x > 128 + y dist dist % % > x
# 512 256 128 256 256 - < 256 128 128 dist 128 + x dist 256 x + dist > 128 sqrt % 64 +
# 16 0 256 128 0 - 128 sqrt % sqrt sqrt 128 128 128 % + dist 16 64 % x x 64 128 -
# 256 512 16 256 0 16 dist + + + dist 64 128 64 y dist > - 16 dist 256 dist % + 64
# 256 256 16 0 512 - 128 256 + % x - dist % 128 x > % > % dist x dist - dist
# 128 0 256 256 512 y 16 x % + x 256 x < 64 dist - < % 256 < x 128 16 > 256 > sqrt y 256 % x 256 % y % % y y 256 dist

nums = <[ 0 16 128 256 512 ]>
vocab = <[ 16 64 128 256 x y < > + - % sqrt dist ]>

R = -> ~~(it * Math.random!)
pick = -> it[R(it.length)]

# With image, twitter takes up to 117 characters
window.random-prog = ->
  prog = ''
  for ii from 0 til 5 # first seed the stack
    prog += ' ' + pick nums
  #for ii from 0 til 20 # now mix in operations
  while prog.length < 112
    prog += ' ' + pick vocab
  console.log prog
  return prog

window.layers = ->
  ctx.global-alpha = 1
  ctx.fill-style = '#fff'
  ctx.fill-rect 0, 0, canvas.width, canvas.height
  ctx.global-alpha = 0.2
  for ii from 0 til 5
    render random-prog!
