#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

extern int errno;

void
errexit(const char *msg) {
	fprintf(stderr, "Error: %s\n", msg);
	exit(1);
}

void*
gzmalloc(size_t size)
{
	void *value = malloc(size);
	//fprintf(stderr, "gzmalloc: %p\n", value);
	if(value == NULL) errexit("fatal: can't alloc");
	return value;
}

void*
gzcalloc(size_t nmemb, size_t size)
{
	void *value = calloc(nmemb, size);
	//fprintf(stderr, "gzcalloc: %p\n", value);
	if(value == NULL) errexit("fatal: can't alloc");
	return value;
}

void *
gzrealloc(void *oldvalue, size_t new_size) {
	void *value;
	fprintf(stderr, "gzrealloc before: %p (%d)\n", oldvalue, sizeof(oldvalue));
	value = realloc(oldvalue, new_size);
	fprintf(stderr, "gzrealloc after: %p (%d), %p (%d)", oldvalue, sizeof(oldvalue), value, sizeof(value));
	if(value == NULL) errexit("fatal: can't alloc");
	return value;
}
	

char*
strcopy(char *source)
{
	int  len = strlen(source);
	char *buf = gzmalloc(len+1);
	strncpy(buf, source, len);
	buf[len+1] = '\0';
	return buf;
}

char*
basename(char *path)
{
	int pathlen;
	char *pos;
	char *buf;

	if((pos = strrchr(path, '/')) != NULL) {
		buf = strcopy(++pos);
	} else {
		buf = strcopy(path);
	}

	return buf;
}


int
gz_parsetemplate(FILE *stream)
{
	char chr, nchr;
	int in_giza_tag = 0;
	int startags 	= 0;
	int endtags 	= 0;
	int elements	= 0;
	int curchr		= 0;
	int curtaglen 	= 2048;
	char *curtag;
	char gzbc[2048];
	curtag	= (char*)gzmalloc(curtaglen);

	while((chr = fgetc(stream)) != EOF) {
		if(chr == EOF) break;

		if(chr == '<') {
			if(fgetc(stream) == '?') {
				in_giza_tag++, elements++;
				continue;
			}
		} else if(chr == '?') {
			if(fgetc(stream) == '>') {
				char *entry = gzmalloc(strlen(curtag)+1);
				strncpy(entry, curtag, strlen(entry));
				//entry[strlen(curtag)+1] = '\0';
				gzbc[elements] = *entry;
				memset(curtag, (curchr = 0), strlen(curtag)+1);
				printf("%s\n", (char)gzbc[elements]);
				in_giza_tag--;
				continue;
			}
		}
		if(in_giza_tag > 0) {
			char *q;
			if(curtaglen <= curchr) {
				q = (char *)gzrealloc(curtag, strlen(curtag)+sizeof(char));
				curtaglen++;
			}
			curtag[curchr++] = chr;
			curtag[curchr] = '\0';
		}
	}	
	return(0);
}
	

int
main(int argc, char *argv[])
{
	struct stat *statbuf;
	char *myself;
	char *filename;
	int ret;
	FILE *stream;

	myself = basename(argv[0]);

	if(argc < 2) {
		fprintf(stderr, "Usage: %s <template>\n", myself);
		exit(1);
	}
	filename = strcopy(argv[1]);
	if(stat(filename, statbuf) == -1) {
		fprintf(stderr, "%s: Couldn't stat file '%s': %s\n",
			myself, filename, strerror(errno)
		);
		exit(1);
	}

	if((stream = fopen(filename, "r")) != NULL) {
		gz_parsetemplate(stream);
		fclose(stream);
	}
	else {
		fprintf(stderr, "%s: Couldn't open file '%s' for reading: %s\n",
			myself, filename, strerror(errno)
		);
		exit(1);
	}

	
	return(0);
}

