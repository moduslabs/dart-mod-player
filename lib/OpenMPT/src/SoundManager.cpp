#include "SoundManager.h"
#include <thread>
#include <mutex>
#include <cstring>

static openmpt::module_ext *modFile = nullptr;
std::mutex mutex;

#define NUM_FRAMES 1024



static double soundVolume = 0; //[ 0 - 200 ];

static int currentModPattern = -1;
static int currentModOrder = -1;
static int currentModRow = -1;
static int currentModPosition = -1;
static int currentNumRows = -1;
static int currentPlayMode = -1;

ModInfo modInfoObject;
ModPosition modPosition;
static const int numLRFrames = NUM_FRAMES / 2;

static float *ltBuffer = (float *) malloc(numLRFrames * sizeof (float));
static float *rtBuffer = (float *) malloc(numLRFrames * sizeof (float));


static const size_t bufferSize =  numLRFrames;



static int static_paStreamCallback(const void *inputBuffer,
                                   void *outputBuffer,
                                   unsigned long numFrames,
                                   const PaStreamCallbackTimeInfo* timeInfo,
                                   PaStreamCallbackFlags statusFlags,
                                   void *userData)  {

  /* Prevent unused variable warning. */
  (void) inputBuffer;
  (void) timeInfo;
  (void) inputBuffer;
  (void) userData;



  if (statusFlags == paOutputUnderflow) {
    printf("Underflow!!\n");
  }

  auto *out = (float*)outputBuffer;

  SoundManager::LockMutex();

  if (modFile != nullptr) {

    modFile->read_interleaved_stereo(44100, numFrames, out);

    SoundManager::currentOrder = (int)modFile->get_current_order();
    SoundManager::currentPattern = (int)modFile->get_current_pattern();
    SoundManager::currentRow = (int)modFile->get_current_row();
    SoundManager::currentNumRows = (int)modFile->get_pattern_num_rows(currentModPattern);

    auto *outBuff = (float *)outputBuffer;

    // Copy data from
    int index = 0;
    for (int i = 0; i < numFrames; i+=2) {
      ltBuffer[index] = outBuff[i];
      rtBuffer[index] = outBuff[i+1];
      index++;
    }

  }

  SoundManager::UnlockMutex();

  return 0;
}

static PaStream *stream;

static int initializePortAudio() {
  PaError err;

  err = Pa_Initialize();
  if( err != paNoError ) goto error;

  /* Open an audio I/O stream. */
  err = Pa_OpenDefaultStream(
    &stream,
    0,                /* no input channels */
    2,                /* stereo output */
    paFloat32,        /* 32 bit floating point output */
    44100,            /* Sample Rate */
    NUM_FRAMES,       /* frames per buffer */
    static_paStreamCallback,
    nullptr
  );

  if( err != paNoError ) goto error;

  return err;

  error:
    Pa_Terminate();
    fprintf(stderr, "An error occurred while using the portaudio stream\n");
    fprintf(stderr, "Error number: %d\n", err);
    fprintf(stderr, "Error message: %s\n", Pa_GetErrorText(err));
    return err;
}


int SoundManager::currentOrder = -1;
int SoundManager::currentPattern = -1;
int SoundManager::currentRow = -1;
int SoundManager::currentNumRows = -1;
int SoundManager::currentPlayMode = -1;

int SoundManager::InitSound() {
  currentOrder = -1,
  currentPattern = -1,
  currentRow = -1;
  currentNumRows = -1;
  currentPlayMode = PLAY_MODE_STOPPED;

  fflush(stdout);
  return initializePortAudio();
}

void SoundManager::LockMutex() {
  mutex.lock();
}

void SoundManager::UnlockMutex() {
  mutex.unlock();
}


ModPosition SoundManager::GetModPosition() {
  LockMutex();

  ModPosition position = {
    .current_order = (int)modFile->get_current_order(),
    .current_pattern = (int)modFile->get_current_pattern(),
    .current_row = (int)modFile->get_current_row(),
    .current_num_rows = (int)modFile->get_pattern_num_rows((int)modFile->get_current_pattern())
  };

  UnlockMutex();
  return position;
}

