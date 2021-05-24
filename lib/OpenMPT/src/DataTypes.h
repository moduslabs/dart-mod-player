#ifndef OPENMPT_LIBRARY_STRUCTS_H
#define OPENMPT_LIBRARY_STRUCTS_H

#include <cstdio>

struct ArrayOfStrings {
  int32_t numItems;
  char **items;

  // Constructor, sets all of the items to null
  // takes in numItems

  // Create add method that appends

  void InitializeWithNumItems (int num_items)  {
    numItems = num_items;

    items = new char*[numItems];
    for (int i = 0; i < numItems; ++i) {
      items[i] = nullptr;
    }
  }

  void free() const {
    for (int i = 0; i < numItems; ++i) {
      delete[] items[i];
    }
  }

  void addItem(const char *item, int index) const {
    items[index] = new char[strlen(item) + 1];
    strcpy(items[index], item);
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
