#include "OpenMPT.h"


extern "C" {

#include "DataTypes.h"


ModInfo get_mod_info() {
  ModInfo modInfo = SoundManager::GetModInfo();
  printf("%s: title %s\n", __PRETTY_FUNCTION__ , modInfo.title);
  return modInfo;
}

int open_mod_file(char *filePath) {

  int result = SoundManager::InitSound();

  if (result != 0) {
    fprintf(stderr, "Failure initializing audio!\n");
    exit(SND_MGR_ERR_INIT_AUDIO);
  }

  result = SoundManager::LoadFile(filePath);

  if (result != SND_MGR_NO_ERROR) {
    fprintf(stderr, "Error loading file %s\n", filePath);
    exit(SND_MGR_ERR_LOAD_FILE);
  }

  return result;
}


int play_music() {
  printf("%s\n", __PRETTY_FUNCTION__ );
  return SoundManager::Play();
}

int pause_music() {
  return SoundManager::Pause();
}

int stop_music() {
  return SoundManager::Stop();
}

int shutdown() {
  return SoundManager::ShutDown();
}



struct ArrayOfStrings get_pattern(int patternNum) {
  return SoundManager::GetPattern(patternNum);
}

struct ModPosition get_mod_position() {
  return SoundManager::GetModPosition();
}

struct StereoAudioBuffers get_stereo_audio_buffers() {
  return SoundManager::GetStereoAudioBuffers();
}




} // extern ""C