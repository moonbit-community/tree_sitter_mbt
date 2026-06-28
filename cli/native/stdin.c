#include <moonbit.h>

#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

MOONBIT_FFI_EXPORT moonbit_bytes_t tree_sitter_mbt_cli_read_stdin_bytes(void) {
  size_t capacity = 4096;
  size_t length = 0;
  uint8_t *buffer = (uint8_t *)malloc(capacity);
  if (buffer == NULL) {
    return moonbit_make_bytes(0, 0);
  }

  while (1) {
    if (length == capacity) {
      size_t next_capacity = capacity * 2;
      if (next_capacity < capacity) {
        free(buffer);
        return moonbit_make_bytes(0, 0);
      }
      uint8_t *next = (uint8_t *)realloc(buffer, next_capacity);
      if (next == NULL) {
        free(buffer);
        return moonbit_make_bytes(0, 0);
      }
      buffer = next;
      capacity = next_capacity;
    }

    if (length > INT32_MAX) {
      free(buffer);
      return moonbit_make_bytes(0, 0);
    }

    size_t available = capacity - length;
    size_t read = fread(buffer + length, 1, available, stdin);
    length += read;
    if (length > INT32_MAX) {
      free(buffer);
      return moonbit_make_bytes(0, 0);
    }
    if (read < available) {
      if (ferror(stdin)) {
        free(buffer);
        return moonbit_make_bytes(0, 0);
      }
      break;
    }
  }

  moonbit_bytes_t result = moonbit_make_bytes((int32_t)length, 0);
  memcpy(result, buffer, length);
  free(buffer);
  return result;
}
