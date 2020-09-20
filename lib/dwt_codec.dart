import 'package:caracal_steg/hadamard_codec.dart';
import 'package:caracal_steg/steg_interfaces.dart';
import 'package:caracal_steg/dwt.dart';
import 'package:image/src/image.dart';
import 'package:ml_linalg/linalg.dart';

class DWTStegnanography extends StegInterface {
  int bitPosition;

  DWTStegnanography(Image image, [this.bitPosition = 2]) : super(image, HadamardErrorCorrection());
  DWTStegnanography.withECC(Image image, ErrorCorrectionClass ecc, [this.bitPosition = 2]) : super(image, ecc);

  Iterable<int> getBits() sync* {
    var haarMatrices = imageHaarT2D(image);
    for(var row = 0; row < haarMatrices[0][0].rowsNum; row++) {
      for(var col = 0; col < haarMatrices[0][0].columnsNum; col++) {
        for(var i = 0; i < 3; i++) {
          yield ((haarMatrices[i][0][row][col].toInt()) & (1 << bitPosition)) >> bitPosition;
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
    var haarMatrices = imageHaarT2D(image);
    var cols = haarMatrices[0][0].columnsNum;
    var row = 0;
    var col = 0;
    var color = 0;
    var approxLists = <List<List<double>>>[];
    approxLists.add(haarMatrices[0][0].toList().map((e) => e.toList()).toList());
    approxLists.add(haarMatrices[1][0].toList().map((e) => e.toList()).toList());
    approxLists.add(haarMatrices[2][0].toList().map((e) => e.toList()).toList());

    for(var bit in ecc.encodeString(message)) {
      var curCoeff = approxLists[color][row][col].toInt();
      curCoeff &= ~(1 << bitPosition);
      curCoeff |= (bit << bitPosition);
      approxLists[color][row][col] = curCoeff.toDouble();
      if(color == 2) {
        color = 0;
        col = (col + 1) % cols;
        row = row + (col == 0 ? 1 : 0);
      }
      else {
        color++;
      }
    }
    for(var i = 0; i < 3; i++) {
      haarMatrices[i][0] = Matrix.fromList(approxLists[i], dtype: doubleType);
    }
    image = imageHaarIT2D(haarMatrices, image.exif, image.iccProfile);
  }

}