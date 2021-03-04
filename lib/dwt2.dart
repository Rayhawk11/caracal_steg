import 'package:ml_linalg/linalg.dart';
import 'package:caracal_steg/matrix_extensions.dart';
import 'package:image/image.dart';
import 'package:image/src/exif_data.dart';
import 'package:image/src/icc_profile_data.dart';
import 'dart:typed_data';
import 'dart:io';

Matrix rowHaarT(Matrix input) {
  var evens = input.sample(
      columnIndices: input.columnIndices.where((element) => element & 1 == 0),
      rowIndices: input.rowIndices);
  var odds = input.sample(
      columnIndices: input.columnIndices.where((element) => element & 1 != 0),
      rowIndices: input.rowIndices);
  var average = ((evens + odds) / 2).truncate();
  var difference = evens - odds;
  return Matrix.fromColumns(
      average.columns.toList() + difference.columns.toList());
}

Matrix fastRowHaarT(Matrix input) {
  var averages = <Vector>[];
  var differences = <Vector>[];
  for (var i = 0; i < input.columnsNum; i += 2) {
    var x = input.getColumn(i);
    var y = input.getColumn(i + 1);
    averages.add(((x + y) / 2).truncate());
    differences.add(x - y);
  }
  return Matrix.fromColumns(averages + differences);
}

Matrix rowHaarIT(Matrix input) {
  var averages = input.sample(
      columnIndices: input.columnIndices.take(input.columnsNum ~/ 2),
      rowIndices: input.rowIndices);
  var differences = input.sample(
      columnIndices: input.columnIndices.skip(input.columnsNum ~/ 2),
      rowIndices: input.rowIndices);
  var x = averages + ((differences + 1) / 2).truncate();
  var y = x - differences;
  var columns = <Vector>[];
  for (var i = 0; i < x.columnsNum; i++) {
    columns.add(x.getColumn(i));
    columns.add(y.getColumn(i));
  }
  return Matrix.fromColumns(columns);
}

Matrix fastRowHaarIT(Matrix input) {
  var cols = <Vector>[];
  var halfCols = input.columnsNum ~/ 2;
  for (var i = 0; i < halfCols; i += 1) {
    var average = input.getColumn(i);
    var differences = input.getColumn(i + halfCols);
    var x = average + ((differences + 1) / 2).truncate();
    var y = x - differences;
    cols.add(x);
    cols.add(y);
  }
  return Matrix.fromColumns(cols);
}

Matrix colHaarT(Matrix input) {
  var evens = input.sample(
      columnIndices: input.columnIndices,
      rowIndices: input.rowIndices.where((element) => element & 1 == 0));
  var odds = input.sample(
      columnIndices: input.columnIndices,
      rowIndices: input.rowIndices.where((element) => element & 1 != 0));
  var average = ((evens + odds) / 2).truncate();
  var difference = evens - odds;
  return Matrix.fromRows(average.rows.toList() + difference.rows.toList());
}

Matrix fastColHaarT(Matrix input) {
  var averages = <Vector>[];
  var differences = <Vector>[];
  for (var i = 0; i < input.rowsNum; i += 2) {
    var x = input[i];
    var y = input[i + 1];
    averages.add(((x + y) / 2).truncate());
    differences.add(x - y);
  }
  return Matrix.fromRows(averages + differences);
}

Matrix colHaarIT(Matrix input) {
  var averages = input.sample(
      columnIndices: input.columnIndices,
      rowIndices: input.rowIndices.take(input.rowsNum ~/ 2));
  var differences = input.sample(
      columnIndices: input.columnIndices,
      rowIndices: input.rowIndices.skip(input.rowsNum ~/ 2));
  var x = averages + ((differences + 1) / 2).truncate();
  var y = x - differences;
  var columns = <Vector>[];
  for (var i = 0; i < x.rowsNum; i++) {
    columns.add(x.getRow(i));
    columns.add(y.getRow(i));
  }
  return Matrix.fromRows(columns);
}

Matrix fastColHaarIT(Matrix input) {
  var rows = <Vector>[];
  var halfRows = input.rowsNum ~/ 2;
  for (var i = 0; i < halfRows; i += 1) {
    var average = input[i];
    var differences = input[i + halfRows];
    var x = average + ((differences + 1) / 2).truncate();
    var y = x - differences;
    rows.add(x);
    rows.add(y);
  }
  return Matrix.fromRows(rows);
}

