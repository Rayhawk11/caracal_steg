import 'package:caracal_steg/hadamard_matrix.dart';
import 'package:caracal_steg/steg_interfaces.dart';
import 'package:ml_linalg/linalg.dart';

class HadamardErrorCorrection extends ErrorCorrectionClass {
  HadamardErrorCorrection(): super(256);

  @override
  int decodeByte(List<int> code) {
    var lookupTable = [-1.0, 1.0];
    var codeMatrix = Matrix.fromList([code.map((x) => lookupTable[x]).toList()]);
    var index = 0;
    var highestMagnitude = 0;
    var highestMagnitudeIndex = 0;
    for (var magnitude in (codeMatrix * hadamardMatrix)[0].map((x) => x.toInt().abs())) {
      if (magnitude > highestMagnitude) {
        highestMagnitude = magnitude;
        highestMagnitudeIndex = index;
      }
      index += 1;
    }
    return highestMagnitudeIndex;
  }

  @override
  Iterable<int> encodeByte(int byte) {
    return hadamardMatrix[byte].map((floatVal) => (floatVal.truncate() + 1) >> 1);
  }
}
