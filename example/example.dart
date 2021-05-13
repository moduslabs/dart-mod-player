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

final leftDot = bluePen('█');
final rightDot = redPen('█');
final purpleDot = redPen('█');
final hyphen = grayPen('─');
// print('col:${col} | row:${rowNum} | yPos:${yPos} | xPos:${xPos} | leftAvg:${leftAverage}');
//https://www.bbc.co.uk/bitesize/guides/zscvxfr/revision/4
// ▓ ▒ ░

List<String> fiveTrailingPatterns = ["","","","",""];


int prevOrd = -1;
int prevPat = -1;
int prevRow = -1;
int prevColumns = 0;
int prevRows = 0;


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

  if (pos.current_order != prevOrd || pos.current_pattern != prevPat || pos.current_row != prevRow) {
    // move positions of items
    fiveTrailingPatterns[0] = fiveTrailingPatterns[1];
    fiveTrailingPatterns[1] = fiveTrailingPatterns[2];
    fiveTrailingPatterns[2] = fiveTrailingPatterns[3];
    fiveTrailingPatterns[3] = fiveTrailingPatterns[4];
    fiveTrailingPatterns[4] = allPatterns[pos.current_pattern][pos.current_row];
  }

  int idx = 0;
  fiveTrailingPatterns.forEach((String str) {
    if (str.length >= numCols) {
      fiveTrailingPatterns[idx++] = str.substring(0, numCols);
    }
  });

  prevOrd = pos.current_order;
  prevPat = pos.current_pattern;
  prevRow = pos.current_row;


  print(fiveTrailingPatterns[0]);
  print(fiveTrailingPatterns[1]);
  print(fiveTrailingPatterns[2]);
  print(fiveTrailingPatterns[3]);
  print(blueBgPen(fiveTrailingPatterns[4]));
  print('');
  
  List<List<String>> screenBuffer = [];
  String emptyString = ' ';

  final int halfY = (numRows / 2).floor();
  final int halfX = (numCols / 2).floor();


  // Create memory space to act as a screen buffer
  // (could not figure out a way to do this en mass)
  for (int rowNum = 0; rowNum < numRows; rowNum++) {
    List<String> row = [];
    for (int col = 0; col < numCols; col++) {

      String str = emptyString;
      if (rowNum == halfY) {
        str = hyphen;
      }
      if (col == halfX) {
        str = '│';
      }
      row.add(str);
    }

    screenBuffer.add(row);
  }

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
      if (leftSum.isNaN){
        leftSum = 0; // Hack
      }
    }


    double leftAverage = leftSum / samplesPerDot;
    int leftChannelY = halfY + (leftAverage * numRows / 2).floor();

    if (leftChannelY < 0) {
      leftChannelY = 0;
    }
    if (leftChannelY > numRows) {
      leftChannelY = numRows - 1;
    }

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
    print("${screenBuffer[rowNum].join('')}");
  }

}

Future<void> main(List<String> args) async {


  // This is used for testing only.
  // OpenMpt openMpt = OpenMpt();
  // openMpt.openModFile('/Users/jgarcia/projects/dart/dart_openmpt/lib/OpenMPT/songs/Dungeon2.xm');


  if (args.length < 1) {
    print('Error! Need a file name.');
    exit(1);
  }
  OpenMpt openMpt = OpenMpt();
  openMpt.openModFile(args[0]);

  openMpt.playMusic();


  bool shouldContinue = true;

  //TODO: why doesn't this work?
  // Catch CTRL+C (Signal Interrupt)
  // ProcessSignal.sigint.watch().forEach((signal) {
  //   shouldContinue = false;
  // });

  // Move Cursor 0,0
  print("\x1B[2J\x1B[0;0H");

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

  openMpt.stopMusic();

  openMpt.shutdown();
}

