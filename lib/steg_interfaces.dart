import 'dart:convert';
import 'package:quiver/iterables.dart';

import 'package:image/image.dart';

abstract class ErrorCorrectionClass {
  final int codeSize;
  Iterable<int> encodeByte(int byte);
  int decodeByte(List<int> code);

  ErrorCorrectionClass([this.codeSize = 0]);

  Iterable<int> encodeString(String string) sync* {
    var codec = AsciiCodec();
    var ascii = codec.encode(string);
    for(var byte in ascii) {
      for(var bit in encodeByte(byte)) {
        yield bit;
      }
    }
  }

  String decodeString(Iterable<int> code) {
    var codec = AsciiCodec(allowInvalid: true);
    return codec.decode(partition(code, codeSize).map((codeUnit) => decodeByte(codeUnit)).toList());
  }
}

abstract class StegInterface {
  Image image;
  ErrorCorrectionClass ecc;
  StegInterface(this.image, this.ecc);
  Image encodeMessage(String message);
  String decodeMessage(int messageLength);
}