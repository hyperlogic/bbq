#include "bbq.h"
#include "level.h"
#include <stdio.h>

int main()
{
	Level* level = (Level*)bbq_load("level.bin");

	printf("loaded level!\n");

	return 0;
}
