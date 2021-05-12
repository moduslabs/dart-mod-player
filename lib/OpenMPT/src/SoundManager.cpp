#include "SoundManager.h"
#include <thread>
#include <mutex>
#include <cstring>

static openmpt::module_ext *modFile = nullptr;
std::mutex mutex;

#define BUFFER_SIZE 1024

static int playMode = 0; // 0 stopped, 1 playing, 2 paused;
static double soundVolume = 0; //[ 0 - 200 ];

typedef struct {
  float left_phase;
  float right_phase;
} paTestData;

static paTestData data;

static int currentModData[4];

ModInfo modInfoObject;
ModPosition modPosition;
static const int numBuffers = BUFFER_SIZE / 2;

static float *ltBuffer = (float *) malloc(numBuffers * sizeof (float));
static float *rtBuffer = (float *) malloc(numBuffers * sizeof (float));


static const size_t bufferSize =  numBuffers;



static int static_paStreamCallback(const void *inputBuffer,
                                   void *outputBuffer,
                                   unsigned long numFrames,
                                   const PaStreamCallbackTimeInfo* timeInfo,
                                   PaStreamCallbackFlags statusFlags,
                                   void *userData )  {

  /* Prevent unused variable warning. */
  (void) inputBuffer;
  (void) timeInfo;
  (void) inputBuffer;
  (void) userData;



  if (statusFlags == paOutputUnderflow) {
    printf("Underflow!!\n");
  }

  auto *out = (float*)outputBuffer;

  if (modFile != nullptr) {

    modFile->read_interleaved_stereo(44100, numFrames, out);

    mutex.lock();

    currentModData[0] = (int)modFile->get_current_order();
    currentModData[1] = (int)modFile->get_current_pattern();
    currentModData[2] = (int)modFile->get_current_row();
    currentModData[3] = (int)modFile->get_pattern_num_rows(currentModData[1]);

    auto *outBuff = (float *)outputBuffer;

    for (int i = 0; i < numBuffers; ++i) {
      ltBuffer[i] = outBuff[i];
      rtBuffer[i] = outBuff[i+1];
    }

//    memset(outputBuffer, 0, numFrames * sizeof(outputBuffer));
  }

  mutex.unlock();

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
      0,      /* no input channels */
    2,      /* stereo output */
    paFloat32,  /* 32 bit floating point output */
    44100,    // Sample Rate
    BUFFER_SIZE,    /* frames per buffer */
    static_paStreamCallback,
      &data
  );

  if( err != paNoError ) goto error;

  return err;

error:
  Pa_Terminate();
  fprintf(stderr, "An error occured while using the portaudio stream\n");
  fprintf(stderr, "Error number: %d\n", err);
  fprintf(stderr, "Error message: %s\n", Pa_GetErrorText(err));
  return err;
}


int SoundManager::currentOrder = -1;
int SoundManager::currentPattern = -1;
int SoundManager::currentRow = -1;

int SoundManager::InitSound() {
  currentOrder = -1,
  currentPattern = -1,
  currentRow = -1;

  fflush(stdout);
  return initializePortAudio();
}


void SoundManager::Run() {

  mutex.lock();

  currentModData[0] = -1;
  currentModData[1] = -1;
  currentModData[2] = -1;
  currentModData[3] = -1;

  mutex.unlock();

  int prevOrder = 0;

  while (playMode > 0 && modFile) {
    SoundManager::GetStereoAudioBuffers();
    mutex.lock();

    if (currentOrder != currentModData[0] || currentPattern != currentModData[1] || currentRow != currentModData[2]) {
//      printf("Order %i -- Pattern %i -- Row %i\n", currentOrder, currentPattern, currentRow);


      currentOrder   = currentModData[0];
      currentPattern = currentModData[1];
      currentRow     = currentModData[2];

      modPosition.current_order = currentOrder;
      modPosition.current_pattern = currentPattern;
      modPosition.current_row = currentRow;

      if (currentOrder != prevOrder) {
        prevOrder = currentOrder;
        printf("\n");
      }

//      int orderPattern = modFile->get_order_pattern(currentOrder);

//      for (int i = 0; i < modInfoObject.num_channels; ++i) {
//        printf("%s",  modFile->format_pattern_row_channel(currentPattern, currentRow, i, 0, true).c_str());
//        if (i < modInfoObject.num_channels) {
//          printf("|");
//        }
//      }
//      printf("\n");
//      char *rowString  =
    }

    mutex.unlock();
    usleep(5000);
  }

  SoundManager::Stop();
}



