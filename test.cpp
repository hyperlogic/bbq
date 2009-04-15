#include "bbq.h"
#include "level.h"
#include <stdio.h>

int main()
{
	Level* level = (Level*)bbq_load("level.bin");

	printf("loaded level!\n");
	
	printf("level has %d children\n", level->children_size);

	for (int i = 0; i < level->children_size; ++i)
	{
		printf("    child %d has %d numbers\n", i, level->children[i].numbers_size);
	    printf("        [ ");
		for (int j = 0; j < level->children[i].numbers_size; ++j)
			printf("%d ", level->children[i].numbers[j]);
	    printf("]\n");
	}

	return 0;
}
