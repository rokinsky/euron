#ifndef EURON_H
#define EURON_H

#include <stdint.h>

uint64_t get_value(uint64_t n);

void put_value(uint64_t n, uint64_t w);

uint64_t euron(uint64_t n, char const *prog);

#endif // EURON_H