# simple makefile

GCC = g++

# SDL Mac OS X
CFLAGS = -Wall -D DARWIN -O -I /Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks/OpenGL.framework/Headers -I /Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks/GLUT.framework/Headers -I /Library/Frameworks/SDL.framework/Headers -I/usr/X11/include/freetype2 -I/usr/X11/include

LFLAGS = -framework Cocoa -framework OpenGL -framework GLUT -framework SDL -lstdc++ -Wl -framework CoreServices -framework ApplicationServices -Wl,-dylib_file,/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib:/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib

OBJ = test.o SDLMain.o

# TODO: fix dependencies
BBQ_HEADERS = app.h
DEPENDS = test.h $(BBQ_HEADERS)

test: $(OBJ)
	$(GCC) $(OBJ) -o test $(LFLAGS)

test.o: test.c $(DEPENDS)
	$(GCC) $(CFLAGS) -c $<

# Mac OS X system files
SDLMain.o : SDLMain.m $(DEPENDS)
	$(GCC) $(CFLAGS) -c $<

app.h : app.dd
	bbq-burn $< app.h

clean:
	rm $(OBJ) test $(BBQ_HEADERS)
