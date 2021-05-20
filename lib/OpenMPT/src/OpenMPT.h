#ifndef _OPENMPT_H_
#define _OPENMPT_H_

#include <cstdlib>
#include <cstdio>
#include <dirent.h>
#include <cstring>


#include "libopenmpt.h"
#include "SoundManager.h"

extern "C" {

ModInfo get_mod_info();

int open_mod_file(char *filePath);

int play_music();

int pause_music();

int stop_music();

int shutdown();


struct ArrayOfStrings get_pattern(int patternNum);

struct ModPosition get_mod_position();

struct StereoAudioBuffers get_stereo_audio_buffers();

}
#endif

