#include <cstdlib>
#include <cstdio>
#include <dirent.h>
#include <cstring>


#include "libopenmpt.h"
//#include "libopenmpt_stream_callbacks_file.h"
#include "SoundManager.h"


extern "C" {

#include "DataTypes.h"


static void error_log_fn( const char * message, void * userdata ) {
  (void)userdata;
  if ( message ) {
    fprintf( stderr, "openmpt: %s\n", message );
  }
}


ModInfo get_mod_info() {
  ModInfo modInfo = SoundManager::GetModInfo();
  printf("%s: title %s\n", __PRETTY_FUNCTION__ , modInfo.title);
  return modInfo;
}

void open_mod_file(char *filePath) {

  int result = SoundManager::InitSound();

  if (result == SND_MGR_ERR_INIT_AUDIO) {
    fprintf(stderr, "Failure initializing audio!\n");
    exit(SND_MGR_ERR_INIT_AUDIO);
  }

  result = SoundManager::LoadFile(filePath);
  if (result != SND_MGR_NO_ERROR) {
    fprintf(stderr, "Error loading file %s\n", filePath);
    exit(SND_MGR_ERR_LOAD_FILE);
  }

//  ModInfo modFileInfo = SoundManager::GetModInfo();
//  printf("%s: modFileInfo.title = %s\n", __PRETTY_FUNCTION__ , modFileInfo.title);

//  SoundManager::Play();
//  SoundManager::Run();

//  SoundManager::ShutDown();
//  int result = 0;
//  FILE * file;
//  openmpt_module * mod;
//  int mod_err = OPENMPT_ERROR_OK;
//  const char * mod_err_str;
//  size_t count = 0;
//
//  file = fopen("/Users/jgarcia/projects/dart/dart_openmpt/lib/cpp-lib-sources/open-mpt/test/test.s3m", "rb" );
//
//
//  mod = openmpt_module_create2( openmpt_stream_get_file_callbacks(), file, &error_log_fn, NULL, NULL, NULL, &mod_err, &mod_err_str, NULL );
//
//  const char *keys = openmpt_module_get_metadata_keys(mod);
//  printf("mod keys = %s\n", keys);
//
//  if ( mod ) {
//    openmpt_module_destroy( mod );
//    mod = NULL;
//  }
//
//  fclose(file);
}


void play_music() {
  printf("%s\n", __PRETTY_FUNCTION__ );
  SoundManager::Play();
}

void pause_music() {
  SoundManager::Pause();
}

void stop_music() {
  SoundManager::Stop();
}

void shutdown() {
  SoundManager::ShutDown();
}

//void hello_world() {
//  printf("Hello World (from C)\n");
//}
//
//void printInt(int aInt) {
//  printf("The int is %i\n", aInt);
//}
//
//void printString(char *str) {
//  printf("The string from Dart land is \"%s\"\n", str);
//}
//
//char *getString() {
//  return "This is a string from C land :D";
//}

struct ArrayOfStrings get_pattern(int patternNum) {
  return SoundManager::GetPattern(patternNum);
}

struct ModPosition get_mod_position() {
  return SoundManager::GetModPosition();
}

struct StereoAudioBuffers get_stereo_audio_buffers() {
  return SoundManager::GetStereoAudioBuffers();
}

struct ArrayOfStrings readDirectory() {
  DIR *homeDirectory = opendir(".");


  struct dirent *dirEntry;

  // Count number of items
  int numItems = 0;
  size_t totalStringSize = 0;

  while ((dirEntry = readdir(homeDirectory)) != NULL) {
    numItems++;
    totalStringSize += ((strlen(dirEntry->d_name) + 1) * sizeof(char));
  }

  printf("Total Items %i, totalStringSize %lu\n", numItems, totalStringSize);

  // Rewind so we can populate the array of strings.
  rewinddir(homeDirectory);

  struct ArrayOfStrings strings = {};
  strings.numItems = numItems;

  strings.items = (char**)malloc(numItems * sizeof(char *));

  int i = 0;
  while ((dirEntry = readdir(homeDirectory)) != NULL) {
    size_t size = strlen(dirEntry->d_name) + 1;

    strings.items[i] = (char*) malloc(size);
    strcpy(strings.items[i], dirEntry->d_name);

    i++;
  }

  return strings;
}


int main(int argc, char *argv[]) {
//  hello_world();
//  printInt(12345);
//  printString("This is some string");
//  printf("Results of getString() is \"%s\"\n", getString());
//  readDirectory();

  if (argc < 2) {
    // Try to load Dungeon2.xm

    printf("Error!! Need a file name.\nExample: ./Openmpt-test MainMenu.xm\n");
    exit(SND_MGR_ERR_NO_FILE_SPECIFIED);
  }
  else {
    open_mod_file(argv[1]);
    ModInfo modInfo = get_mod_info();
    printf("modInfo.title = %s\n", modInfo.title);
    play_music();

    for (int patNum = 0; patNum < modInfo.num_patterns; ++patNum) {
      SoundManager::GetPattern(patNum);

    }

//    SoundManager::GetPattern(0);
    SoundManager::Run();
  }


  return 0;
}


} // extern ""C