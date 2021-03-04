import 'dart:math';

import 'package:caracal_steg/dwt2.dart';
import 'package:image/image.dart';

double psnr(Image initial, Image modified) {
  var initialRGB = imageToMatrices(initial);
  var modifiedRGB = imageToMatrices(modified);
  var rMSE = (initialRGB[0] - modifiedRGB[0]).pow(2).mean().mean();
  var gMSE = (initialRGB[1] - modifiedRGB[1]).pow(2).mean().mean();
  var bMSE = (initialRGB[2] - modifiedRGB[2]).pow(2).mean().mean();
  var mse = (rMSE + gMSE + bMSE) / 3;
  return 20 * log(255) / log(10) - 10 * log(mse) / log(10);
}

double stringSimilarity(String initial, String modified) {
  var identical = 0;
  for (var i = 0; i < initial.length; i++) {
    if (initial[i] == modified[i]) identical += 1;
  }
  return identical / initial.length;
}
