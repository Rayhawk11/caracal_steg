import 'package:caracal_steg/dwt.dart';
import 'package:caracal_steg/repetition_codecs.dart';
import 'package:image/image.dart';

import 'dwt_codec.dart';
import 'hadamard_codec.dart';
import 'dart:io';

void main() {
  var inputImage = decodeImage(File('data/IMG_0042_Smaller.jpg').readAsBytesSync());
  var firstCoder = DWTStegnanography.withECC(
      inputImage,
      BitMajorityRepetitionCorrection(HadamardErrorCorrection(), 1), 2, 3);
  var outputImage = firstCoder.encodeMessage('fah');
  var first = firstCoder.helper.rgb;
  var secondHelper = ImageDWTHelper(3);
  secondHelper.haarTransform(outputImage);
  var second = secondHelper.rgb;
  for(var i = 0; i < 3; i++) {
    for (var row = 0; row < first[0].length; row++) {
      for (var col = 0; col < first[0][0].length; col++) {
        if (first[i][row][col] != second[i][row][col]) {
          print('Approximation mismatch at ($i, $row, $col)');
        }
      }
    }
  }
}