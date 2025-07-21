import 'dart:core';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:caracal_steg/dwt_codec.dart';
import 'package:caracal_steg/hadamard_codec.dart';
import 'package:caracal_steg/statistics.dart';
import 'package:image/image.dart';
import 'package:caracal_steg/lsb_codec.dart';
import 'package:caracal_steg/repetition_codecs.dart';

class EncodeCommand extends Command {
  @override
  final name = 'encode';

  @override
  final description = 'Steganographically encode a message in an image file.';

  EncodeCommand() {
    addSubcommand(EncodeLSBCommand());
    addSubcommand(EncodeDWTCommand());
  }
}

class DecodeCommand extends Command {
  @override
  final name = 'decode';

  @override
  final description = 'Decode a message from a file created by the encode command.';

  DecodeCommand() {
    addSubcommand(DecodeLSBCommand());
    addSubcommand(DecodeDWTCommand());
  }
}

class EncodeLSBCommand extends Command {
  @override
  final name = 'lsb';

  @override
  final description = 'Use the least-significant bit method of encoding.';

  EncodeLSBCommand() {
    argParser.addOption('quality',
        defaultsTo: '95',
        allowed: [for (var i = 0; i <= 100; i++) i.toString()],
        help: 'JPEG quality value of output file');
    argParser.addOption('input', help: 'Input file to embed a message within');
    argParser.addOption('output', help: 'Output file to place resulting file in');
    argParser.addOption('lsb',
        defaultsTo: '3',
        allowed: ['0', '1', '2', '3', '4', '5', '6', '7'],
        help: 'Which pixel RGB bit to use (0 is least-significant bit, 7 is most-significant bit)');
  }

  @override
  void run() {
    var resultsCopy = argResults!;
    if (resultsCopy['input'] == null || !FileSystemEntity.isFileSync(resultsCopy['input'])) {
      print('Provided input file path "${resultsCopy['input']}" is not a file');
      exit(1);
    }
    if (resultsCopy['output'] == null || FileSystemEntity.isDirectorySync(resultsCopy['output'])) {
      print('Provided output file path "${resultsCopy['output']}" is a directory or null');
      exit(1);
    }

    if (resultsCopy.rest.isEmpty) {
      print(usage);
      exit(1);
    }

    var inputImage = decodeImage(File(resultsCopy['input']).readAsBytesSync())!;
    var message = resultsCopy.rest.join(' ');
    var repetitions = (inputImage.length * 3) ~/ (message.length * 256);
    var coder = LSBSteganography.withECC(inputImage,
        ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions), int.parse(resultsCopy['lsb']));
    var image = coder.encodeMessage(message);
    File(resultsCopy['output']).writeAsBytesSync(encodeJpg(image, quality: int.parse(resultsCopy['quality'])));
    print('Encoded image with ${message.length} characters');
  }
}

class EncodeDWTCommand extends Command {
  @override
  final name = 'dwt';

  @override
  final description = 'Use the Haar wavelet transform method of encoding.';

  EncodeDWTCommand() {
    argParser.addOption('quality',
        defaultsTo: '95',
        allowed: [for (var i = 0; i <= 100; i++) i.toString()],
        help: 'JPEG quality value of output file');
    argParser.addOption('input', help: 'Input file to embed a message within');
    argParser.addOption('output', help: 'Output file to place resulting file in');
    argParser.addOption('width', help: 'Width to resize to');
    argParser.addOption('null', help: 'File to place reencoded image lacking a message in');
    argParser.addOption('lsb',
        defaultsTo: '2',
        allowed: ['1', '2', '3', '4', '5', '6', '7'],
        help: 'Which Haar approximation bit to use (0 is least-significant bit, 7 is most-significant bit)');
    argParser.addFlag('psnr', help: 'Whether to print PSNR');
    argParser.addFlag('decodability', help: 'Whether to print decodability');
  }

