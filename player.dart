import 'dart:io';
import 'package:dart_openmpt/dart_openmpt.dart';
import 'package:dart_openmpt/dart_openmpt_structs.dart';
import 'package:ffi/ffi.dart';
import 'package:ansicolor/ansicolor.dart';

// Colored "AnsiPen" instances to draw characters
AnsiPen whitePen = new AnsiPen()..white();
AnsiPen redPen = new AnsiPen()..red();
AnsiPen bluePen = new AnsiPen()..blue();
AnsiPen purplePen = new AnsiPen()..magenta();
AnsiPen grayPen = new AnsiPen()..gray();
AnsiPen greenPen =  new AnsiPen()..green();
AnsiPen yellowPen =  new AnsiPen()..yellow();
AnsiPen blueBgPen = new AnsiPen()..blue(bg:true);

// Colored Strings used to plot the Audio wave forms
final String leftDot = bluePen('▓');
final String leftDotAlt = yellowPen('▓');
final String rightDot = redPen('▓');
final String rightDotAlt = greenPen('▓');
final String hyphen = grayPen('─');
final String pipeChar = grayPen('│');
final String spaceChar = ' ';


//https://www.bbc.co.uk/bitesize/guides/zscvxfr/revision/4
// ▓ ▒ ░

void clearScreen({bool hard = false}) {
  if (hard) {
    // Move Cursor 0,0 and clear the screen.
    print("\x1B[2J\x1B[0;0H");
  }
  else {
    // Move cursor to 0,0
    print("\x1B[0;0H");
  }
}

List<String> patternbuffer = ["","","","",""];

// Save position data locally
int prevOrd = -1;
int prevPat = -1;
int prevRow = -1;
int prevColumns = 0;
int prevRows = 0;

int midY = 0;
int midX = 0;
List<List<String>> allPatterns = [['']];

/*
   Create memory space to act as a psuedo screen buffer. While allocating the
   arrays of Strings, we add '-' or '|' (pipe character) to draw the X and Y
   axes.
   Is there a more efficient way of doing this?
*/
List<List<String>> newWaveformScreenBuffer(int numCols, int numRows) {

  List<List<String>> screenBuffer = [];

  for (int rowNum = 0; rowNum < numRows; rowNum++) {
    List<String> row = [];
    for (int col = 0; col < numCols; col++) {

      String str = spaceChar;
      if (rowNum == midY) {
        str = hyphen;
      }

      if (col == midX) {
        str = pipeChar;
      }
      row.add(str);
    }

    screenBuffer.add(row);
  }

  return screenBuffer;
}

void drawLiveWaveform(List<List<String>> screenBuffer, StereoAudioBuffers buffers, int numCols, int numRows) {

  // We use samplesPerDot to create averages of values so the waveform can make
  // use of the full 512 values per stereo channel.
  int samplesPerDot = (buffers.num_items / (numCols / 2)).floor();

  // LEFT channel
  for (int col = 0; col < midX; col++) {
    double leftSum = 0;
    for (int sampleIdx = 0; sampleIdx < samplesPerDot; sampleIdx++) {

      int ltIndex = (col * samplesPerDot) +  sampleIdx;
      if (ltIndex > buffers.left_buffer.length - 1) {
        ltIndex = buffers.left_buffer.length - 1;
      }

      leftSum += buffers.left_buffer[ltIndex];;
      if (leftSum.isNaN) { // TODO: Why do we get NaN sometimes? :(
        leftSum = 0; // Hack
      }
    }

    double leftAverage = leftSum / samplesPerDot;
    int leftChannelY = midY + (leftAverage * numRows / 2).floor();

    // Set the ceiling.
    if (leftChannelY < 0) {
      leftChannelY = 0;
    }

    // Set the floor.
    if (leftChannelY > numRows) {
      leftChannelY = numRows - 1;
    }

    // Plot the value in the psuedo screen buffer.
    screenBuffer[leftChannelY][col] = leftDot;
  }
  // RIGHT channel
  int iterationNum = 0;
  for (int drawCol = midX + 1; drawCol < numCols; drawCol++) {
    double rightSum = 0;

    for (int sampleIdx = 0; sampleIdx < samplesPerDot; sampleIdx++) {
      int rtIndex = (iterationNum * samplesPerDot) + sampleIdx;
      if (rtIndex > buffers.right_buffer.length - 1) {
        rtIndex = buffers.right_buffer.length - 1;
      }

      double rtBufferVal = buffers.right_buffer[rtIndex];
      rightSum += rtBufferVal;
      if (rightSum.isNaN) {
        rightSum = 0; // Hack
      }
    }

    double rightAverage = rightSum / samplesPerDot;
    int rightChannelY = midY + (rightAverage * numRows / 2).floor();

    // Set the ceiling.
    if (rightChannelY < 0) {
      rightChannelY = 0;
    }

    // Set the floor.
    if (rightChannelY > numRows) {
      rightChannelY = numRows - 1;
    }

    // Plot the value in the psuedo screen buffer.
    screenBuffer[rightChannelY][drawCol] = rightDot;
    iterationNum++;
  }

}

