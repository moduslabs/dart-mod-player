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
AnsiPen blueBgPen = new AnsiPen()..blue(bg:true);

// Colored Strings used to plot the Audio wave forms
final String leftDot = bluePen('▓');
final String rightDot = redPen('▓');
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

List<String> fiveTrailingPatterns = ["","","","",""];

// Save position data locally
int prevOrd = -1;
int prevPat = -1;
int prevRow = -1;
int prevColumns = 0;
int prevRows = 0;

int midY = 0;
int midX = 0;

// Utility to draw the waveforms on screen
void drawBuffers(OpenMpt openMpt) {

  ModPosition pos = openMpt.getModPosition();
  List<List<String>> allPatterns = openMpt.getAllPatterns();
  StereoAudioBuffers buffers = openMpt.getStereoAudioBuffers();

  int numCols = stdout.terminalColumns - 1,
      numRows = stdout.terminalLines - 8;

  // Clear the screen IF we end up resizing the terminal
  if (numCols != prevColumns || numRows != prevRows) {
    clearScreen(hard:false);
    midY = (numRows / 2).floor();
    midX = (numCols / 2).floor();
  }
  else {
    clearScreen(hard:true);
  }


  prevColumns = numCols;
  prevRows = numRows;

  print('Song Title -> ${openMpt.modInfo.title.toDartString()}');

  // Move positions of items only if the song position information has changed
  if (pos.current_order != prevOrd || pos.current_pattern != prevPat || pos.current_row != prevRow) {
    fiveTrailingPatterns.removeAt(0);
    fiveTrailingPatterns.add(allPatterns[pos.current_pattern][pos.current_row]);
  }

  // Cache the previous values for comparison for the next run
  prevOrd = pos.current_order;
  prevPat = pos.current_pattern;
  prevRow = pos.current_row;


  // Print out the five trailing patterns
  int idx = 0;
  fiveTrailingPatterns.forEach((String str) {
    if (str.length >= numCols) {
      fiveTrailingPatterns[idx] = str.substring(0, numCols);
    }

    if (idx == 4) {
      print(blueBgPen(fiveTrailingPatterns[idx]));
    }
    else {
      print(fiveTrailingPatterns[idx]);
    }

    idx++;
  });

  print('');


  //TODO: Investigate reuse versus recreation/destruction everytime this function is run.
  List<List<String>> screenBuffer = [];

  /* Create memory space to act as a psuedo screen buffer. While allocating the
     arrays of Strings, we add '-' or '|' (pipe character) to draw the X and Y
     axes.
     Is there a more efficient way of doing this?
   */
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


  // Print the buffer
  for (int rowNum = 0; rowNum < numRows; rowNum++) {
    print(screenBuffer[rowNum].join(''));
  }
}

bool shouldContinue = true;
OpenMpt openMpt = OpenMpt();

void updateView() {
  if (shouldContinue) {
    final stopwatch = Stopwatch()..start();

    drawBuffers(openMpt);
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

  // Instruct the FFI connecting code to play the music.
  openMpt.playMusic();

  // Begin Drawing
  updateView();

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

