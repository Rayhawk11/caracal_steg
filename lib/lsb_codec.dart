import 'package:caracal_steg/hadamard_codec.dart';
import 'package:caracal_steg/steg_interfaces.dart';
import 'package:image/src/image.dart';
import 'package:quiver/iterables.dart';

class LSBSteganography extends StegInterface {
  int bitPosition;

  LSBSteganography(Image image, [this.bitPosition = 3]) : super(image, HadamardErrorCorrection());

  LSBSteganography.withECC(Image image, ErrorCorrectionClass ecc, [this.bitPosition = 3]) : super(image, ecc);

  Iterable<int> getNthLSBs(int x, int y) sync* {
    var pixel = image.getPixel(x, y);
    yield ((pixel & (1 << (16 + bitPosition))) >> (16 + bitPosition));
    yield ((pixel & (1 << (8 + bitPosition))) >> (8 + bitPosition));
    yield ((pixel & (1 << (0 + bitPosition))) >> (0 + bitPosition));
  }

  Iterable<int> getBits() sync* {
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        for (var bit in getNthLSBs(x, y)) {
          yield bit;
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
    var bits = ecc.encodeString(message);
    var x = 0;
    var y = 0;
    for(var threeBits in partition(bits, 3)){
      var addition = 0;
      var shift = 16;
      for (var bit in threeBits) {
        addition |= bit << shift;
        shift -= 8;
      }
      var pixel = image.getPixel(x, y);
      pixel &= ~(0x10101 << bitPosition);
      pixel |= (addition << bitPosition);
      image.setPixel(x, y, pixel);
      x = (x + 1) % image.width;
      y = y + (x == 0 ? 1 : 0);
    }
    return image;
  }
}