ModPosition SoundManager::GetModPosition() {
  mutex.lock();

  ModPosition position = {
    .current_order = (int)modFile->get_current_order(),
    .current_pattern = (int)modFile->get_current_pattern(),
    .current_row = (int)modFile->get_current_row()
  };

  mutex.unlock();
  return position;
}

StereoAudioBuffers SoundManager::GetStereoAudioBuffers() {
  StereoAudioBuffers buffers = {};

  buffers.numItems = numBuffers;
  buffers.left_buffer = (double*)malloc(numBuffers * sizeof(double));
  buffers.right_buffer = (double*)malloc(numBuffers * sizeof(double));

  mutex.lock();
  for (int i = 0; i < bufferSize; ++i) {
//    printf("%i (%lu) | %5f\n", i, bufferSize, ltBuffer[i]);fflush(stdout);
    buffers.left_buffer[i] = ltBuffer[i];
    buffers.right_buffer[i] = rtBuffer[i];
  }
//  memcpy(buffers.left_buffer, ltBuffer, bufferSize);
//  memcpy(buffers.right_buffer, rtBuffer, bufferSize);
  mutex.unlock();

  return buffers;
}

int SoundManager::LoadFile(char * filePath) {
  SoundManager::Stop();


  std::ifstream file(filePath, std::ios::binary);

  int loadResult = openmpt::probe_file_header(openmpt::probe_file_header_flags_default, file);

  if (loadResult == openmpt::probe_file_header_result_success) {
    static openmpt::module_ext *newModFile = nullptr;

    newModFile = new openmpt::module_ext(file);
    // Todo:: Setup as a configuration option from the UI
    newModFile->set_repeat_count(999999);
    newModFile->set_render_param(3, 1);
    openmpt::ext::interactive *interactive = static_cast<openmpt::ext::interactive *>(newModFile->get_interface(openmpt::ext::interactive_id));

    interactive->set_global_volume(1);

    SoundManager::Pause();

    mutex.lock(); // Likely unnecessary.

    delete modFile;
    modFile = newModFile;

    mutex.unlock();

    return SND_MGR_NO_ERROR;
  }

  return SND_MGR_ERR_LOAD_FILE;
}

ArrayOfStrings SoundManager::GetPattern(int patternNum) {
//  printf("%s %i\n", __PRETTY_FUNCTION__ , patternNum);

  ArrayOfStrings strings = {};
  strings.numItems = modFile->get_pattern_num_rows(patternNum);
  strings.items = (char**)malloc(strings.numItems * sizeof(char *));


  for (int currentRow = 0; currentRow < strings.numItems; ++currentRow) {
    std::string rowString;

    for (int i = 0; i < modInfoObject.num_channels; ++i) {
      rowString = rowString.append(modFile->format_pattern_row_channel(patternNum, currentRow, i, 0, true));
      if (i < modInfoObject.num_channels - 1) {
        rowString = rowString.append("|");
      }
    }

    strings.items[currentRow] = (char*)malloc(rowString.length() * sizeof (char*) + 1 );
    strcpy(strings.items[currentRow], rowString.c_str());

//    printf("Row: %i -- %s \n", currentRow, rowString.c_str());
//    std::string rowNum = std::to_string(currentRow);
//    if (currentRow < 10) {
//      rowNum.insert(0, 1, '0');
//    }
//    printf("R: %s : %s \n", rowNum.c_str(), strings.items[currentRow]);
  }

  return strings;
}

ModInfo SoundManager::GetModInfo() {
//  printf("%s\n", __PRETTY_FUNCTION__ );

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

  mutex.lock();
  modFile->set_position_order_row(order, 0);
  mutex.unlock();
};

void SoundManager::Pause() {
  mutex.lock();

  playMode = 2;
  Pa_StopStream(stream);

  mutex.unlock();
}

void SoundManager::Play() {
  mutex.lock();
  playMode = 1;

  int result = Pa_StartStream(stream);
  printf("Pa_StartStream result = %i\n", result);
  mutex.unlock();
}

void SoundManager::Stop() {
  mutex.lock();
  playMode = 0;
  Pa_StopStream(stream);
  mutex.unlock();
}

void SoundManager::SetVolume(int newVolume) {
  if (newVolume == 0) {
    soundVolume = 0;
    return;
  }

  soundVolume = (std::int32_t)(200.0f * ((float)newVolume * 0.1f));

  if (modFile != nullptr) {
    openmpt::ext::interactive *interactive = static_cast<openmpt::ext::interactive *>( modFile->get_interface( openmpt::ext::interactive_id ) );
//    interactive->set_global_volume((double)globalStateObject->getState("volume").toInt() * 0.01f);
  }
}


void SoundManager::ShutDown() {
  Stop();
  usleep(100);
  delete modFile;
  Pa_CloseStream(stream);

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
}