StereoAudioBuffers SoundManager::GetStereoAudioBuffers() {
  StereoAudioBuffers buffers = {};

  buffers.numItems = numLRFrames;
  buffers.left_buffer = (double*)malloc(numLRFrames * sizeof(double));
  buffers.right_buffer = (double*)malloc(numLRFrames * sizeof(double));

  LockMutex();
  for (int i = 0; i < bufferSize; ++i) {
    buffers.left_buffer[i] = ltBuffer[i];
    buffers.right_buffer[i] = rtBuffer[i];
  }
  UnlockMutex();

  return buffers;
}

int SoundManager::LoadFile(char * filePath) {
  SoundManager::Stop();


  std::ifstream file(filePath, std::ios::binary);

  int loadResult = openmpt::probe_file_header(openmpt::probe_file_header_flags_default, file);

  if (loadResult == openmpt::probe_file_header_result_success) {
    static openmpt::module_ext *newModFile = nullptr;

    newModFile = new openmpt::module_ext(file);

    newModFile->set_repeat_count(999999);
    newModFile->set_render_param(3, 1);

    openmpt::ext::interactive *interactive =
        static_cast<openmpt::ext::interactive *>(newModFile->get_interface(openmpt::ext::interactive_id));

    interactive->set_global_volume(1);

    SoundManager::Pause();

    LockMutex(); // Likely unnecessary.

    delete modFile;
    modFile = newModFile;

    UnlockMutex();

    return SND_MGR_NO_ERROR;
  }

  return SND_MGR_ERR_LOAD_FILE;
}

ArrayOfStrings SoundManager::GetPattern(int patternNum) {

  ArrayOfStrings strings = {};
  strings.numItems = modFile->get_pattern_num_rows(patternNum);
  strings.items = (char**)malloc(strings.numItems * sizeof(char *));


  for (int row = 0; row < strings.numItems; ++row) {
    std::string rowString;

    for (int i = 0; i < modInfoObject.num_channels; ++i) {
      rowString = rowString.append(modFile->format_pattern_row_channel(patternNum, row, i, 0, true));
      if (i < modInfoObject.num_channels - 1) {
        rowString = rowString.append("|");
      }
    }

    strings.items[row] = (char*)malloc(rowString.length() * sizeof (char*) + 1 );
    strcpy(strings.items[row], rowString.c_str());
  }

  return strings;
}