List<int> priorLeftValues = [];
List<int> priorRightValues = [];

void drawTimedWaveform(List<List<String>> screenBuffer, StereoAudioBuffers buffers, int numCols, int numRows) {
  int numValues = priorLeftValues.length - 1;
  int floor = ((numRows) * .9).floor();

  // If we grew horizontally
  if (numValues < midX) {
    for (int i = numValues; i < midX; i++) {
      priorLeftValues.add(0);
      priorRightValues.add(0);
    }
  }

  // If we shrank horizontally
  if (numValues > midX) {
    for (int i = 0; i < numValues - midX; i++) {
      priorLeftValues.removeAt(0);
      priorRightValues.removeAt(0);
    }
  }

  /**** L E F T   V A L U E S  ****/
  double leftValue = 0;
  for (int i = 0; i < buffers.left_buffer.length - 1; i++) {
    leftValue += buffers.left_buffer[i].abs();
  }

  leftValue = (leftValue * 2) / buffers.left_buffer.length;
  priorLeftValues.removeAt(0);
  priorLeftValues.add((leftValue * midY).floor());

  for (int col = 0; col < priorLeftValues.length - 1; col++) {
    int val = priorLeftValues[col];
    int leftChannelY = midY + val;
    // Floor (bottom)
    if (leftChannelY >= floor) {
      leftChannelY = floor;
    }

    // Ceiling (top)
    if (leftChannelY < 0) {
      leftChannelY = 0;
    }

    screenBuffer[leftChannelY][col] = leftDot;

    int yStop = (leftChannelY - midY) + 1;
    for (int y = leftChannelY; y > (midY - yStop); y--) {
      screenBuffer[y][col] = leftDot;
    }
  }

  /**** R I G H T   V A L U E S ****/

  double rightValue = 0;
  for (int i = 0; i < buffers.right_buffer.length - 1; i++) {
    rightValue += buffers.right_buffer[i].abs();
  }

  rightValue = (rightValue * 2) / buffers.right_buffer.length;
  priorRightValues.removeAt(0);
  priorRightValues.add((rightValue * midY).floor());

  int index = 0;

  for (int col = midX + 1; col < numCols; col++) {
    int val = priorRightValues[index];
    int rightChannelY = midY + val;
    // Floor (bottom)
    if (rightChannelY >= floor) {
      rightChannelY = floor;
    }

    // Ceiling (top)
    if (rightChannelY < 0) {
      rightChannelY = 0;
    }

    screenBuffer[rightChannelY][col] = leftDot;

    int yStop = (rightChannelY - midY) + 1;
    for (int y = rightChannelY; y > (midY - yStop); y--) {
      screenBuffer[y][col] = rightDot;
    }

    index++;
  }
}


enum mode_type {
  LIVE_WAVEFORM,
  TIMED_WAVEFORM
}

