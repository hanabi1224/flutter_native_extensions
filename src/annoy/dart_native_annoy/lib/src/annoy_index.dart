import 'dart:core';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:dart_native_annoy/annoy.dart';
import 'package:ffi/ffi.dart';

import '../utils/native_array_utils.dart';

part 'annoy_factory.dart';
part 'annoy_index_search_result.dart';

/// Annoy index
class AnnoyIndex {
  final AnnoyIndexFactory _factory;
  final Pointer _ptr;
  late final int dimension;
  late final int size;
  final IndexType type;
  AnnoyIndex._create(this._factory, this._ptr, this.type) {
    dimension = _factory._getDimension(_ptr);
    size = _factory._getSize(_ptr);
  }

  /// Close the index
  void close() {
    _factory._freeAnnoyIndex(_ptr);
  }

  /// Get item vector with id
  List<double> getItemVector(int itemId) {
    final vecPtr = malloc.allocate<Float>(dimension);
    try {
      _factory._getItemVector(_ptr, itemId, vecPtr);
      final list = vecPtr.asTypedList(dimension);
      return List<double>.unmodifiable(list);
    } finally {
      malloc.free(vecPtr);
    }
  }

  /// Get nearest items to the given vector
  AnnoyIndexSearchResult getNearest(List<double> vector, int nResults,
      {int searchK = -1, bool includeDistance = false}) {
    final vecPtr = Float32List.fromList(vector).getPointer();
    try {
      final resultPtr = _factory._getNearest(
          _ptr, vecPtr, nResults, searchK, includeDistance ? 1 : 0);
      try {
        return AnnoyIndexSearchResult._create(
            includeDistance, _factory, resultPtr);
      } finally {
        _factory._freeSearchResult(resultPtr);
      }
    } finally {
      malloc.free(vecPtr);
    }
  }

  /// Get nearest items to the given item id
  AnnoyIndexSearchResult getNearestToItem(int itemId, int nResults,
      {int searchK = -1, bool includeDistance = false}) {
    final resultPtr = _factory._getNearestToItem(
        _ptr, itemId, nResults, searchK, includeDistance ? 1 : 0);
    try {
      return AnnoyIndexSearchResult._create(
          includeDistance, _factory, resultPtr);
    } finally {
      _factory._freeSearchResult(resultPtr);
    }
  }
}
