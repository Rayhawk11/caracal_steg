import 'package:ml_linalg/linalg.dart';

List<Matrix> fastSplitMatrix(Matrix m) {
  if (m.rowsNum % 2 != 0 || m.columnsNum % 2 != 0) {
    throw Exception('Can only split even matrices!');
  }
  var rowsPer = m.rowsNum ~/ 2;
  var colsPer = m.columnsNum ~/ 2;
  var results = List<Matrix>(4);
  var t1 = List<Vector>(rowsPer);
  var t2 = List<Vector>(rowsPer);
  for (var rowIndex = 0; rowIndex < rowsPer; rowIndex++) {
    var row = m[rowIndex];
    t1[rowIndex] = row.subvector(0, colsPer);
    t2[rowIndex] = row.subvector(colsPer);
  }
  results[0] = Matrix.fromRows(t1);
  results[1] = Matrix.fromRows(t2);
  var t3 = List<Vector>(rowsPer);
  var t4 = List<Vector>(rowsPer);
  for (var rowIndex = rowsPer; rowIndex < m.rowsNum; rowIndex++) {
    var row = m[rowIndex];
    t3[rowIndex - rowsPer] = row.subvector(0, colsPer);
    t4[rowIndex - rowsPer] = row.subvector(colsPer);
  }
  results[2] = Matrix.fromRows(t3);
  results[3] = Matrix.fromRows(t4);
  return results;
}

void main() {
  var testMatrix = Matrix.fromList([
    [1, 1, 1, 1],
    [2, 2, 2, 2],
    [3, 3, 3, 3],
    [4, 4, 4, 4]
  ]);
  var split = fastSplitMatrix(testMatrix);
  print(split[0]);
  print(split[0] + split[0]);
}
