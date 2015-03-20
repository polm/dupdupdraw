"""
First take - like a shader, a function is called once for each point. 
The three values at the top of the stack become r g b.

Builtins: x y t (time) */+- sqrt exp dup drop

"""


is-func = -> \function == typeof it
is-num  = -> not isNaN it

write-png = (canvas, fname) ->
  fs = require('fs')
  fname = fname or __dirname + '/images/dupdupdraw.' + (new Date!).toISOString! + '.png'
  out = fs.createWriteStream(fname)
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
      "//": \floordiv
      "=": \equal
      "%": \mod
      "^": \exp
      ">": \greater
      "&gt;": \greater
      "<": \less
      "&lt;": \less
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
  floordiv: ~> a = @pop!; b = @pop!; @push ~~(b / a)
  equal: ~> a = @pop!; b = @pop!; @push ~~(b == a)
  mod: ~> a = @pop!; b = @pop!; @push b % a
  exp: ~> a = @pop!; b = @pop!; @push Math.pow b, a
  swap: ~> a = @pop!; b = @pop!; @push a; @push b
  over: ~> a = @pop!; b = @pop!; @push a; @push b; @push a
  rot: ~> a = @pop!; b = @pop!; c = @pop!; @push b; @push a; @push c
  greater: ~> a = @pop!; b = @pop!; @push ~~(b > a)
  less: ~> a = @pop!; b = @pop!; @push ~~(b < a)
  dist: ~> yy = @pop!; xx = @pop!; @push ~~Math.sqrt( ((@x - xx)^2) + ((@y - yy)^2))
  max: ~> @push Math.max(@pop!, @pop!)
  xl: ~> if @x < @pop! then \ok else (@pop!; @push 0) # zero if not less than x
  xg: ~> if @x > @pop! then \ok else (@pop!; @push 0)
  yl: ~> if @y < @pop! then \ok else (@pop!; @push 0)
  yg: ~> if @y > @pop! then \ok else (@pop!; @push 0)
  sin: ~> @push ~~(256 * (Math.sin (@pop! / 256) * (Math.PI / 2)))
  cos: ~> @push ~~(256 * (Math.cos (@pop! / 256) * (Math.PI / 2)))
  sinh: ~> a = @pop!; @push ( (Math.pow(Math.E, a) - Math.pow(Math.E, -a)) / 2)
  ish: ~> a = @pop! / 256; @push (64 / ( (Math.pow(Math.E, a) - Math.pow(Math.E, -a)) / 2))
  r: ~> @push ~~(255 * Math.random!)
  e: ~> @push Math.E

  rgb: ~>
    b = ~~@pop! or 0
    g = ~~@pop! or 0
    r = ~~@pop! or 0
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
        ##console.log "randomed: #word"
        #@push ~~(255 * Math.random!) # no errors, just noise
    return @s

Parser = Parser
Canvas = require \canvas-browserify
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

nums = <[ 0 16 32 64 128 256 512 ]>
pushes = nums.concat <[ ? x x x x y y y y dup @ ]>
neuts = <[ swap sr sr sin sinh ish ]>
pops = <[ + - * // % di di di max xg xl yl yg ]>
vocab = pushes.concat neuts.concat pops 

R = -> ~~(it * Math.random!)
pick = -> it[R(it.length)]

stack-length = (prog) -> 
  return prog.reduce (acc, cur) ->
    if ~(pushes.indexOf cur)
      return acc + 1
    if ~(pops.indexOf cur)
      return Math.max acc - 1, 0
    return acc
  , 0

# With image, twitter takes up to 117 characters
random-prog = (cap) ->
  prog = [pick nums]
  while prog.join(' ').length <= cap
    if stack-length(prog) < 1
      prog.pop()
      prog.push pick pushes.concat neuts
    else
      prog.push pick vocab
  prog.pop()
  while stack-length(prog) < 3
    cand = prog.pop()
    prog.splice R(prog.length), 0, pick pushes.filter (x) ->
      return x.length <= cand.length
  return prog.join ' '

if process.argv.2 and process.argv.2.length > 0
  code = process.argv.2
else code = random-prog 100
console.log code
render code

if process.title !== 'browser'
  write-png canvas, process.argv.3
else
  set-timeout ->
    document.body.append-child canvas
