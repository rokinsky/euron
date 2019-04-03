#ifndef _TEST_EURON_H_
#define _TEST_EURON_H_

#include <stdint.h>

/** BYTY ZDEFINIOWANE GDZIEŚ I WOŁANE STĄD **/

// Sprawdza, czy w wywołaniu funkcji function n jest poprawnym numerem euronu.
void check_euron_number(uint64_t n, char const *function);

// Sprawdza, czy w wywołaniu funkcji function dla euronu n
// wartość value jest równa wartości expected_value.
void check_euron_value(uint64_t n, uint64_t value, uint64_t expected_value,
                       char const *function);

// Informuje o nieoczekiwanym wywołaniu funkcji.
void unexpected_function_call(uint64_t n, char const *function);

// Wykonuje na stosie m + 1 operacji push, po czym czyści stos.
void push_stack(uint64_t m);

// numer testu
extern uint64_t TEST_NUM;

/** BYTY ZDEFINIOWANE TU I WOŁANE SKĄDŚ **/

// funkcje wołane przez eurony
uint64_t get_value(uint64_t n);
void put_value(uint64_t n, uint64_t v);

// liczba rzeczywistych wywołań tych funkcji
extern int get_value_calls[];
extern int put_value_calls[];

// generator programów dla euronów
void make_programs(void);

/** WŁAŚCIWE TESTY **/

// liczba euronów w testach 4xx
#define NNNN 36

typedef struct {
  char     *program; // program dla euronu
  uint64_t expected; // oczekiwany wynik obliczenia
  int      get_value_expected; // liczba oczekiwanych wywołań funkcji get_value
  int      put_value_expected; // liczba oczekiwanych wywołań funkcji put_value
} euron_test_t;

extern euron_test_t test_1xx[8][1];
extern euron_test_t test_2xx[3][2];
extern euron_test_t test_3xx[2][3];
extern euron_test_t test_4xx[2][NNNN];

#endif
