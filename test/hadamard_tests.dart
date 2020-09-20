import 'dart:math';
import 'package:caracal_steg/hadamard_codec.dart';
import 'package:test/test.dart';

HadamardErrorCorrection ecc = HadamardErrorCorrection();

int testDecode(Iterable<int> code, int errors) {
  var codeCopy = code.toList();
  var errorIndices = <int>{};
  var random = Random();
  while (errorIndices.length < errors) {
    errorIndices.add(random.nextInt(256));
  }
  for (var index in errorIndices) {
    codeCopy[index] ^= 1;
  }
  return ecc.decodeByte(codeCopy);
}

void main() {
  for (var i = 0; i < 255; i++) {
    group('Testing for ASCII value $i', () {
      var code = ecc.encodeByte(i);
      for (var errors = 0; errors <= 64; errors++) {
        test('Testing for ASCII value $i and $errors errors', () {
          expect(testDecode(code, errors), equals(i));
        });
      }
      for (var errors = 192; errors <= 256; errors++) {
        test('Testing for ASCII value $i and $errors errors', () {
          expect(testDecode(code, errors), equals(i));
        });
      }
    });
  }
}