// Used to toggle modes
int mode = mode_type.LIVE_WAVEFORM.index;

// Utility to draw the waveforms on screen
void drawAudioBuffers(OpenMpt openMpt) {

  ModPosition pos = openMpt.getModPosition();
  StereoAudioBuffers buffers = openMpt.getStereoAudioBuffers();

  int numCols = stdout.terminalColumns - 1,
      numRows = stdout.terminalLines - 9;

  // Clear the screen IF we end up resizing the terminal
  if (numCols != prevColumns || numRows != prevRows) {
    clearScreen(hard:true);
    midY = (numRows / 2).floor();
    midX = (numCols / 2).floor();
  }
  else {
    clearScreen(hard:false);
  }

  // cache previous values
  prevColumns = numCols;
  prevRows = numRows;

  print('Song Title -> ${openMpt.modInfo.title.toDartString()}');

  // Move positions of items only if the song position information has changed
  if (pos.current_order != prevOrd || pos.current_pattern != prevPat || pos.current_row != prevRow) {
    patternbuffer.removeAt(0);
    patternbuffer.add(allPatterns[pos.current_pattern][pos.current_row]);
  }

  // Cache the previous values for comparison for the next run
  prevOrd = pos.current_order;
  prevPat = pos.current_pattern;
  prevRow = pos.current_row;


  // Print out the five trailing patterns
  for (int idx = 0; idx < patternbuffer.length; idx++) {
    String str = patternbuffer[idx];

    if (str.length >= numCols) {
      patternbuffer[idx] = str.substring(0, numCols);
    }

    if (idx == patternbuffer.length - 1) {
      print(blueBgPen(patternbuffer[idx]));
    }
    else {
      print(patternbuffer[idx]);
    }
  }

  // Add one line underneath the pattern view
  print('');

  // Destroy prior array and start anew.
  List<List<String>> screenBuffer = newWaveformScreenBuffer(numCols, numRows);

  if (mode == mode_type.LIVE_WAVEFORM.index) {
    // Draw the live waveform
    drawLiveWaveform(screenBuffer, buffers, numCols, numRows);
  }
  else if (mode == mode_type.TIMED_WAVEFORM.index){
    drawTimedWaveform(screenBuffer, buffers, numCols, numRows);
  }

  // Print screen buffer
  for (int rowNum = 0; rowNum < numRows; rowNum++) {
    print(screenBuffer[rowNum].join(''));
  }
}

bool shouldContinue = true;
OpenMpt openMpt = OpenMpt();

void updateView() {
  if (shouldContinue) {
    final stopwatch = Stopwatch()..start();

    drawAudioBuffers(openMpt);
    int diff = 20 - stopwatch.elapsed.inMilliseconds;
    // sleep ONLY if we need to.
    if (diff < 0) {
      diff = 0;
    }

    Future.delayed(Duration(milliseconds: diff), updateView);
  }
}

main(List<String> args)  {
  // Check for args
  if (args.length < 1) {
    print('Error! Need a file name.');
    exit(1);
  }

  // Create instance of OpenMpt and use the passed file path to open the MOD file.
  openMpt.openModFile(args[0]);
  allPatterns = openMpt.getAllPatterns();

  // Instruct the FFI connecting code to play the music.
  openMpt.playMusic();

  // Begin Drawing
  updateView();

  // Read stdin and allow any key press to change the mode
  stdin.lineMode = false;
  stdin.echoMode = false;

  stdin.forEach((element) {
    mode = (mode == mode_type.LIVE_WAVEFORM.index)
        ? mode_type.TIMED_WAVEFORM.index : mode_type.LIVE_WAVEFORM.index;
  });

  ProcessSignal.sigint.watch().forEach((signal) {
    shouldContinue = false;
    clearScreen(hard:true);

    // Use the FFI connector to stop the playing thread
    openMpt.stopMusic();

    // Use FFI to begin to clean things up.
    openMpt.shutdown();
    exit(0);
  });

}