ModInfo SoundManager::GetModInfo() {

  char *title =  (char*)modFile->get_metadata("title").c_str();
  if (modInfoObject.title != nullptr) {
    free(modInfoObject.title);
  }
  modInfoObject.title = (char *)malloc(strlen(title) * sizeof(char*));
  strcpy(modInfoObject.title, title);

  char *artist =  (char*)modFile->get_metadata("artist").c_str();
  if (modInfoObject.artist != nullptr) {
    free(modInfoObject.artist);
  }
  modInfoObject.artist = (char *)malloc(strlen(artist) * sizeof(char*));
  strcpy(modInfoObject.artist, artist);

  char *type =  (char*)modFile->get_metadata("type").c_str();
  if (modInfoObject.type != nullptr) {
    free(modInfoObject.type);
  }
  modInfoObject.type = (char *)malloc(strlen(type) * sizeof(char*));
  strcpy(modInfoObject.type, type);

  char *type_long =  (char*)modFile->get_metadata("type_long").c_str();
  if (modInfoObject.type_long != nullptr) {
    free(modInfoObject.type_long);
  }
  modInfoObject.type_long = (char *)malloc(strlen(type_long) * sizeof(char*));
  strcpy(modInfoObject.type_long, type_long);

  char *container = (char*)modFile->get_metadata("container").c_str();
  if (modInfoObject.container != nullptr) {
    free(modInfoObject.container);
  }
  modInfoObject.container = (char *)malloc(strlen(container) * sizeof(char*));
  strcpy(modInfoObject.container, container);

  char *container_long = (char*)modFile->get_metadata("container_long").c_str();
  if (modInfoObject.container_long != nullptr) {
    free(modInfoObject.container_long);
  }
  modInfoObject.container_long = (char *)malloc(strlen(container_long) * sizeof(char*));
  strcpy(modInfoObject.container_long, container_long);

  char *tracker = (char*)modFile->get_metadata("tracker").c_str();
  if (modInfoObject.tracker != nullptr) {
    free(modInfoObject.tracker);
  }
  modInfoObject.tracker = (char *)malloc(strlen(tracker) * sizeof(char*));
  strcpy(modInfoObject.tracker, tracker);

  char *date = (char*)modFile->get_metadata("date").c_str();
  if (modInfoObject.date != nullptr) {
    free(modInfoObject.date);
  }
  modInfoObject.date = (char *)malloc(strlen(date) * sizeof(char*));
  strcpy(modInfoObject.date, date);

  char *message = (char*)modFile->get_metadata("message").c_str();
  if (modInfoObject.message != nullptr) {
    free(modInfoObject.message);
  }
  modInfoObject.message = (char *)malloc(strlen(message) * sizeof(char*));
  strcpy(modInfoObject.message, message);

  char *warnings = (char*)modFile->get_metadata("warnings").c_str();
  if (modInfoObject.warnings != nullptr) {
    free(modInfoObject.warnings);
  }
  modInfoObject.warnings = (char *)malloc(strlen(warnings) * sizeof(char*));
  strcpy(modInfoObject.warnings, warnings);

  modInfoObject.num_patterns = modFile->get_num_patterns();
  modInfoObject.num_channels =  modFile->get_num_channels();
  modInfoObject.num_samples =  modFile->get_num_samples();
  modInfoObject.num_instruments = modFile->get_num_instruments();
  modInfoObject.speed =  modFile->get_current_speed();
  modInfoObject.bpm =  modFile->get_current_tempo();
  modInfoObject.length =  modFile->get_duration_seconds();
  modInfoObject.num_orders =  modFile->get_num_orders() - 1;

  return modInfoObject;
}

void SoundManager::SetModPosition(int order) {
  if (! modFile) {
    return;
  }

  LockMutex();
  modFile->set_position_order_row(order, 0);
  UnlockMutex();
};

int SoundManager::Pause() {
  currentPlayMode = PLAY_MODE_PAUSED;
  int result = Pa_StopStream(stream);
  return result;
}

int SoundManager::Play() {
  int result = Pa_StartStream(stream);
  currentPlayMode = PLAY_MODE_PLAYING;
  return result;
}

int SoundManager::Stop() {
  int result = Pa_StopStream(stream);
  currentPlayMode = PLAY_MODE_STOPPED;
  return result;
}

void SoundManager::SetVolume(int newVolume) {
  if (newVolume <= 0) {
    soundVolume = 0;
    return;
  }

  soundVolume = (std::int32_t)(200.0f * ((float)newVolume * 0.1f));

  if (modFile != nullptr) {
    openmpt::ext::interactive *interactive = static_cast<openmpt::ext::interactive *>( modFile->get_interface( openmpt::ext::interactive_id ) );
    interactive->set_global_volume((double)newVolume * 0.01f);
  }
}

bool SoundManager::IsLoaded() {
  return modFile != nullptr;
}

int SoundManager::ShutDown() {
  Stop();
  usleep(100);
  delete modFile;
  int result = Pa_CloseStream(stream);

  delete ltBuffer;
  delete rtBuffer;


  if (modInfoObject.title != nullptr) free(modInfoObject.title);
  if (modInfoObject.artist != nullptr) free(modInfoObject.artist);
  if (modInfoObject.type != nullptr) free(modInfoObject.type);
  if (modInfoObject.type_long != nullptr) free(modInfoObject.type_long);
  if (modInfoObject.container != nullptr) free(modInfoObject.container);
  if (modInfoObject.container_long != nullptr) free(modInfoObject.container_long);
  if (modInfoObject.tracker != nullptr) free(modInfoObject.tracker);
  if (modInfoObject.date != nullptr) free(modInfoObject.date);
  if (modInfoObject.message != nullptr) free(modInfoObject.message);
  if (modInfoObject.warnings != nullptr) free(modInfoObject.warnings);
  return result;
}