Matrix haarT2D(Matrix input) {
  return colHaarT(rowHaarT(input));
}

Matrix fastHaarT2D(Matrix input) {
  return fastColHaarT(fastRowHaarT(input));
}

Matrix haarIT2D(Matrix input) {
  return rowHaarIT(colHaarIT(input));
}

Matrix fastHaarIT2D(Matrix input) {
  return fastRowHaarIT(fastColHaarIT(input));
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
    Matrix.fromList(rgbResultsTmp[0]),
    Matrix.fromList(rgbResultsTmp[1]),
    Matrix.fromList(rgbResultsTmp[2])
  ];
}

Image matricesToImage(
    List<Matrix> matrices, ExifData? exif, ICCProfileData? iccp) {
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

List<Matrix> splitMatrix(Matrix m) {
  if (m.rowsNum % 2 != 0 || m.columnsNum % 2 != 0) {
    throw Exception('Can only split even matrices!');
  }
  var rowsPer = m.rowsNum ~/ 2;
  var colsPer = m.columnsNum ~/ 2;

  var firstRows = m.rows.take(rowsPer);
  var top_generator = firstRows
      .map((row) => [row.subvector(0, colsPer), row.subvector(colsPer)]);

  var t1 = <Vector>[];
  var t2 = <Vector>[];
  for (var vectors in top_generator) {
    t1.add(vectors[0]);
    t2.add(vectors[1]);
  }

  var t3 = <Vector>[];
  var t4 = <Vector>[];
  var secondRows = m.rows.skip(rowsPer);
  var bottom_generator = secondRows
      .map((row) => [row.subvector(0, colsPer), row.subvector(colsPer)]);
  for (var vectors in bottom_generator) {
    t3.add(vectors[0]);
    t4.add(vectors[1]);
  }
  return [t1, t2, t3, t4].map((e) => Matrix.fromRows(e)).toList();
}

Matrix mergeMatrices(List<Matrix> matrices) {
  var elements = Float32List(matrices[0].rowsNum * matrices[0].columnsNum * 4);
  var index = 0;
  void addElement(double element) {
    elements[index] = element;
    index += 1;
  }

  for (var row = 0; row < matrices[0].rowsNum; row++) {
    matrices[0][row].forEach(addElement);
    matrices[1][row].forEach(addElement);
  }
  for (var row = 0; row < matrices[0].rowsNum; row++) {
    matrices[2][row].forEach(addElement);
    matrices[3][row].forEach(addElement);
  }
  return Matrix.fromFlattenedList(
      elements, matrices[0].rowsNum * 2, matrices[0].columnsNum * 2);
}

class ImageDWTHelper {
  int levels;
  late List<List<List<Matrix>>> secondaryMatrices;
  late List<Matrix> approxMatrices;
  late ExifData? exif;
  late ICCProfileData? iccp;

  ImageDWTHelper(this.levels);

  void haarT(Image image) {
    exif = image.exif;
    iccp = image.iccProfile;
    var workingMatrices = imageToMatrices(image);
    secondaryMatrices = List<List<List<Matrix>>>.generate(levels, (level) {
      var currentSecondaryMatrices = List<List<Matrix>>.generate(3, (color) {
        var haarMatrices = splitMatrix(fastHaarT2D(workingMatrices[color]));
        workingMatrices[color] = haarMatrices[0];
        return haarMatrices.sublist(1);
      });
      return currentSecondaryMatrices;
    });
    approxMatrices = workingMatrices;
  }

  Image haarIT() {
    var currentApproxMatrices = List<Matrix>.from(approxMatrices);
    for (var level = levels - 1; level >= 0; level--) {
      for (var color = 0; color < 3; color++) {
        var merged = mergeMatrices(
            [currentApproxMatrices[color]] + secondaryMatrices[level][color]);
        currentApproxMatrices[color] = fastHaarIT2D(merged);
      }
    }
    return matricesToImage(currentApproxMatrices, exif, iccp);
  }
}

void main() {
  var helper = ImageDWTHelper(3);
  var testImage =
      decodeImage(File('data/IMG_0042_Smaller.jpg').readAsBytesSync());
  helper.haarT(testImage!);
  var outputImage = helper.haarIT();
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
}
