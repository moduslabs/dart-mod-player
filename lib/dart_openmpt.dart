import 'dart:ffi';
import 'dart:io' show Directory, Platform, sleep, exit;
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';


import 'dart_openmpt_structs.dart';

// Create the function type definitions
typedef openModFile_native = Int32 Function(Pointer<Utf8> str);
typedef OpenModFile = int Function(Pointer<Utf8> str);

typedef play_music_native = Int32 Function();
typedef PlayMusic = int Function();

typedef stop_music_native = Int32 Function();
typedef StopMusic = int Function();

typedef shutdown_native = Int32 Function();
typedef Shutdown = int Function();

typedef get_mod_info_native = ModInfo Function();

typedef get_pattern_native = ArrayOfStrings Function(Int32 patternNum);
typedef GetPattern = ArrayOfStrings Function(int patternNum);

typedef get_mod_position_native = ModPosition Function();

typedef get_audio_buffers_native = StereoAudioBuffersNative Function();
typedef GetAudioBuffers = StereoAudioBuffersNative Function();


// Load the compiled CPP Library
String LoadLibrary() {

  String currentPath = Directory.current.path;
  final String libraryName = 'OpenMPT';

  // Link shared objects
  String libraryPath = path.join(currentPath, 'lib/${libraryName}/build/', 'libdartopenmpt.so');
  if (Platform.isMacOS) {
    libraryPath = path.join(currentPath, 'lib/${libraryName}/build/', 'libdartopenmpt.dylib');
  }
  if (Platform.isWindows) {
    libraryPath = path.join(currentPath, 'lib/${libraryName}/build/', 'Debug', 'libdartopenmpt.dll');
  }

  return libraryPath;
}

// Load the compiled (shared) CPP Libraries
String libraryPath = LoadLibrary();


class OpenMpt extends Object {
  DynamicLibrary dyLib = DynamicLibrary.open(libraryPath);
  ModInfo modInfo = ModInfo();
  List<List<String>> allPatterns = [[]];

  // Opens a Mod file via shared Library function
  void openModFile(String file) {
    final OpenModFile openModFileC = dyLib.lookup<NativeFunction<openModFile_native>>('open_mod_file').asFunction();
    openModFileC(file.toNativeUtf8());

    final GetModFileInfo = dyLib.lookupFunction<get_mod_info_native, get_mod_info_native>('get_mod_info');

    modInfo = GetModFileInfo();
    loadAllPatterns();
  }


  // Helper function to load all MOD file song patterns and cache them in an array of array of strings.
  void loadAllPatterns() {
    allPatterns = getAllPatterns();
  }

  List<List<String>> getAllPatterns() {
    List<List<String>> allPatterns = [];

    for (int patNum = 0; patNum < modInfo.num_patterns; patNum++) {
      allPatterns.add(getPattern(patNum));
    }

    return allPatterns;
  }

  // Helper function to fetch a specific song pattern via FFI
  List<String> getPattern(int patternNum) {
    GetPattern getPatternZ = dyLib.lookupFunction<get_pattern_native, GetPattern>('get_pattern');

    ArrayOfStrings patternStrings = getPatternZ(patternNum);

    List<String> pattern = [];

    for (int i = 0; i < patternStrings.numItems; i++) {
      pattern.add(patternStrings.items[i].toDartString());
    }

    return pattern;
  }

  // Helper to begin playing music via FFI function invocation
  void playMusic() {
    final PlayMusic playMusic = dyLib.lookup<NativeFunction<play_music_native>>('play_music').asFunction();
    playMusic();
  }

  // Helper to stop playing music via FFI function invocation
  void stopMusic() {
    final StopMusic stopMusic = dyLib.lookup<NativeFunction<play_music_native>>('stop_music').asFunction();
    stopMusic();
  }

  // Helper to invoke cleanup via FFI function invocation
  void shutdown() {
    final Shutdown shutdown = dyLib.lookup<NativeFunction<shutdown_native>>('shutdown').asFunction();
    shutdown();
  }

  // Get the current status of the playing mod. This Struct helps us know what to print on screen.
  ModPosition getModPosition() {
    final GetModPosition = dyLib.lookupFunction<get_mod_position_native, get_mod_position_native>('get_mod_position');
    ModPosition position = GetModPosition();

    return position;
  }

  // Get the current array of Doubles
  StereoAudioBuffers getStereoAudioBuffers() {
    final GetStereoAudioBuffers = dyLib.lookupFunction<get_audio_buffers_native, GetAudioBuffers>('get_stereo_audio_buffers');
    StereoAudioBuffersNative buffers = GetStereoAudioBuffers();

    StereoAudioBuffers newBuffers = StereoAudioBuffers();
    newBuffers.num_items = buffers.numItems;

    for (int i = 0; i < buffers.numItems; i++) {
      newBuffers.left_buffer.add(buffers.left_buffer.elementAt(i).value.toDouble());
      newBuffers.right_buffer.add(buffers.right_buffer.elementAt(i).value.toDouble());
    }

    return newBuffers;
  }

  // Empty constructor for posterity
  OpenMpt() {}

  // Utility to print out the mod file information
  void printModInfo() {

    print('[Dart]Mod title = ${modInfo.title.toDartString()}');
    print('[Dart]Mod artist = ${modInfo.artist.toDartString()}');
    print('[Dart]Mod type = ${modInfo.type.toDartString()}');
    print('[Dart]Mod type_long = ${modInfo.type_long.toDartString()}');
    print('[Dart]Mod container = ${modInfo.container.toDartString()}');
    print('[Dart]Mod container_long = ${modInfo.container_long.toDartString()}');
    print('[Dart]Mod tracker = ${modInfo.tracker.toDartString()}');
    print('[Dart]Mod date = ${modInfo.date.toDartString()}');
    print('[Dart]Mod message = ${modInfo.message.toDartString()}');
    print('[Dart]Mod warnings = ${modInfo.warnings.toDartString()}');
    print('[Dart]Mod num_patterns = ${modInfo.num_patterns}');
    print('[Dart]Mod num_channels = ${modInfo.num_channels}');
    print('[Dart]Mod num_instruments = ${modInfo.num_instruments}');
    print('[Dart]Mod speed = ${modInfo.speed}');
    print('[Dart]Mod bpm = ${modInfo.bpm}');
    print('[Dart]Mod length = ${modInfo.length}');
    print('[Dart]Mod num_orders = ${modInfo.num_orders}');

  }
}
