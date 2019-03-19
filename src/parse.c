#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#define SIZE 40
#define MAX_THREADS 10

int N;
int stack_pointer[MAX_THREADS];
int stacks[MAX_THREADS][SIZE];
int pc[MAX_THREADS];
bool ended[MAX_THREADS];
int synchronize[MAX_THREADS] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};

int size(int stack) {
  return stack_pointer[stack];
}

bool empty(int stack) {
  return size(stack) == 0;
}

int top(int stack) {
  assert(!empty(stack));
  return stacks[stack][stack_pointer[stack] - 1];
}

int pop(int stack) {
  assert(!empty(stack));
  return stacks[stack][--stack_pointer[stack]];
}

void push(int stack, int x) {
  stacks[stack][stack_pointer[stack]++] = x;
}

void print_table(int t[], int n, const char* end) {
  printf("[");

  for (int i = 0; i < n - 1; i++) {
    printf("%d, ", t[i]);
  }

  if (n > 0) {
    printf("%d", t[n - 1]);
  }

  printf("]%s", end);
}

int get_value(int n) {
  assert(n < N);
  return n + 1;
}

void swap(int stack1, int stack2) {
  int tmp1 = pop(stack1);
  int tmp2 = pop(stack2);

  push(stack2, tmp1);
  push(stack1, tmp2);
}

void put_value(int n, int v) {
  assert(n < N);
  printf("put_value(%d, %d)\n", n, v);
  // assert(v == n + 4);
}

int main(int argc, char* argv[]) {
  assert(argc == 3);

  int threads = atoi(argv[1]);
  assert(0 < threads && threads <= MAX_THREADS);

  N = threads;

  int tmp;
  char* program = argv[2];
  int ended_counter = 0;

  while (ended_counter != threads) {
    for (int e = 0; e < threads; ++e) {
      if (ended[e]) {
        continue;
      }

      // printf("euron %d execute program[%d] = %c\n", e, pc[e], program[pc[e]]);

      switch(program[pc[e]]) {
        case '+': // zdejmij dwie wartości ze stosu, oblicz ich sumę i wstaw wynik na stos;
          push(e, pop(e) + pop(e));
          break;

        case '*': // zdejmij dwie wartości ze stosu, oblicz ich iloczyn i wstaw wynik na stos;
          push(e, pop(e) * pop(e));
          break;

        case '-': // zaneguj arytmetycznie wartość na wierzchołku stosu;
          push(e, -pop(e));
          break;

        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9': // wstaw na stos odpowiednio liczbę 0 do 9;
          push(e, program[pc[e]] - '0');
          break;

        case 'n': // wstaw na stos numer euronu;
          push(e, e);
          break;

        case 'B': // zdejmij wartość ze stosu, jeśli teraz na wierzchołku stosu jest wartość
          // różna od zera, potraktuj zdjętą wartość jako liczbę w kodzie
          // uzupełnieniowym do dwójki i przesuń się o tyle operacji;
          tmp = pop(e);

          if (top(e) != 0) {
            pc[e] += tmp;
          }

          break;

        case 'C': // zdejmij wartość ze stosu;
          pop(e);
          break;

        case 'D': // wstaw na stos wartość z wierzchołka stosu, czyli zduplikuj wartość na wierzchu stosu;
          push(e, top(e));
          break;

        case 'E': // zamień miejscami dwie wartości na wierzchu stosu;
          swap(e, e);
          break;

        case 'G': // wstaw na stos wartość uzyskaną z wywołania (zaimplementowanej gdzieś
          // indziej w języku C) funkcji uint64_t get_value(uint64_t n);
          push(e, get_value(e));
          break;

        case 'N': // dodatkowa, zdejmuje liczbę x ze stosu,
          // następnie zdejmuje x liczb ze stosu
          // i wstawia do stosu liczbę o wartości s_1 * 10^{x-1} + s_2 + 10^{x-2} + ... + s_x,
          // gdzie s_1 to pierwsza z x zdejmowaych liczb, a s_x ostatnią.

          tmp = 0;

          for (int i = pop(e); i > 0; --i) {
            tmp = 10 * tmp + pop(e);
          }

          push(e, tmp);
          break;

        case 'P': // zdejmij wartość ze stosu (oznaczmy ją przez w) i wywołaj (zaimplementowaną
          // gdzieś indziej w języku C) funkcję void put_value(uint64_t n, uint64_t v);
          put_value(e, pop(e));
          break;

        case 'S': // zdejmij wartość ze stosu, potraktuj ją jako numer euronu m, czekaj na
          // operację 'S' euronu m ze zdjętym ze stosu numerem euronu n i zamień
          // wartości na wierzchołkach stosów euronów m i n.
          if (synchronize[e] == -1) {
            synchronize[e] = pop(e);
          }

          if (synchronize[e] == e) {
            push(e, pop(e)); // assercja na rozmiar stosu
            synchronize[e] = -1;
          } else {
            if (synchronize[synchronize[e]] != e) {
              --pc[e]; // czekanie
            } else {
              swap(e, synchronize[e]);

              ++pc[synchronize[e]]; // zakoncz czekanie drugiego z pary
              synchronize[synchronize[e]] = -1;
              synchronize[e] = -1;
            }
          }

          break;

        case '\0': // koniec obliczenia
          ended_counter++;
          ended[e] = true;
          break;

        default: // domyslnie nic
          break;
      }

      ++pc[e]; // zwieksz licznik rozkazow
    }
  }

  for (int e = 0; e < threads; ++e) {
    (void) printf("result for euron %d = %d\n", e, top(e));
    // (void) printf("stacks[%d] = ", e);

    // print_table(stacks[e], stack_pointer[e], "\n");
  }

  return 0;
}