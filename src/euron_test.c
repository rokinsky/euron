#include <stdio.h>
#include <inttypes.h>
#include <assert.h>
#include "euron.h"
#include <pthread.h>
#include <string.h>
#include <fcntl.h>
#include <memory.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <limits.h>

#define N 2
#define N_TESTS 4

typedef struct euron_args {
  uint64_t id;
  char* prog;
} euron_args;

typedef struct Test {
  uint64_t id;
  char* prog;
  uint64_t expected;
} Test;

const Test tests[N_TESTS][N] = {
  {
    {0, "nnS4n+P4n+P", 0},
    {1, "nnS4n+P4n+P", 1}
  },
  {
    {0, "5n+1n-+4n+1n-+SCS", 6},
    {1, "5n+1n-+4n+1n-+SCS", 5}
  },
  {
    {0, "4n+1n-+S", 5},
    {1, "4n+1n-+S", 4}
  },
  {
    {0, "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC", 112},
    {1, "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC", 56}
  }
};

uint64_t get_value(uint64_t n) {
  const char* s = "get_value";
  assert(n < N);
  uint64_t res = n + 1;
  uint64_t a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9;
  fprintf(stderr, "%s: %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu\n",
      s, a, b, c, d, e, f, g, h, i
  );
  return res;
}

void put_value(uint64_t n, uint64_t v) {
  const char* s = "put_value";
  assert(n < N);
  assert(v >= n);
  get_value(n);
  fprintf(stderr, "%s: %lu, %lu\n", s, n, v);
  if (v != n)
    put_value(n, v - 1);

  return;
}

void* thread_function(void* data) {
  euron_args args = *((euron_args* ) data);
  free(data);

  fprintf(stderr, "[euron] id: %" PRIu64 ", prog: %s\n", args.id, args.prog);

  pthread_exit((void *) euron(args.id, args.prog));
}

int main() {
  pthread_t thread[N];
  void *ret;

  fprintf(stderr, "[main] pid is %d\n\n", (int) getpid());

  // branch tests, one thread
  const char* t = "21-+6-B";
  assert(euron(N, t) == 0);
  assert(strcmp(t, "21-+6-B") == 0);
  assert(euron(N, "15B00002") == 1);
  assert(euron(N, "12ED+E1-+75+-BC") == 4);
  assert(euron(0, "01234n+P56789E-+D+*G*1n-+C2*2ED+E1-+75+-BC") == 112);
  assert(euron(1, "01234n+P56789E-+D+*G*1n-+C7-7-++2ED+E1-+75+-BC") == 56);

  // synchronize tests, two threads
  for (int j = 0; j < N_TESTS; j++) {
    fprintf(stderr, "[main] test N %d\n", j);
    for (int i = 0; i < N; i++) {
      euron_args *arg = malloc(sizeof(euron_args));
      arg->id = tests[j][i].id;
      arg->prog = tests[j][i].prog;

      if (pthread_create(&(thread[i]), NULL, thread_function, arg) != 0)
        fprintf(stderr, "pthread_create\n");
    }

    for (int i = 0; i < N; i++) {
      if (pthread_join(thread[i], &ret) != 0) {
        fprintf(stderr, "pthread_join\n");
        exit(1);
      }
      fprintf(stderr, "[main] result for euron %d is %" PRIu64 "\n",
          i, (uint64_t) ret);
      assert((uint64_t) ret == tests[j][i].expected);
    }
    fprintf(stderr, "\n");
  }

  return 0;
}