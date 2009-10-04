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

#define WHITE 0xffffffff
#define BLACK 0x0
static unsigned int s_texture_data[] = { 
	WHITE, WHITE, WHITE, WHITE, BLACK, BLACK, BLACK, BLACK,
	WHITE, WHITE, WHITE, WHITE, BLACK, BLACK, BLACK, BLACK,
	WHITE, WHITE, WHITE, WHITE, BLACK, BLACK, BLACK, BLACK,
	WHITE, WHITE, WHITE, WHITE, BLACK, BLACK, BLACK, BLACK,
	BLACK, BLACK, BLACK, BLACK, WHITE, WHITE, WHITE, WHITE, 
	BLACK, BLACK, BLACK, BLACK, WHITE, WHITE, WHITE, WHITE, 
	BLACK, BLACK, BLACK, BLACK, WHITE, WHITE, WHITE, WHITE, 
	BLACK, BLACK, BLACK, BLACK, WHITE, WHITE, WHITE, WHITE 
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
static struct App* s_app;

void render_init()
{
	// set up projection matrix
	glMatrixMode(GL_PROJECTION);
	glOrtho(1.0, -1.0, -1.0, 1.0, 1.0, -1.0);
	glMatrixMode(GL_MODELVIEW);
	glRotatef(180.0f, 0.0f, 1.0f, 0.0f);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

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

	printf("clear color = %.3f, %.3f, %.3f, %.3f\n", 
		   s_app->clear_color.r, s_app->clear_color.g, 
		   s_app->clear_color.b, s_app->clear_color.a);

	printf("quad color = %.3f, %.3f, %.3f, %.3f\n", 
		   s_app->quad_color.r, s_app->quad_color.g, 
		   s_app->quad_color.b, s_app->quad_color.a);
}

void render()
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

	unsigned int i;
	for (i = 0; i < 4; i++)
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
	s_app = (struct App*)bbq_load("app.bin");

	render_init();

	unsigned char done = 0;
	while (!done)
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
				case SDL_QUIT:
					done = 1;
					break;

				case SDL_VIDEORESIZE:
					screen = SDL_SetVideoMode( event.resize.w, event.resize.h, 32, 
											   SDL_HWSURFACE | SDL_RESIZABLE | SDL_OPENGL );
					break;
			}
		}

		if (!done)
			render();
	}

	// free app
	bbq_free(s_app);

	return 0;
}
