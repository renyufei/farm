#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "vertical.h"

/* ./vertical [rawdata] [min_sup] [min_confidence] */

static void
usage(const char *name)
{
	printf("usage: %s [-i input_file] [-s min_sup] [-c min_confidence]\n", \
		name);
	printf("\t-i\t\tInput File\n");
	printf("\t-s\t\tMinimum Support - default 10\n");
	printf("\t-c\t\tMinimum Confidence - default 20\n");
}

int
main(int argc, char **argv)
{
	int total_trans;
	int op;
	char inputfile[1024];
	int support;
	int confidence;
	
	memset(inputfile, '\0', 1024);
	support = 10;
	confidence = 20;
	while ((op=getopt(argc, argv, "i:s:c:")) != -1) {
		switch (op) {
		case 'i':
			strcpy(inputfile, optarg);
			break;
		case 's':
			support = atoi(optarg);
			break;
		case 'c':
			confidence = atoi(optarg);
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
			break;
		}
	}
	
	if (strlen(inputfile) == 0) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	
	TAILQ_INIT(&vertical_tqh);
	TAILQ_INIT(&canset_tqh);

	total_trans = loaddata_txt(inputfile);
	DPRINTF(("total trans is %d\n", total_trans));
	
	support = (total_trans * support) / 100;
	if (support == 0)
		support = 1;

	/* construct level 1 */
	find_frequent(support);
	
	while (!TAILQ_EMPTY(&vertical_tqh)) {
		apriori_gen();
		find_frequent(support);
	}
	
	return 0;
}