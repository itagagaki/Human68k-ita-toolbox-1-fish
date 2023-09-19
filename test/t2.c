#include <stdio.h>
main(argc, argv)
char **argv;
{
	int i;

	for (i = 0; i < argc; i++) printf("%d: >%s<\n", i, argv[i]);
}
