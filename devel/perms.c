#include <stdio.h>

/*
sub GZ_IREAD	{0400}
sub GZ_IWRITE	{0200}
sub GZ_IEXEC	{0100}

# ### User permissions
sub GZ_IRUSR	{GZ_IREAD}
sub GZ_IWUSR	{GZ_IWRITE}
sub GZ_IXUSR	{GZ_IEXEC}
sub GZ_IRWXU	{GZ_IREAD|GZ_IWRITE|GZ_IEXEC}

# ### Group permissions
sub GZ_IRGRP	{GZ_IRUSR >> 3}
sub GZ_IWGRP	{GZ_IWUSR >> 3}
sub GZ_IXGRP	{GZ_IXUSR >> 3}
sub GZ_IRWXG	{GZ_IRWXU >> 3}

# ### Other permissions
sub GZ_IROTH	{GZ_IRGRP >> 3}
sub GZ_IWOTH	{GZ_IWGRP >> 3}
sub GZ_IXOTH	{GZ_IXGRP >> 3}
sub GZ_IRWXO	{GZ_IRWXG >> 3}
*/

#define GZ_IREAD	0400
#define GZ_IWRITE	0200
#define GZ_IEXEC	0100
#define GZ_IRUSR	GZ_IREAD
#define GZ_IWUSR	GZ_IWRITE
#define GZ_IXUSR	GZ_IEXEC
#define GZ_IRGRP	(GZ_IRUSR >> 3)
#define GZ_IWGRP  	(GZ_IWUSR >> 3)
#define GZ_IXGRP	(GZ_IXUSR >> 3)
#define GZ_IROTH	(GZ_IRGRP >> 3)
#define GZ_IWOTH	(GZ_IWGRP >> 3)
#define GZ_IXOTH	(GZ_IXGRP >> 3)

int main(void)
{
	int perm = GZ_IRUSR|GZ_IWUSR|GZ_IRGRP|GZ_IROTH;
	printf("%o", perm);
	return 0;
}
