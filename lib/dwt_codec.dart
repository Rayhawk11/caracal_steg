import 'package:caracal_steg/hadamard_codec.dart';
import 'package:caracal_steg/steg_interfaces.dart';
import 'package:caracal_steg/dwt2.dart';
import 'package:image/src/image.dart';
import 'package:ml_linalg/linalg.dart';

class DWTStegnanography extends StegInterface {
  int bitPosition;

  DWTStegnanography(Image image, [this.bitPosition = 2])
      : super(image, HadamardErrorCorrection());

  DWTStegnanography.withECC(Image image, ErrorCorrectionClass ecc,
      [this.bitPosition = 2])
      : super(image, ecc);

  Iterable<int> getBits() sync* {
    var helper = ImageDWTHelper(3);
    helper.haarT(image);
    var haarMatrices = helper.approxMatrices;
    for (var row = 0; row < haarMatrices[0].rowsNum; row++) {
      for (var col = 0; col < haarMatrices[0].columnsNum; col++) {
        for (var i = 0; i < 3; i++) {
          yield ((haarMatrices[i][row][col].toInt()) & (1 << bitPosition)) >>
              bitPosition;
        }
      }
    }
  }

  @override
  String decodeMessage(int messageLength) {
    return ecc.decodeString(getBits().take(ecc.codeSize * messageLength));
  }

  @override
  Image encodeMessage(String message) {
    var helper = ImageDWTHelper(3);
    helper.haarT(image);
    var haarMatrices = List<List<List<double>>>.generate(
        3,
        (color) => helper.approxMatrices[color]
            .toList()
            .map((element) => element.toList())
            .toList());
    var cols = haarMatrices[0][0].length;
    var row = 0;
    var col = 0;
    var color = 0;
    for (var bit in ecc.encodeString(message)) {
      var curCoeff = haarMatrices[color][row][col].toInt();
      curCoeff &= ~(1 << (bitPosition));
      curCoeff |= (bit << bitPosition);
      haarMatrices[color][row][col] = curCoeff.toDouble();
      if (color == 2) {
        color = 0;
        col = (col + 1) % cols;
        row = row + (col == 0 ? 1 : 0);
      } else {
        color++;
      }
    }
    helper.approxMatrices =
        haarMatrices.map((element) => Matrix.fromList(element)).toList();
    return helper.haarIT();
  }
}
