import 'package:caracal_steg/hadamard_codec.dart';
import 'package:caracal_steg/steg_interfaces.dart';
import 'package:caracal_steg/dwt.dart';
import 'package:image/src/image.dart';

class DWTStegnanography extends StegInterface {
  int bitPosition;
  ImageDWTHelper helper;

  DWTStegnanography(Image image, [bitPosition = 2, levels = 3])
      : this.withECC(image, HadamardErrorCorrection(), bitPosition, levels);

  DWTStegnanography.withECC(Image image, ErrorCorrectionClass ecc,
      [this.bitPosition = 2, levels = 3])
      : helper = ImageDWTHelper(levels),
        super(image, ecc);

  Iterable<int> getBits() sync* {
    helper.haarTransform(image);
    var haarMatrices = helper.rgb;
    for (var row = 0; row < haarMatrices[0].length; row++) {
      for (var col = 0; col < haarMatrices[0][0].length; col++) {
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
    helper.haarTransform(image);
    var row = 0;
    var col = 0;
    var color = 0;
    var cols = helper.rgb[0][0].length;
    for (var bit in ecc.encodeString(message)) {
      var curCoeff = helper.rgb[color][row][col].truncate();
      curCoeff &= ~(1 << bitPosition);
      curCoeff |= (bit << bitPosition);
      assert(curCoeff <= 255);
      helper.rgb[color][row][col] = curCoeff.toDouble();
      if (color == 2) {
        color = 0;
        col = (col + 1) % cols;
        row = row + (col == 0 ? 1 : 0);
      } else {
        color++;
      }
    }
    return helper.inverseHaarTransform();
  }
}
