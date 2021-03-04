import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:image/src/exif_data.dart';
import 'package:image/src/icc_profile_data.dart';
import 'package:ml_linalg/linalg.dart';
import 'package:caracal_steg/matrix_extensions.dart';

var doubleType = DType.float32;

List<Matrix> splitMatrix(Matrix m) {
  if (m.rowsNum % 2 != 0 || m.columnsNum % 2 != 0) {
    throw Exception('Can only split even matrices!');
  }
  var rowsPer = m.rowsNum ~/ 2;
  var colsPer = m.columnsNum ~/ 2;
  var results = List<Matrix>(4);
  results[0] = m.sample(
      rowIndices: [for (var i = 0; i < rowsPer; i++) i],
      columnIndices: [for (var i = 0; i < colsPer; i++) i]);
  results[1] = m.sample(
      rowIndices: [for (var i = 0; i < rowsPer; i++) i],
      columnIndices: [for (var i = colsPer; i < m.columnsNum; i++) i]);
  results[2] = m.sample(
      rowIndices: [for (var i = rowsPer; i < m.rowsNum; i++) i],
      columnIndices: [for (var i = 0; i < colsPer; i++) i]);
  results[3] = m.sample(
      rowIndices: [for (var i = rowsPer; i < m.rowsNum; i++) i],
      columnIndices: [for (var i = colsPer; i < m.columnsNum; i++) i]);
  return results;
}

List<Matrix> haarT2D(Matrix m) {
  var split = splitMatrix(m);
  var w = split[0];
  var x = split[1];
  var y = split[2];
  var z = split[3];
  var results = List<Matrix>(4);
  results[0] =
      ((((w + x) / 2).truncate() + (((y + z) / 2).truncate())) / 2).truncate();
  results[1] = ((w - x + y - z) / 2).truncate();
  results[2] = ((w + x) / 2).truncate() - ((y + z) / 2).truncate();
  results[3] = w - x - y + z;
  return results;
}

Matrix haarIT2D(List<Matrix> coeffs) {
  var cA = coeffs[0];
  var cH = coeffs[1];
  var cV = coeffs[2];
  var cD = coeffs[3];
  var w = cA +
      ((cV + 1) / 2).truncate() +
      ((cH + ((cD + 1) / 2).truncate() + 1) / 2).truncate();
  var x = w - cH - ((cD + 1) / 2).truncate();
  var y = cA +
      ((cV + 1) / 2).truncate() -
      cV +
      ((cH + ((cD + 1) / 2) - cD + 1).truncate() / 2).truncate();
  var z = y - cH - ((cD + 1) / 2).truncate() + cD;
  var topMatrix = w.insertColumns(w.columnsNum, x.columns.toList());
  var bottomMatrix = y.insertColumns(y.columnsNum, z.columns.toList());
  var finalMatrix = Matrix.fromRows(
      topMatrix.rows.toList() + bottomMatrix.rows.toList(),
      dtype: doubleType);
  return finalMatrix;
}

List<Matrix> imageToMatrices(Image img) {
  var rgbResultsTmp = List<List<List<double>>>.generate(3,
      (index) => List.generate(img.width, (indexX) => Float32List(img.height)));
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

Image matricesToImage(
    List<Matrix> matrices, ExifData exif, ICCProfileData iccp) {
  var img = Image(matrices[0].rowsNum, matrices[0].columnsNum,
      exif: exif, iccp: iccp);
  for (var x = 0; x < img.width; x++) {
    for (var y = 0; y < img.height; y++) {
      img.setPixelRgba(x, y, matrices[0][x][y].truncate(),
          matrices[1][x][y].truncate(), matrices[2][x][y].truncate());
    }
  }
  return img;
}

List<List<Matrix>> imageHaarT2D(Image img) {
  return imageToMatrices(img).map((e) => haarT2D(e)).toList();
}

Image imageHaarIT2D(
    List<List<Matrix>> matrices, ExifData exif, ICCProfileData iccp) {
  return matricesToImage(matrices.map((e) => haarIT2D(e)).toList(), exif, iccp);
}

class ImageDWTHelper {
  int levels;
  List<bool> hasColumnPadding;
  List<bool> hasRowPadding;
  List<List<List<Matrix>>> secondaryMatrices;
  List<List<List<double>>> rgb;
  ExifData exif;
  ICCProfileData iccp;

  ImageDWTHelper(this.levels) {
    hasColumnPadding = List.filled(levels, false);
    hasRowPadding = List.filled(levels, false);
    secondaryMatrices = List.filled(levels, null);
  }

  void haarTransformUsingMatrices(List<Matrix> matrices) {
    for (var i = 0; i < levels; i++) {
      if (matrices[0].rowsNum % 2 != 0) {
        matrices = matrices.map((e) => e.addZeroRow()).toList();
        hasRowPadding[i] = true;
      }
      if (matrices[0].columnsNum % 2 != 0) {
        matrices = matrices.map((e) => e.addZeroCol()).toList();
        hasColumnPadding[i] = true;
      }
      var haarResults = matrices.map((e) => haarT2D(e)).toList();
      matrices = [
        for (var i = 0; i < haarResults.length; i++) haarResults[i][0]
      ];
      secondaryMatrices[i] = haarResults.map((e) => e.sublist(1)).toList();
    }
    rgb = matrices
        .map((e) => e.toList().map((e) => e.toList()).toList())
        .toList();
  }

  List<Matrix> inverseHaarTransformToMatrices() {
    var currentMatrices =
        rgb.map((e) => Matrix.fromList(e, dtype: doubleType)).toList();
    for (var level = levels - 1; level >= 0; level--) {
      var higherMatrices = <Matrix>[];
      for (var i = 0; i < currentMatrices.length; i++) {
        higherMatrices.add(
            haarIT2D([currentMatrices[i]] + secondaryMatrices[level][i])
                .removePadding(hasRowPadding[level], hasColumnPadding[level]));
      }
      currentMatrices = higherMatrices;
    }
    return currentMatrices;
  }

  Image inverseHaarTransform() {
    return matricesToImage(inverseHaarTransformToMatrices(), exif, iccp);
  }

  void haarTransform(Image image) {
    exif = image.exif;
    iccp = image.iccProfile;
    haarTransformUsingMatrices(imageToMatrices(image));
  }
}

void main() {
  var helper = ImageDWTHelper(3);
  var testImage =
      decodeImage(File('data/IMG_0042_Smallerz.jpg').readAsBytesSync());
  helper.haarTransform(testImage);
  var originalRGB = helper.rgb;
  var outputImage = helper.inverseHaarTransform();
  helper.haarTransform(outputImage);
  var newRGB = helper.rgb;
  var correctPixels = 0;
  for (var x = 0; x < testImage.width; x++) {
    for (var y = 0; y < testImage.height; y++) {
      if (testImage.getPixel(x, y) == outputImage.getPixel(x, y)) {
        correctPixels++;
      }
    }
  }
  print(
      'Correct pixel proportion: ${correctPixels / (testImage.width * testImage.height)}');
  for (var i = 0; i < 3; i++) {
    for (var row = 0; row < originalRGB[0].length; row++) {
      for (var col = 0; col < originalRGB[0][0].length; col++) {
        if (originalRGB[i][row][col] != newRGB[i][row][col]) {
          print('Approximation mismatch at ($i, $row, $col)');
        }
      }
    }
  }
}
