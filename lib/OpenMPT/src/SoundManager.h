#ifndef SOUNDMANAGER_H
#define SOUNDMANAGER_H

#include <libopenmpt_ext.hpp>
#include <fstream>
#include <cstdio>

#include "DataTypes.h"

#include <portaudio.h>
#include <unistd.h>

enum SNDMGR_ERROR_CODES {
  SND_MGR_NO_ERROR,
  SND_MGR_ERR_INIT_AUDIO,
  SND_MGR_ERR_LOAD_FILE,
  SND_MGR_ERR_NO_FILE_SPECIFIED
};



class SoundManager {


public:

  static int currentOrder;
  static int currentPattern;
  static int currentRow;


//  explicit SoundManager();
//  ~SoundManager();

  static int InitSound();
  static void ShutDown();

  static void Run(); // For the thread

  static void Pause();
  static void Play();
  static void Stop();

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

//public slots:

//signals:
//  void modPositionChanged(QJsonObject *modInfoObject);
};




#endif // SOUNDMANAGER_H
