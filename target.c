#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv)
{
  printf("My process ID : %d\n", getpid());

  FILE *myself = fopen(argv[0], "r");
  if (myself == NULL) {
        while(1) {
                printf("I can't find myself, I must be running from memory!\n");
                sleep(5);
        }
  } else {
        printf("I am just a regular boring file being executed from the disk...\n");
  }

  return 0;
}
