# simple makefile

GCC = gcc

# SDL Mac OS X
CFLAGS = -Wall -g -D DARWIN -O -I /Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks/OpenGL.framework/Headers -I /Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks/GLUT.framework/Headers `sdl-config --cflags` `freetype-config --cflags`

LFLAGS = -framework Cocoa -framework OpenGL -framework GLUT -lstdc++ -Wl -framework CoreServices -framework ApplicationServices -Wl,-dylib_file,/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib:/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib `sdl-config --libs` `freetype-config --libs`

OBJ = test.o SDLMain.o bbq.o

# TODO: fix dependencies
BBQ_HEADERS = app.h
BBQ_BINARIES = app.bin
DEPENDS = test.h $(BBQ_HEADERS)

test: $(OBJ) $(BBQ_BINARIES)
	$(GCC) $(OBJ) -o test $(LFLAGS)

bbq.o: bbq.c bbq.h
	$(GCC) $(CFLAGS) -c $<

test.o: test.c $(DEPENDS)
	$(GCC) $(CFLAGS) -c $<

# Mac OS X system files
SDLMain.o : SDLMain.m $(DEPENDS)
	$(GCC) $(CFLAGS) -c $<

app.h : app.dd
	bbq-burn $< app.h

app.bin : app.dd app.di
	bbq-cook -l app.di app.bin

clean:
	rm $(OBJ) test $(BBQ_HEADERS) $(BBQ_BINARIES)
