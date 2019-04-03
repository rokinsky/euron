#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "test_euron.h"

// Stos ma domyślnie 8 MiB, więć pomieści milion wartości 8-bajtowych.
#define MAX_STACK_SIZE 1000000

// funkcje wołane przez eurony

int get_value_calls[NNNN];
int put_value_calls[NNNN];

uint64_t get_value(uint64_t n) {
  ++get_value_calls[n];
  check_euron_number(n, "get_value");

  if (TEST_NUM == 102) {
    return 102;
  }
  else if (TEST_NUM == 103) {
    return 103;
  }
  else if (TEST_NUM == 200) {
    return n + 1;
  }
  else {
    unexpected_function_call(n, "get_value");
    return 0;
  }
}

void put_value(uint64_t n, uint64_t v) {
  ++put_value_calls[n];
  check_euron_number(n, "put_value");

  if (TEST_NUM == 104) {
    check_euron_value(n, v, 1, "put_value");
  }
  else if (TEST_NUM == 105) {
    check_euron_value(n, v, 7, "put_value");
    push_stack(MAX_STACK_SIZE);
  }
  else if (TEST_NUM == 200) {
    check_euron_value(n, v, n + 4, "put_value");
  }
  else {
    unexpected_function_call(n, "put_value");
  }
}

// testy 1xx dla N == 1

euron_test_t test_1xx[][1] = {
  // TEST_NUM == 100
  {{"1", 1, 0, 0}},
  // TEST_NUM == 101
  {{"1-", (uint64_t)-1, 0, 0}},
  // TEST_NUM == 102, wołanie funkcji get_value
  {{"G", 102, 1, 0}},
  // TEST_NUM == 103, wołanie funkcji get_value
  {{"GG", 103, 2, 0}},
  // TEST_NUM == 104, obliczenie z dużą ilością danych na stosie
  {{NULL, 0, 0, 1}},
  // TEST_NUM == 105, wołanie funkcji put_value i dużo zapisów na stosie poniżej obliczenia
  {{"27P", 2, 0, 1}},
  // TEST_NUM == 106, wynik 2^64
  {{"8888888888888888888882*********************", 0, 0, 0}},
  // TEST_NUM == 107, wynik 2^64
  {{"444444444444444444444444444444*****************************DDDDDDDDDDDDDDD+++++++++++++++-", 0, 0, 0}}
};

// testy 2xx dla N == 2

static char program_200[] = "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC";

euron_test_t test_2xx[][2] = {
  // TEST_NUM == 200, test z treści zadania
  {{program_200, 112, 1, 1},
   {program_200, 56, 1, 1}},
  // TEST_NUM == 201, intensywna synchronizacja dwóch eronów
  {{"41S1S1S1S1S1S1S1S1S1S1S1S1S1S1S1S1S1S1S1S1S"
    "9DDDDDDD*******3B1-+6-BC1S"
    "9DDDDDD******3B1-+6-BC1S"
    "9DDDDD*****3B1-+6-BC1S"
    "9DDDD****3B1-+6-BC1S"
    "9DDD***3B1-+6-BC1S"
    "9DD**3B1-+6-BC1S"
    "9D*3B1-+6-BC6C", 5, 0, 0},
   {"56C0S0S0S0S0S0S0S0S0S0S0S0S0S0S0S0S0S0S0S0S"
    "9DDDDDDD*******3B1-+6-BC0S"
    "9DDDDDD******3B1-+6-BC0S"
    "9DDDDD*****3B1-+6-BC0S"
    "9DDDD****3B1-+6-BC0S"
    "9DDD***3B1-+6-BC0S"
    "9DD**3B1-+6-BC0S"
    "9D*3B1-+6-BC0S", 4, 0, 0}},
  // TEST_NUM == 202, zapętlenie przy braku synchronizacji, naruszenie
  // ochrony pamięci przy braku implementacji synchronizacji
  {{"1C2468***1S3579***-+998++-B", 0, 0, 0},
   {"1C3579***0S2468***-+998++-B", 0, 0, 0}},
};

// testy 3xx dla N == 3, każdy test powtarzany 3 razy

static char program_300[] = "25*D*D*6*6*nE1-+8-BC";

euron_test_t test_3xx[][3] = {
  // TEST_NUM == 300, oblicznie zajmujące ponad 1/3 stosu bez synchronizacji euronów
  {{program_300, 0, 0, 0}, {program_300, 1, 0, 0}, {program_300, 2, 0, 0}},
  // TEST_NUM == 301, prosta synchronizacja 3 euronów
  {{"01S2S", 0, 0, 0}, {"10S2S", 2, 0, 0}, {"21S0S", 1, 0, 0}}
};

