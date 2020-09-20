import 'package:caracal_steg/dwt.dart';
import 'package:ml_linalg/linalg.dart';

void main() {
  var matrix = Matrix.fromList([
    [255, 254],
    [254, 255]
  ]);
  print(haarT2D(matrix));
}
