import 'package:caracal_steg/steg_interfaces.dart';
import 'package:quiver/iterables.dart';

abstract class RepetitionCorrection extends ErrorCorrectionClass {
  ErrorCorrectionClass inner;
  int repCount;

  RepetitionCorrection(this.inner, this.repCount) : super(inner.codeSize * repCount);

  @override
  Iterable<int> encodeByte(int byte) sync* {
    for (var i = 0; i < repCount; i++) {
      for (var bit in inner.encodeByte(byte)) {
        yield bit;
      }
    }
  }
}

class BitMajorityRepetitionCorrection extends RepetitionCorrection {
  BitMajorityRepetitionCorrection(ErrorCorrectionClass inner, int repCount) : super(inner, repCount);

  @override
  int decodeByte(List<int> code) {
    var oneCounts = List<int>.filled(inner.codeSize, 0);
    var codePos = 0;
    for (var i = 0; i < repCount; i++) {
      for (var bitPos = 0; bitPos < inner.codeSize; bitPos++) {
        oneCounts[bitPos] += code[codePos];
        codePos++;
      }
    }
    return inner.decodeByte(oneCounts.map((oneCount) => oneCount > repCount / 2 ? 1 : 0).toList());
  }
}

class ValuePluralityRepetitionCorrection extends RepetitionCorrection {
  bool Function(int value) filter;

  static bool defaultFilter(int value) {
    return true;
  }

  ValuePluralityRepetitionCorrection(ErrorCorrectionClass inner, int repCount, [this.filter = defaultFilter])
      : super(inner, repCount);

  @override
  int decodeByte(List<int> code) {
    var valueFrequency = List.filled(256, 0);
    for (var repetition in partition(code, inner.codeSize)) {
      valueFrequency[inner.decodeByte(repetition)]++;
    }

    var bestFrequency = -1;
    var bestValue = -1;
    for (var i = 0; i < 256; i++) {
      if (valueFrequency[i] > bestFrequency && filter(i)) {
        bestFrequency = valueFrequency[i];
        bestValue = i;
      }
    }

    return bestValue;
  }
}