// testy 4xx dla N == NNNN

#define BUFFER_LENGTH_400 (32 * NNNN)

static char program_400[] = "n0Sn0Sn0Sn0S";
static char program_401_0[] =
  "n0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S"
   "0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S0---Cn1+S";
static char program_401_1[] =
  "nn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+S"
   "n1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+S";
static char program_401_2[] =
  "nn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+S"
   "n1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+Sn1+Sn1-+S";
static char program_401_e[] =
  "n0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S"
   "0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S0--Cn1-+S";

euron_test_t test_4xx[][NNNN];

// generator programów dla euronów

void make_programs(void) {
  if (TEST_NUM == 104) {
    char *p = test_1xx[4][0].program = malloc(2 * MAX_STACK_SIZE);
    assert(p);
    test_1xx[4][0].expected = MAX_STACK_SIZE - 1;
    memset(p, '1', MAX_STACK_SIZE);
    p[MAX_STACK_SIZE] = 'P';
    memset(p + MAX_STACK_SIZE + 1, '+', MAX_STACK_SIZE - 2);
    p[2 * MAX_STACK_SIZE - 1] = '\0';
  }
  else if (TEST_NUM == 400) {
    assert(NNNN >= 2);
    char *p = test_4xx[0][0].program = malloc(BUFFER_LENGTH_400);
    assert(p);
    int x = NNNN - 1, i = 0, j = 0, k;
    assert(x > 0);
    while (x) {
      p[BUFFER_LENGTH_400 / 2 + i] = x % 9 + '0';
      x /= 9;
      ++i;
    }
    p[j++] = '0';
    assert(i > 0);
    while (i) {
      --i;
      p[j++] = '9';
      p[j++] = '*';
      p[j++] = p[BUFFER_LENGTH_400 / 2 + i];
      p[j++] = '+';
    }
    for (i = 2; i < NNNN; ++i) {
      p[j++] = 'D';
      p[j++] = '1';
      p[j++] = '-';
      p[j++] = '+';
    }
    p[j++] = '0';
    for (i = 1; i < NNNN; ++i) {
      p[j++] = 'E';
      p[j++] = 'S';
    }
    for (k = 0; k < 4; ++k) {
      for (i = 0; i < j; ++i) {
        p[3 * j + i] = p[2 * j + i] = p[j + i] = p[i];
      }
    }
    p[4 * j] = '\0';
    assert(4 * j < BUFFER_LENGTH_400);
    test_4xx[0][0].expected = NNNN - 1;
    test_4xx[1][0].get_value_expected = test_4xx[1][0].put_value_expected = 0;
    for (i = 1; i < NNNN; ++i) {
      test_4xx[0][i].program = program_400;
      test_4xx[0][i].expected = i - 1;
      test_4xx[1][i].get_value_expected = test_4xx[1][i].put_value_expected = 0;
    }
  }
  else if (TEST_NUM == 401) {
    assert(NNNN >= 2);
    int perm[NNNN], i, j;
    test_4xx[1][0].program = program_401_0;
    for (i = 1; i < NNNN - 1; i += 2)
      test_4xx[1][i].program = program_401_1;
    for (i = 2; i < NNNN - 1; i += 2)
      test_4xx[1][i].program = program_401_2;
    test_4xx[1][NNNN - 1].program = program_401_e;
    for (i = 0; i < NNNN; ++i)
      test_4xx[1][i].expected = i;
    perm[0] = 1;
    for (i = 1; i < NNNN - 1; i += 2)
      perm[i] = i + 2 < NNNN ? i + 2 : i + 1;
    for (i = 2; i < NNNN; i += 2)
      perm[i] = i - 2;
    if ((NNNN & 1) == 0)
      perm[NNNN - 1] = NNNN - 2;
    for (i = 0; i < NNNN; ++i)
      assert(perm[i] >= 0 && perm[i] < NNNN);
    for (i = 1; i < NNNN; ++i)
      for (j = 0; j < i; ++j)
        assert(perm[j] != perm[i]);
    for (i = 0; i < NNNN; ++i)
      test_4xx[1][i].expected = perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[perm[i]]]]]]]]]]]]]]]];
    for (i = 0; i < NNNN; ++i)
      test_4xx[1][i].get_value_expected = test_4xx[1][i].put_value_expected = 0;
  }
}