  @override
  void run() {
    var resultsCopy = argResults!;
    if (resultsCopy['input'] == null || !FileSystemEntity.isFileSync(resultsCopy['input'])) {
      print('Provided input file path "${resultsCopy['input']}" is not a file');
      exit(1);
    }
    if (resultsCopy['output'] == null || FileSystemEntity.isDirectorySync(resultsCopy['output'])) {
      print('Provided output file path "${resultsCopy['output']}" is a directory or null');
      exit(1);
    }

    if (resultsCopy.rest.isEmpty) {
      print(usage);
      exit(1);
    }

    var inputImage = decodeImage(File(resultsCopy['input']).readAsBytesSync())!;

    if (resultsCopy['width'] != null) {
      inputImage = copyResize(inputImage, width: int.parse(resultsCopy['width']));
    }
    if (inputImage.width % 8 != 0 || inputImage.height % 8 != 0) {
      var shrunkWidth = inputImage.width - inputImage.width % 8;
      var shrunkHeight = inputImage.height - inputImage.height % 8;
      inputImage = copyResize(inputImage, width: shrunkWidth, height: shrunkHeight);
    }

    var message = resultsCopy.rest.join(' ');
    var repetitions = (inputImage.length * 3) ~/ (message.length * 256 * 64);
    var coder = DWTStegnanography.withECC(inputImage,
        ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions), int.parse(resultsCopy['lsb']));
    var image = coder.encodeMessage(message);
    var outputImage = encodeJpg(image, quality: int.parse(resultsCopy['quality']));
    File(resultsCopy['output']).writeAsBytesSync(outputImage);
    print('Encoded image with ${message.length} characters');
    late List<int> reencodedBytes;
    late Image decodedOutputImage;
    if (resultsCopy['psnr'] || resultsCopy['null'] != null) {
      reencodedBytes = encodeJpg(inputImage, quality: int.parse(resultsCopy['quality']));
    }
    if (resultsCopy['psnr'] || resultsCopy['decodability']) {
      decodedOutputImage = decodeJpg(outputImage)!;
    }
    if (resultsCopy['psnr']) {
      var unmodifiedOutputImage = decodeJpg(reencodedBytes);
      print('PSNR compared to image without a message is ${psnr(unmodifiedOutputImage!, decodedOutputImage)}dB');
    }
    if (resultsCopy['null'] != null) {
      File(resultsCopy['null']).writeAsBytesSync(reencodedBytes);
    }
    if (resultsCopy['decodability']) {
      var decoder = DWTStegnanography.withECC(
          decodedOutputImage,
          ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions, (value) {
            return (value >= 32) && (value <= 126);
          }));
      var decodedMessage = decoder.decodeMessage(message.length);
      print('Decodability is ${stringSimilarity(message, decodedMessage) * 100}%');
      print("Decoded message is '$decodedMessage'");
    }
  }
}

class DecodeLSBCommand extends Command {
  @override
  final name = 'lsb';

  @override
  final description = 'Use the least-significant bit method of decoding.';

  DecodeLSBCommand() {
    argParser.addOption('input', help: 'Input file to embed a message within');
    argParser.addOption('numChars', help: 'Length of embedded message');
    argParser.addOption('lsb',
        defaultsTo: '3',
        allowed: ['0', '1', '2', '3', '4', '5', '6', '7'],
        help: 'Which pixel RGB bit to use (0 is least-significant bit, 7 is most-significant bit)');
  }

  @override
  void run() {
    var resultsCopy = argResults!;
    if (resultsCopy['input'] == null || !FileSystemEntity.isFileSync(resultsCopy['input'])) {
      print('Provided input file path "${resultsCopy['input']}" is not a file');
      exit(1);
    }

    var inputImage = decodeImage(File(resultsCopy['input']).readAsBytesSync())!;
    var messageLength = int.parse(resultsCopy['numChars']);
    var repetitions = (inputImage.length * 3) ~/ (messageLength * 256);
    var coder = LSBSteganography.withECC(
        inputImage,
        ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions, (value) {
          return (value >= 32) && (value <= 126);
        }),
        int.parse(resultsCopy['lsb']));
    print(coder.decodeMessage(messageLength));
  }
}

class DecodeDWTCommand extends Command {
  @override
  final name = 'dwt';

  @override
  final description = 'Use the Haar wavelet transform method of decoding.';

  DecodeDWTCommand() {
    argParser.addOption('input', help: 'Input file to embed a message within');
    argParser.addOption('numChars', help: 'Length of embedded message');
    argParser.addOption('lsb',
        defaultsTo: '2',
        allowed: ['1', '2', '3', '4', '5', '6', '7'],
        help: 'Which Haar approximation bit to use (0 is least-significant bit, 7 is most-significant bit)');
  }

  @override
  void run() {
    var resultsCopy = argResults!;
    if (resultsCopy['input'] == null || !FileSystemEntity.isFileSync(resultsCopy['input'])) {
      print('Provided input file path "${resultsCopy['input']}" is not a file');
      exit(1);
    }

    var inputImage = decodeImage(File(resultsCopy['input']).readAsBytesSync())!;
    if (inputImage.width % 8 != 0 || inputImage.height % 8 != 0) {
      var shrunkWidth = inputImage.width - inputImage.width % 8;
      var shrunkHeight = inputImage.height - inputImage.height % 8;
      inputImage = copyResize(inputImage, width: shrunkWidth, height: shrunkHeight);
    }
    var messageLength = int.parse(resultsCopy['numChars']);
    var repetitions = (inputImage.length * 3) ~/ (messageLength * 256 * 64);
    var coder = DWTStegnanography.withECC(
        inputImage,
        ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions, (value) {
          return ((value >= 32) && (value <= 126));
        }),
        //BitMajorityRepetitionCorrection(HadamardErrorCorrection(), repetitions),
        int.parse(resultsCopy['lsb']));
    print(coder.decodeMessage(messageLength));
  }
}

void main(List<String> arguments) {
  var runner = CommandRunner('caracal_steg', 'Dart steganography command-line application')
    ..addCommand(EncodeCommand())
    ..addCommand(DecodeCommand());
  var stopwatch = Stopwatch()..start();
  runner.run(arguments);
  print('Took ${stopwatch.elapsedMilliseconds}ms');
}
