import 'dart:ffi';
import 'package:ffi/ffi.dart';

class ArrayOfInt32s extends Struct {
  @Int32()
  external int numItems;

  external Pointer<Int32> items;
}

class ArrayOfDoubles extends Struct {
  @Int32()
  external int numItems;

  external Pointer<Double> items;
}

class ArrayOfStrings extends Struct {
  @Int32()
  external int numItems;

  external Pointer<Pointer<Utf8>> items;
}

class StereoAudioBuffersNative extends Struct {
  @Int32()
  external int numItems;

  external Pointer<Double> left_buffer;
  external Pointer<Double> right_buffer;
}

class ModPosition extends Struct {
  @Int32()
  external int current_order;
  @Int32()
  external int current_pattern;
  @Int32()
  external int current_row;
  @Int32()
  external int current_num_rows;
}

class ModInfo extends Struct {
  external Pointer<Utf8> file_name;
  external Pointer<Utf8> song_name;
  external Pointer<Utf8> artist;
  external Pointer<Utf8> type;
  external Pointer<Utf8> type_long;
  external Pointer<Utf8> container;
  external Pointer<Utf8> container_long;
  external Pointer<Utf8> title;
  external Pointer<Utf8> tracker;
  external Pointer<Utf8> date;
  external Pointer<Utf8> message;
  external Pointer<Utf8> warnings;

  @Int32()
  external int num_patterns;

  @Int32()
  external int num_channels;

  @Int32()
  external int num_samples;

  @Int32()
  external int num_instruments;

  @Int32()
  external int num_orders;
  @Int32()
  external int speed;

  @Int32()
  external int bpm;

  @Double()
  external double length;
}

class StereoAudioBuffers extends Object {
  List<double> left_buffer = [];
  List<double> right_buffer = [];
  int num_items = 0;
}






