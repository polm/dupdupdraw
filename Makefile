all: src/dupdupdraw.ls
	lsc -b -c -o lib src/
	browserify lib/dupdupdraw.js > pages/dupdupdraw.browser.js

clean:
	rm -f lib/*
