import 'package:image/image.dart';
import 'package:caracal_steg/dwt2.dart';
import 'dart:io';

void main() {
  var matrix = imageToMatrices(
      decodeImage(File('data/IMG_0042.JPG').readAsBytesSync())!)[0];
  var stopwatch = Stopwatch()..start();
  var slowResult = splitMatrix(matrix)[0];
  var t1 = stopwatch.elapsedMilliseconds;
  var fastResult = splitMatrix(matrix)[0];
  var t2 = stopwatch.elapsedMilliseconds - t1;
  print(slowResult);
  print(fastResult);
  print(!(slowResult - fastResult).any((element) => element.any((value) => value != 0)));
  print('Slow time was $t1 ms, fast time was $t2 ms');
}
