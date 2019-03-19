#include <stdio.h>
#include <inttypes.h>
#include <assert.h>
#include "euron.h"
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define N 2
#define COMPUTE "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC"

int64_t *addr;

uint64_t get_value(uint64_t n) {
  assert(n < N);
  return n + 1;
}

void* thread_function(void* arg) {
  fprintf(stderr, "[thread] pid is %d\n", (int) getpid());
  int64_t thread_var = *addr;

  fprintf(stderr, "[thread] var: %" PRId64 "\n", thread_var);
  fprintf(stderr, "[thread] var addr: %p\n", &thread_var);

  while (1);
  return NULL;
}

void put_value(uint64_t n, uint64_t v) {
  assert(n < N);
  assert(v == n + 4);
}

int main() {

  //fprintf(stderr, "[main] pid is %d\n", (int) getpid());
  //int64_t main_var = 42;
  //addr = &main_var;
  //fprintf(stderr, "[main] addr: %p\n", addr);

  //pthread_t thread;
  //pthread_create(&thread, NULL, &thread_function, NULL);


  // branch tests
  assert(euron(N, "21-+6-B") == 0);
  assert(euron(N, "15B00002") == 1);
  assert(euron(N, "12ED+E1-+75+-BC") == 4);
  assert(euron(0, "01234n+P56789E-+D+*G*1n-+C2*2ED+E1-+75+-BC") == 112);
  assert(euron(1, "01234n+P56789E-+D+*G*1n-+C7-7-++2ED+E1-+75+-BC") == 56);

  // synchronize tests
  assert(euron(0, "4n+1n-+S") == 5);
  assert(euron(1, "4n+1n-+S") == 4);

  // 01234n+P56789E-+D+*G*1n-+2*2ED+E1-+75+-BED+E1-+75+-BC

  //fprintf(stderr, "[main] len prog: %lu, is it true? %d\n",
  //    len, len == strlen(COMPUTE));
  //while (1);
  return 0;
}