#include <stdio.h>
#include <math.h>
#include <SDL/SDL.h>

#ifdef DARWIN
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>
#else
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#endif

#include "test.h"
#include "bbq.h"
#include "app.h"

const unsigned int white = 0xffffffff;
const unsigned int black = 0;
static unsigned int s_texture_data[] = { 
	white, white, white, white, black, black, black, black,
	white, white, white, white, black, black, black, black,
	white, white, white, white, black, black, black, black,
	white, white, white, white, black, black, black, black,
	black, black, black, black, white, white, white, white, 
	black, black, black, black, white, white, white, white, 
	black, black, black, black, white, white, white, white, 
	black, black, black, black, white, white, white, white 
};

static float s_quad_verts[] = {
	-1.0f, -1.0f, 0.0f,
	1.0f, -1.0f, 0.0f,
	1.0f, 1.0f, 0.0f,
	-1.0f, 1.0f, 0.0f
};

static float s_quad_uvs[] = {
	0.0f, 0.0f,
	1.0f, 0.0f,
	1.0f, 1.0f,
	0.0f, 1.0f
};

static GLuint s_texture;
static App* s_app;

void RenderInit()
{
	// set up projection matrix
	glMatrixMode(GL_PROJECTION);
	glOrtho(1.0, -1.0, -1.0, 1.0, 1.0, -1.0);
	glMatrixMode(GL_MODELVIEW);

	// setup the static texture
	glEnable(GL_TEXTURE_2D);
	glGenTextures(1, &s_texture);
	glBindTexture(GL_TEXTURE_2D, s_texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//	glTexImage2D(GL_TEXTURE_2D, 0, 4, 8, 8, 0, GL_RGBA, GL_UNSIGNED_BYTE, s_texture_data);
	glTexImage2D(GL_TEXTURE_2D, 
				 0, 
				 s_app->background.internal_format, 
				 s_app->background.width, 
				 s_app->background.height, 
				 0, 
				 s_app->background.format, 
				 s_app->background.type, 
				 s_app->background.pixels);
	
}

void Render()
{
	glClearColor(s_app->clear_color.r, s_app->clear_color.g, 
				 s_app->clear_color.b, s_app->clear_color.a);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glBindTexture(GL_TEXTURE_2D, s_texture);

	float* uvs = s_quad_uvs;
	float* verts = s_quad_verts;

	glColor4f(s_app->quad_color.r, s_app->quad_color.g, 
			  s_app->quad_color.b, s_app->quad_color.a);

	glBegin(GL_QUADS);

	for (unsigned int i = 0; i < 4; i++)
	{
		glMultiTexCoord2fv(0, uvs); uvs += 2;
		glVertex3fv(verts); verts += 3;
	}
	glEnd();
		
	SDL_GL_SwapBuffers();
}

int main(int argc, char* argv[])
{
	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		fprintf(stderr, "Couldn't init SDL!\n");

	atexit(SDL_Quit);

	SDL_Surface* screen = SDL_SetVideoMode(800, 600, 32, 
										   SDL_HWSURFACE | SDL_RESIZABLE | SDL_OPENGL);

	if (!screen)
		fprintf(stderr, "Couldn't create SDL screen!\n");

	// load app
	s_app = (App*)bbq_load("app.bin");

	RenderInit();

	bool done = false;
	while (!done)
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
				case SDL_QUIT:
					done = true;
					break;

				case SDL_VIDEORESIZE:
					screen = SDL_SetVideoMode( event.resize.w, event.resize.h, 32, 
											   SDL_HWSURFACE | SDL_RESIZABLE | SDL_OPENGL );
					break;
			}
		}

		if (!done)
			Render();
	}

	// free app
	bbq_free(s_app);

	return 0;
}
