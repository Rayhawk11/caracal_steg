import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:image/src/exif_data.dart';
import 'package:image/src/icc_profile_data.dart';
import 'package:ml_linalg/linalg.dart';

var doubleType = DType.float32;

List<Matrix> splitMatrix(Matrix m) {
  if (m.rowsNum % 2 != 0 || m.columnsNum % 2 != 0) {
    throw Exception('Can only split even matrices!');
  }
  var rowsPer = m.rowsNum ~/ 2;
  var colsPer = m.columnsNum ~/ 2;
  var results = List<Matrix>(4);
  results[0] =
      m.sample(rowIndices: [for (var i = 0; i < rowsPer; i++) i], columnIndices: [for (var i = 0; i < colsPer; i++) i]);
  results[1] = m.sample(
      rowIndices: [for (var i = 0; i < rowsPer; i++) i],
      columnIndices: [for (var i = colsPer; i < m.columnsNum; i++) i]);
  results[2] = m.sample(
      rowIndices: [for (var i = rowsPer; i < m.rowsNum; i++) i], columnIndices: [for (var i = 0; i < colsPer; i++) i]);
  results[3] = m.sample(
      rowIndices: [for (var i = rowsPer; i < m.rowsNum; i++) i],
      columnIndices: [for (var i = colsPer; i < m.columnsNum; i++) i]);
  return results;
}

Matrix truncMatrix(Matrix m) {
  return m.mapElements((x) {
    return x.floor().toDouble();
  });
}

List<Matrix> haarT2D(Matrix m) {
  var split = splitMatrix(m);
  var w = split[0];
  var x = split[1];
  var y = split[2];
  var z = split[3];
  var results = List<Matrix>(4);
  results[0] = truncMatrix((truncMatrix((w + x) / 2) + truncMatrix((y + z) / 2)) / 2);
  results[1] = truncMatrix((w - x + y - z) / 2);
  results[2] = truncMatrix((w + x) / 2) - truncMatrix((y + z) / 2);
  results[3] = w - x - y + z;
  return results;
}

Matrix haarIT2D(List<Matrix> coeffs) {
  var cA = coeffs[0];
  var cH = coeffs[1];
  var cV = coeffs[2];
  var cD = coeffs[3];
  var w = cA + truncMatrix((cV + 1) / 2) + truncMatrix((cH + truncMatrix((cD + 1) / 2) + 1) / 2);
  var x = w - cH - truncMatrix((cD + 1) / 2);
  var y = cA + truncMatrix((cV + 1) / 2) - cV + truncMatrix((cH + truncMatrix((cD + 1) / 2) - cD + 1) / 2);
  var z = y - cH - truncMatrix((cD + 1) / 2) + cD;
  var topMatrix = w.insertColumns(w.columnsNum, x.columns.toList());
  var bottomMatrix = y.insertColumns(y.columnsNum, z.columns.toList());
  var finalMatrix = Matrix.fromRows(topMatrix.rows.toList() + bottomMatrix.rows.toList(), dtype: doubleType);
  return finalMatrix;
}

List<Matrix> imageToMatrices(Image img) {
  img.exif;
  var rgbResultsTmp =
      List<List<List<double>>>.generate(3, (index) => List.generate(img.width, (indexX) => Float32List(img.height)));
  for (var x = 0; x < img.width; x++) {
    for (var y = 0; y < img.height; y++) {
      var pixel = img.getPixel(x, y);
      rgbResultsTmp[0][x][y] = (pixel & (0xFF)).toDouble();
      rgbResultsTmp[1][x][y] = ((pixel & (0xFF << 8)) >> 8).toDouble();
      rgbResultsTmp[2][x][y] = ((pixel & (0xFF << 16)) >> 16).toDouble();
    }
  }
  return [
    Matrix.fromList(rgbResultsTmp[0], dtype: doubleType),
    Matrix.fromList(rgbResultsTmp[1], dtype: doubleType),
    Matrix.fromList(rgbResultsTmp[2], dtype: doubleType)
  ];
}

Image matricesToImage(List<Matrix> matrices, ExifData exif, ICCProfileData iccp) {
  var img = Image(matrices[0].rowsNum, matrices[0].columnsNum, exif: exif, iccp: iccp);
  for (var x = 0; x < img.width; x++) {
    for (var y = 0; y < img.height; y++) {
      img.setPixelRgba(x, y, matrices[0][x][y].truncate(), matrices[1][x][y].truncate(), matrices[2][x][y].truncate());
    }
  }
  return img;
}

List<List<Matrix>> imageHaarT2D(Image img) {
  return imageToMatrices(img).map((e) => haarT2D(e)).toList();
}

Image imageHaarIT2D(List<List<Matrix>> matrices, ExifData exif, ICCProfileData iccp) {
  return matricesToImage(matrices.map((e) => haarIT2D(e)).toList(), exif, iccp);
}

void main() {
  var testImage = decodeImage(File('data/IMG_0042_LSB.jpg').readAsBytesSync());
  var outputImage = imageHaarIT2D(imageHaarT2D(testImage), testImage.exif, testImage.iccProfile);
  var correctPixels = 0;
  for(var x = 0; x < testImage.width; x++) {
    for(var y = 0; y < testImage.height; y++) {
      if(testImage.getPixel(x,y) == outputImage.getPixel(x,y)) {
        correctPixels++;
      }
    }
  }
  print('Correct pixel proportion: ${correctPixels / (testImage.width * testImage.height)}');
}
