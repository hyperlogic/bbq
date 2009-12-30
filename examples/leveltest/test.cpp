#include "bbq.h"
#include "level.h"
#include <stdio.h>

int main()
{
	bbq::Level* level = static_cast<bbq::Level*>(bbq_load("level.bin"));

	printf("loaded level!\n");
	printf("sizeof(Level) = %ld\n", sizeof(bbq::Level));
	printf("sizeof(Child) = %ld\n", sizeof(bbq::Child));
	
	printf("level has %d children\n", level->children_size);

	for (unsigned int i = 0; i < level->children_size; ++i)
	{
		printf("    child %d has %d numbers\n", i, level->children[i].numbers_size);
	    printf("        [ ");
		for (unsigned int j = 0; j < level->children[i].numbers_size; ++j)
		    printf("%d ", level->children[i].numbers[j]);
	    printf("]\n");
	}

	bbq_free(level);

	return 0;
}
