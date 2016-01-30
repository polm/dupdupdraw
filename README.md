This is a simple HTML canvas experiment with a forth-like language. 

As a quick primer:

# How does Forth work?

Forth is a stack-machine based postfix language. Words in your program are executed in order, and the stack starts empty. A stack is like a list where the first thing you put in is the first thing you pull out. 

    stack: []
    program: 2 3 + 4

In many programming languages you might think this adds 3 and 4 and gives an error about 2, but the language for dupdupdraw doesn't work that way. Words are executed from left to right, so...

1. 2 is a number, so it goes on the stack: [2]
2. 3 is the same: [2 3]
3. + is an instruction, so it adds the top two numbers and puts the result on the stack: [5]
4. 4 is just like 2 and 3, so our final stack is [5 4]. 

Trying to use an empty stack or using a word you haven't defined causes an error in a real Forth, but in dupdupdraw it's handled this way:

- if the stack is empty you get enough zeros to perform the operation (so "2 +" -> [2]). 
- unknown words are assigned a random value which is constant for the whole picture. So "asdf asdf /" -> [1], and a whole program of "asdf asdf asdf" would make a picture that was some shade of gray. Note random values are not consistent between runs of the generator.

# How does dupdupdraw work?

Your program (like a tweet) is executed once for every pixel of a 512 by 512 image. The three values at the top (right) end of the stack are the r, g, and b values for that pixel, on a scale of 0 to 255. So [0 0 0] is black, [128 128 128] is grey, and [255 0 0] is red. Values outside the range are simply treated as 255 or 0 appropriately. Leftover values on the stack are ignored.

Some built in keywords change what they do depending on your pixel's location; the most obvious are `x` and `y`, which evaluate to the value for that pixel's location.

# What are the built in words? 

A word in parens is an alias. ? and @ are not keywords, but are often used as random values.

- +-/* - basic math
- = - equality test - if the top two values are equal, then push 1 onto the stack, otherwise push 0
- mod (%) - modulus "7 4 %" -> [3]. A
- // - As division, but take the floor (round down). 
- sqrt (sr) - square root
- sin - sin of the value multiplied by 255
- r - random and re-evaluated for every pixel (adds noise)
- dist (di) - the distance of the current pixel from the location denoted by the two values on the top of the stack ("10 20 di" gives distance from x: 10, y: 20).
- < > - "10 7 <" -> [0], "7 10 <" -> [1]. There's no `if` in dupdupdraw, but this can be used in much the same way ("x dup 256 < *" is zero where x is not less than 256, for example.)
- xl / xg / yl / yg - If the top of the stack is less than x (for xl), leave the next value alone, otherwise replace with zero. xg -> x greater, yg -> y greater etc. This is good for sectioning your canvas.
- dup - duplicate the top of the stack ("23 dup" -> [23 23])
- swap - swap the top of the stack with the next value "1 2 swap" -> [2 1]
- ish - inverse sinh, 64 / sinh(input / 256). Good for curves. Thanks to @itszutak for introducing me to sinh. (sinh is also available but it's a very steep curve)
- max - remove the two values from the top of the stack and put the higher one back. 
- rot - put the value two down the stack on top. "1 2 3 rot" -> [2 3 1]
- over - make a copy of the second value on the stack and push it. "1 2 over" -> [1 2 1]

If you have any questions, feel free to ask me on Twitter. Thanks!

-POLM
