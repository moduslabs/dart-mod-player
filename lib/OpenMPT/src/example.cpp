#include <cstdlib>
#include <cstdio>

#ifdef __linux__
#include <csignal>
#endif


#include "SoundManager.h"
#include "OpenMPT.h"
#include "DataTypes.h"

// Position variables
static int currPattern = -1;
static int currOrder = -1;
static int currRow = -1;

// Function that loops and prints out current status of the player thread
void run() {

  currPattern = -1;
  currOrder = -1;
  currRow = -1;


  int prevOrder = 0;

  while (SoundManager::currentPlayMode == PLAY_MODE_PLAYING && SoundManager::IsLoaded()) {
    SoundManager::GetStereoAudioBuffers(); // This is here just to exercise this method.

    ModPosition modPosition = SoundManager::GetModPosition();

    if (modPosition.current_order != currOrder || modPosition.current_pattern != currPattern || modPosition.current_row != currRow) {

      currOrder   = modPosition.current_order;
      currPattern = modPosition.current_pattern;
      currRow     = modPosition.current_row;

      if (currOrder != prevOrder) {
        prevOrder = currOrder;
      }

      ArrayOfStrings pattern = SoundManager::GetPattern(currPattern);
      printf("%s\n", pattern.items[currRow]);
      pattern.destroy();
    }

    usleep(5000);
  }

  SoundManager::Stop();
}



extern "C" {

// This will listen to any interrupt signal and exit the program
void interruptHandler(int sig) {
  printf("\nShutting down...\r\n");
  stop_music();
  shutdown();
  exit(sig);
}

// Main function
int main(int argc, char *argv[]) {
  if (argc < 2) {
    printf("Error!! Need a file name.\nExample: ./Openmpt-test MainMenu.xm\n");
    exit(SND_MGR_ERR_NO_FILE_SPECIFIED);
  }

  // register the signal handler
  signal(SIGINT, interruptHandler);

  int result = open_mod_file(argv[1]);
  if (result != 0) {
    printf("Could not load mod file: %s\n", argv[1]);
    return result;
  }

  // open the mod file
  ModInfo modInfo = get_mod_info();
  printf("modInfo.title = %s\n", modInfo.title);

  // Start playing music
  play_music();

  // Loop endlessly until CTRL + C is pressed
  run();

  SoundManager::Stop();
  return SoundManager::ShutDown();
}


} // extern ""C