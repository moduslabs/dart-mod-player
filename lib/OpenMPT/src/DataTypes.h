#ifndef OPENMPT_LIBRARY_STRUCTS_H
#define OPENMPT_LIBRARY_STRUCTS_H

#include <cstdio>

struct ArrayOfStrings {
  int32_t numItems;
  char **items;
  void destroy() const {
    if (numItems) {
      for (int i = 0; i < numItems; ++i) {
        free(items[i]);
      }
    }
  }
};

struct ArrayOfInt32s {
  int32_t numItems;
  int32_t *items;
};

struct ArrayOfDoubles {
  int32_t numItems;
  double *items;
};

struct StereoAudioBuffers {
  int32_t numItems;
  double *left_buffer;
  double *right_buffer;
};

struct ModPosition {
  int32_t current_order;
  int32_t current_pattern;
  int32_t current_row;
  int32_t current_num_rows;
};

struct ModInfo {
  char *file_name;
  char *song_name;
  char *artist;
  char *type;
  char *type_long;
  char *container;
  char *container_long;
  char *title;
  char *tracker;
  char *date;
  char *message;
  char *warnings;

  int32_t num_patterns;
  int32_t num_channels;
  int32_t num_samples;
  int32_t num_instruments;
  int32_t num_orders;
  int32_t speed;
  int32_t bpm;
  double length;
};

#endif //OPENMPT_LIBRARY_STRUCTS_H
