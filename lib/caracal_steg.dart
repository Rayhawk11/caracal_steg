import 'dart:core';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:caracal_steg/dwt_codec.dart';
import 'package:caracal_steg/hadamard_codec.dart';
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
    if (argResults['input'] == null || !FileSystemEntity.isFileSync(argResults['input'])) {
      print('Provided input file path "${argResults['input']}" is not a file');
      exit(1);
    }
    if (argResults['output'] == null || FileSystemEntity.isDirectorySync(argResults['output'])) {
      print('Provided output file path "${argResults['output']}" is a directory or null');
      exit(1);
    }

    if (argResults.rest.isEmpty) {
      print(usage);
      exit(1);
    }

    var inputImage = decodeImage(File(argResults['input']).readAsBytesSync());
    var message = argResults.rest.join(' ');
    var repetitions = (inputImage.length * 3) ~/ (message.length * 256);
    var coder = LSBSteganography.withECC(inputImage,
        ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions), int.parse(argResults['lsb']));
    coder.encodeMessage(message);
    File(argResults['output']).writeAsBytesSync(encodeJpg(coder.image, quality: int.parse(argResults['quality'])));
  }
}

class EncodeDWTCommand extends Command {
  @override
  final name = 'dwt';

  @override
  final description = 'Use the discrete wavelet transform method of encoding.';

  EncodeDWTCommand() {
    argParser.addOption('quality',
        defaultsTo: '95',
        allowed: [for (var i = 0; i <= 100; i++) i.toString()],
        help: 'JPEG quality value of output file');
    argParser.addOption('input', help: 'Input file to embed a message within');
    argParser.addOption('output', help: 'Output file to place resulting file in');
    argParser.addOption('lsb',
        defaultsTo: '2',
        allowed: ['0', '1', '2', '3', '4', '5', '6', '7'],
        help: 'Which Haar approximation bit to use (0 is least-significant bit, 7 is most-significant bit)');
  }

  @override
  void run() {
    if (argResults['input'] == null || !FileSystemEntity.isFileSync(argResults['input'])) {
      print('Provided input file path "${argResults['input']}" is not a file');
      exit(1);
    }
    if (argResults['output'] == null || FileSystemEntity.isDirectorySync(argResults['output'])) {
      print('Provided output file path "${argResults['output']}" is a directory or null');
      exit(1);
    }

    if (argResults.rest.isEmpty) {
      print(usage);
      exit(1);
    }

    var inputImage = decodeImage(File(argResults['input']).readAsBytesSync());
    var message = argResults.rest.join(' ');
    var repetitions = ((inputImage.length * 3) ~/ 4) ~/ (message.length * 256);
    var coder = DWTStegnanography.withECC(inputImage,
        BitMajorityRepetitionCorrection(HadamardErrorCorrection(), repetitions), int.parse(argResults['lsb']));
    coder.encodeMessage(message);
    File(argResults['output']).writeAsBytesSync(encodeJpg(coder.image, quality: int.parse(argResults['quality'])));
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
        defaultsTo: '2',
        allowed: ['0', '1', '2', '3', '4', '5', '6', '7'],
        help: 'Which pixel RGB bit to use (0 is least-significant bit, 7 is most-significant bit)');
  }

  @override
  void run() {
    if (argResults['input'] == null || !FileSystemEntity.isFileSync(argResults['input'])) {
      print('Provided input file path "${argResults['input']}" is not a file');
      exit(1);
    }

    var inputImage = decodeImage(File(argResults['input']).readAsBytesSync());
    var messageLength = int.parse(argResults['numChars']);
    var repetitions = (inputImage.length * 3) ~/ (messageLength * 256);
    var coder = LSBSteganography.withECC(
        inputImage,
        ValuePluralityRepetitionCorrection(HadamardErrorCorrection(), repetitions, (value) {
          return (value >= 32) && (value <= 126);
        }),
        int.parse(argResults['lsb']));
    print(coder.decodeMessage(messageLength));
  }
}

class DecodeDWTCommand extends Command {
  @override
  final name = 'dwt';

  @override
  final description = 'Use the least-significant bit method of decoding.';

  DecodeDWTCommand() {
    argParser.addOption('input', help: 'Input file to embed a message within');
    argParser.addOption('numChars', help: 'Length of embedded message');
    argParser.addOption('lsb',
        defaultsTo: '3',
        allowed: ['0', '1', '2', '3', '4', '5', '6', '7'],
        help: 'Which Haar approximation bit to use (0 is least-significant bit, 7 is most-significant bit)');
  }

  @override
  void run() {
    if (argResults['input'] == null || !FileSystemEntity.isFileSync(argResults['input'])) {
      print('Provided input file path "${argResults['input']}" is not a file');
      exit(1);
    }

    var inputImage = decodeImage(File(argResults['input']).readAsBytesSync());
    var messageLength = int.parse(argResults['numChars']);
    var repetitions = ((inputImage.length * 3) ~/ 4) ~/ (messageLength * 256);
    var coder = DWTStegnanography.withECC(
        inputImage,
        /*BitMajorityRepetitionCorrection(HadamardErrorCorrection(), repetitions, (value) {
          return (value >= 32) && (value <= 126);
        }),*/
        BitMajorityRepetitionCorrection(HadamardErrorCorrection(), repetitions),
        int.parse(argResults['lsb']));
    print(coder.decodeMessage(messageLength));
  }
}

void main(List<String> arguments) {
  var runner = CommandRunner('caracal_steg', 'Dart steganography command-line application')
    ..addCommand(EncodeCommand())
    ..addCommand(DecodeCommand());
  runner.run(arguments);
}
