import 'dart:io';
import 'package:dart_openmpt/dart_openmpt.dart';
import 'package:dart_openmpt/dart_openmpt_structs.dart';
import 'package:ffi/ffi.dart';

import 'package:ansicolor/ansicolor.dart';

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

// print('col:${col} | row:${rowNum} | yPos:${yPos} | xPos:${xPos} | leftAvg:${leftAverage}');
//https://www.bbc.co.uk/bitesize/guides/zscvxfr/revision/4
// ▓ ▒ ░

List<String> fiveTrailingPatterns = ["","","","",""];

// Save position data locally
int prevOrd = -1;
int prevPat = -1;
int prevRow = -1;
int prevColumns = 0;
int prevRows = 0;

// Utility to draw the waveforms on screen
void drawBuffers(OpenMpt openMpt) {
  print("\x1B[0;0H"); //clear screen

  ModPosition pos = openMpt.getModPosition();
  List<List<String>> allPatterns = openMpt.getAllPatterns();
  StereoAudioBuffers buffers = openMpt.getStereoAudioBuffers();

  int numCols = stdout.terminalColumns - 1,
      numRows = stdout.terminalLines - 10;

  // Clear the screen IF we end up resizing the terminal
  if (numCols != prevColumns || numRows != prevRows) {
    print("\x1B[2J\x1B[0;0H");
  }

  prevColumns = numCols;
  prevRows = numRows;

  print('Song Title -> ${openMpt.modInfo.title.toDartString()}');

  // Move positions of items only if the song position information has changed
  if (pos.current_order != prevOrd || pos.current_pattern != prevPat || pos.current_row != prevRow) {
    fiveTrailingPatterns[0] = fiveTrailingPatterns[1];
    fiveTrailingPatterns[1] = fiveTrailingPatterns[2];
    fiveTrailingPatterns[2] = fiveTrailingPatterns[3];
    fiveTrailingPatterns[3] = fiveTrailingPatterns[4];
    fiveTrailingPatterns[4] = allPatterns[pos.current_pattern][pos.current_row];
  }

  int idx = 0;
  fiveTrailingPatterns.forEach((String str) {
    if (str.length >= numCols) {
      fiveTrailingPatterns[idx] = str.substring(0, numCols);
    }
    idx++;
  });

  // Cache the previous values for comparison for the next run
  prevOrd = pos.current_order;
  prevPat = pos.current_pattern;
  prevRow = pos.current_row;


  // Print out the five trailing patterns
  print(fiveTrailingPatterns[0]);
  print(fiveTrailingPatterns[1]);
  print(fiveTrailingPatterns[2]);
  print(fiveTrailingPatterns[3]);
  print(blueBgPen(fiveTrailingPatterns[4]));
  print('');

  //TODO: Investigate reuse versus recreation/destruction everytime this function is run.
  List<List<String>> screenBuffer = [];
  String emptyString = ' ';

  final int halfY = (numRows / 2).floor();
  final int halfX = (numCols / 2).floor();


  /* Create memory space to act as a psuedo screen buffer. While allocating the
     arrays of Strings, we add '-' or '|' (pipe character) to draw the X and Y
     axes.
     Is there a more efficient way of doing this?
   */
  for (int rowNum = 0; rowNum < numRows; rowNum++) {
    List<String> row = [];
    for (int col = 0; col < numCols; col++) {

      String str = emptyString;
      if (rowNum == halfY) {
        str = hyphen;
      }
      if (col == halfX) {
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
  for (int col = 0; col < halfX; col++) {
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
    int leftChannelY = halfY + (leftAverage * numRows / 2).floor();

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
  int pointerColumn = 0;
  for (int drawCol = halfX + 1; drawCol < numCols - 1; drawCol++) {
    double rightSum = 0;

    for (int sampleIdx = 0; sampleIdx < samplesPerDot; sampleIdx++) {
      int rtIndex = (pointerColumn * samplesPerDot) + sampleIdx;
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
    int rightChannelY = halfY + (rightAverage * numRows / 2).floor();

    if (rightChannelY < 0) {
      rightChannelY = 0;
    }
    if (rightChannelY > numRows) {
      rightChannelY = numRows - 1;
    }

    screenBuffer[rightChannelY][drawCol] = rightDot;
    pointerColumn++;
  }


  // Print the buffer
  for (int rowNum = 0; rowNum < numRows; rowNum++) {
    print(screenBuffer[rowNum].join(''));
  }

}

Future<void> main(List<String> args) async {
  // This is used for testing only.
  // OpenMpt openMpt = OpenMpt();
  // openMpt.openModFile('/Users/jgarcia/projects/dart/dart-mod-player/songs/Dungeon2.xm');


  // Check for args
  if (args.length < 1) {
    print('Error! Need a file name.');
    exit(1);
  }

  // Create instance of OpenMpt and use the passed file path to open the MOD file.
  OpenMpt openMpt = OpenMpt();
  openMpt.openModFile(args[0]);

  // Instruct the FFI connecting code to play the music.
  openMpt.playMusic();


  bool shouldContinue = true;

  // TODO: Figure out the best way to capture SIGINT and exit gracefully.
  // Catch CTRL+C (Signal Interrupt)
  // ProcessSignal.sigint.watch().forEach((signal) {
  //   shouldContinue = false;
  // });

  // Move Cursor 0,0 and clear the screen.
  print("\x1B[2J\x1B[0;0H");

  // For now this is an endless loop.
  while (true) {

    if (shouldContinue) {
      final stopwatch = Stopwatch()..start();
      drawBuffers(openMpt);
      // print('drawBuffers() executed in ${stopwatch.elapsed.inMilliseconds}');
      if (stopwatch.elapsed.inMilliseconds < 20) {
        int diff = 20 - stopwatch.elapsed.inMilliseconds;
        // sleep ONLY if we need to.
        if (diff > 0) {
          sleep(Duration(milliseconds: diff));
        }
      }

    }
  }

  // Use the FFI connector to stop the playing thread
  openMpt.stopMusic();

  // Use FFI to begin to clean things up.
  openMpt.shutdown();
}

