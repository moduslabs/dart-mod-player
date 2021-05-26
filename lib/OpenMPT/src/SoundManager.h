#ifndef SOUNDMANAGER_H
#define SOUNDMANAGER_H

#include <libopenmpt_ext.hpp>
#include <fstream>
#include <cstdio>

#include "DataTypes.h"

#include <portaudio.h>
#include <unistd.h>

enum SOUND_MANAGER_ERROR_CODES {
  SND_MGR_NO_ERROR,
  SND_MGR_ERR_INIT_AUDIO,
  SND_MGR_ERR_LOAD_FILE,
  SND_MGR_ERR_NO_FILE_SPECIFIED
};

enum PlayMode {
  PLAY_MODE_STOPPED,
  PLAY_MODE_PLAYING,
  PLAY_MODE_PAUSED
};

class SoundManager {


public:

  static int currentPlayMode;
  static int currentOrder;
  static int currentPattern;
  static int currentRow;
  static int currentNumRows;

  static int InitSound();
  static int ShutDown();

  static int Pause();
  static int Play();
  static int Stop();

  static void LockMutex();
  static void UnlockMutex();

  static bool IsLoaded();


  static int LoadFile(char *filePath);
  static ModInfo GetModInfo();
  static void SetModPosition(int position);
  static void SetVolume(int newVolume);

  static ArrayOfStrings GetPattern(int pattern);
  static ModPosition GetModPosition();
  static StereoAudioBuffers GetStereoAudioBuffers();

  static int getCurrentOrder() {
    return currentOrder;
  };
  static int getCurrentPattern() {
    return currentPattern;
  }
  static int getCurrentRow() {
    return currentRow;
  }

};




#endif // SOUNDMANAGER_H
