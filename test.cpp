#include "bbq.h"
#include "simple.h"
#include <stdio.h>

int main()
{
	Level* level = (Level*)bbq_load("simple.bin");

	printf("loaded level!\n");

	return 0;
}
