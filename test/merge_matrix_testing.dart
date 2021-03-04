import 'package:image/image.dart';
import 'package:caracal_steg/dwt2.dart';
import 'dart:io';

void main() {
  var matrix = imageToMatrices(
      decodeImage(File('data/IMG_0042.JPG').readAsBytesSync())!)[0];
  var stopwatch = Stopwatch()..start();
  var result2 = fastHaarT2D(matrix);
  var t2 = stopwatch.elapsedMilliseconds;
  print('Fast time was $t2 ms');
}
