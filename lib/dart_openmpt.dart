import 'dart:ffi';
import 'dart:io' show Directory, Platform, sleep;
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';

import 'dart_openmpt_structs.dart';


typedef openModFile_native = Void Function(Pointer<Utf8> str);
typedef OpenModFile = void Function(Pointer<Utf8> str);

typedef play_music_native = Void Function();
typedef PlayMusic = void Function();

typedef stop_music_native = Void Function();
typedef StopMusic = void Function();

typedef shutdown_native = Void Function();
typedef Shutdown = void Function();

typedef get_mod_info_native = ModInfo Function();

typedef get_pattern_native = ArrayOfStrings Function(Int32 patternNum);
typedef GetPattern = ArrayOfStrings Function(int patternNum);

typedef get_mod_position_native = ModPosition Function();

typedef get_audio_buffers_native = StereoAudioBuffersNative Function();
typedef GetAudioBuffers = StereoAudioBuffersNative Function();


String LoadLibrary() {
  String currentPath = Directory.current.path;

  final String libraryName = 'OpenMPT';

  // Open the dynamic library
  String libraryPath = path.join(currentPath, '../lib/${libraryName}/build/', 'libOpenMPT.so');
  if (Platform.isMacOS) {
    libraryPath = path.join(currentPath, '../lib/${libraryName}/build/', 'libOpenMPT.dylib');
  }
  if (Platform.isWindows) {
    libraryPath = path.join(currentPath, '../lib/${libraryName}/build/', 'Debug', 'libOpenMPT.dll');
  }

  return libraryPath;
}

String libraryPath = LoadLibrary();


class OpenMpt extends Object {
  DynamicLibrary dyLib = DynamicLibrary.open(libraryPath);
  ModInfo modInfo = ModInfo();
  List<List<String>> allPatterns = [[]];

  void openModFile(String file) {
    final OpenModFile openModFileC = dyLib.lookup<NativeFunction<openModFile_native>>('open_mod_file').asFunction();
    openModFileC(file.toNativeUtf8());

    final GetModFileInfo = dyLib.lookupFunction<get_mod_info_native, get_mod_info_native>('get_mod_info');

    modInfo = GetModFileInfo();
    loadAllPatterns();
  }


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

  List<String> getPattern(int patternNum) {
    GetPattern getPatternZ = dyLib.lookupFunction<get_pattern_native, GetPattern>('get_pattern');

    ArrayOfStrings patternStrings = getPatternZ(patternNum);

    List<String> pattern = [];

    for (int i = 0; i < patternStrings.numItems; i++) {
      pattern.add(patternStrings.items[i].toDartString());
      // String rowNum = (i < 10) ? '0${i}' : '${i}';
      // print('${rowNum} : ${patternStrings.items[i].toDartString()}');
    }

    return pattern;
  }

  void playMusic() {
    final PlayMusic playMusic = dyLib.lookup<NativeFunction<play_music_native>>('play_music').asFunction();
    playMusic();
  }

  void stopMusic() {
    final StopMusic stopMusic = dyLib.lookup<NativeFunction<play_music_native>>('stop_music').asFunction();
    stopMusic();
  }

  void shutdown() {
    final Shutdown shutdown = dyLib.lookup<NativeFunction<shutdown_native>>('shutdown').asFunction();
    shutdown();
  }

  ModPosition getModPosition() {
    final GetModPosition = dyLib.lookupFunction<get_mod_position_native, get_mod_position_native>('get_mod_position');
    ModPosition position = GetModPosition();

    return position;
  }



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

  OpenMpt() {
    print('$this() constructor called');
  }

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