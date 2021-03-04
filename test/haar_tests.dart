import 'package:ml_linalg/linalg.dart';
import 'package:caracal_steg/dwt.dart';
import 'package:caracal_steg/matrix_extensions.dart';
import 'package:test/test.dart';
import 'dart:math';
import 'dart:io';
import 'package:image/image.dart';

Matrix randomMatrix() {
  var vectors = <Vector>[];
  var random = Random();
  for (var col = 0; col < 8; col++) {
    vectors.add(Vector.randomFilled(8, min: 0, max: 256, seed: random.nextInt(999999)));
  }
  return Matrix.fromColumns(vectors);
}

void main() {
  for (var i = 0; i < 100; i++) {
    var helper = ImageDWTHelper(1);
    var matrix = randomMatrix().truncate();
    var normalHaar = haarIT2D(haarT2D(matrix));
    helper.haarTransformUsingMatrices([matrix]);
    var newHaar = helper.inverseHaarTransformToMatrices()[0];
    test('Legacy test $i', () {
      expect(normalHaar, equals(matrix));
    });
    test('New test $i', () {
      expect(newHaar, equals(normalHaar));
    });
  }
  for (var i = 0; i < 100; i++) {
    var helper = ImageDWTHelper(2);
    var matrix = randomMatrix().truncate();
    var normalHaar = haarT2D(haarT2D(matrix)[0])[0];
    helper.haarTransformUsingMatrices([matrix]);
    var newHaar = Matrix.fromList(helper.rgb[0]);
    test('Two level test $i', () {
      expect(newHaar, equals(normalHaar));
    });
  }

  test('Image haar testing', () {
    var helper = ImageDWTHelper(1);
    var image = decodeImage(File('data/IMG_0042_Smaller.jpg').readAsBytesSync());
    var haar = imageHaarT2D(image!);
    helper.haarTransform(image);
    var otherHaar = helper.rgb;
    for(var i = 0; i < 3; i++) {
      expect(Matrix.fromList(otherHaar[i]), equals(haar[i][0]));
    }
  });
}
