import 'package:ml_linalg/linalg.dart';

extension MatrixExtensions on Matrix {
  Matrix addZeroRow() {
    var list = toList().map((e) => e.toList()).toList();
    list.add(List<double>.filled(columnsNum, 0));
    return Matrix.fromList(list, dtype: dtype);
  }

  Matrix addZeroCol() {
    return insertColumns(columnsNum, [Vector.filled(rowsNum, 0)]);
  }

  Matrix removePadding(bool rowPadding, bool colPadding) {
    var rowsToKeep = rowsNum - (rowPadding ? 1 : 0);
    var colsToKeep = columnsNum - (colPadding ? 1 : 0);
    return sample(
        rowIndices: [for(var i = 0; i < rowsToKeep; i++) i],
        columnIndices: [for(var i = 0; i < colsToKeep; i++) i]
    );
  }

  Matrix truncate() {
    return mapElements((x) {
      return x.floorToDouble();
    });
  }
}

extension VectorExtensions on Vector {
  Vector truncate() {
    return mapToVector((value) => value.floorToDouble());
  }
}