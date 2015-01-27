"""
First take - like a shader, a function is called once for each point. 
The three values at the top of the stack become r g b.

Builtins: x y t (time) */+- sqrt exp dup drop

"""


is-func = -> \function == typeof it
is-num  = -> not isNaN it

write-png = (canvas) ->
  fs = require('fs')
  fname = 'images/dupdupdraw.' + (new Date!).toISOString! + '.png'
  out = fs.createWriteStream(__dirname + '/' + fname)
  stream = canvas.pngStream()

  stream.on 'data', -> out.write it
  stream.on 'end', -> console.log('saved png to ' + fname)

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
      ">": \greater
      "<": \less
      "sr": \sqrt
      "di": \dist
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
  greater: ~> a = @pop!; b = @pop!; @push ~~(b > a)
  less: ~> a = @pop!; b = @pop!; @push ~~(b < a)
  dist: ~> yy = @pop!; xx = @pop!; @push ~~Math.sqrt( ((@x - xx)^2) + ((@y - yy)^2))
  max: ~> @push Math.max(@pop!, @pop!)
  xl: ~> if @x < @pop! then \ok else @pop! and @push 0 # zero if not less than x
  xg: ~> if @x > @pop! then \ok else @pop! and @push 0
  yl: ~> if @y < @pop! then \ok else @pop! and @push 0
  yg: ~> if @y > @pop! then \ok else @pop! and @push 0
  sin: ~> @push ~~(256 * (Math.sin (@pop! / 256) * (Math.PI / 2)))

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
        @mapping[word] = ~~(255 * Math.random!)
        @push @mapping[word]
        #console.log "randomed: #word"
        #@push ~~(255 * Math.random!) # no errors, just noise
    return @s

Parser = Parser
Canvas = require \canvas
canvas = new Canvas 512, 512
ctx = canvas.get-context \2d
render = ->
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

nums = <[ 0 16 32 64 128 256 512 ? ]>
vocab = <[ 0 16 64 256 512 ? @ x y + - * swap dup % sr sr di di di max xg xl yl yg sin ]>

R = -> ~~(it * Math.random!)
pick = -> it[R(it.length)]

# With image, twitter takes up to 117 characters
random-prog = (cap) ->
  prog = ''
  for ii from 0 til 5 # first seed the stack
    prog += ' ' + pick nums
  while prog.length < cap
    prog += ' ' + pick vocab
  console.log prog
  return prog

layers = ->
  ctx.global-alpha = 1
  ctx.fill-style = '#fff'
  ctx.fill-rect 0, 0, canvas.width, canvas.height
  ctx.global-alpha = 0.2
  for ii from 0 til 5
    render random-prog!

sectioned = ->
  prog = ''
  for ii from 0 til 10
    prog += ' ' + pick nums
  for ii from 0 til 10
    prog += ' ' + pick vocab
  prog += '256 x < *'
  for ii from 0 til 10
    prog += ' ' + pick vocab
  prog += '256 x > *'
  console.log prog
  return prog

code = process.argv.2 or random-prog 100
render code
write-png canvas
