part of 'annoy_index.dart';

class AnnoyIndexSearchResult {
  late final int count;
  late final bool isDistanceIncluded;
  late final List<int> idList;
  late final List<double> distanceList;
  AnnoyIndexSearchResult._create(
      this.isDistanceIncluded, AnnoyIndexFactory fac, Pointer ptr) {
    count = fac._getResultCount(ptr);
    idList = Uint64List.fromList(fac._getIdList(ptr).asTypedList(count));
    distanceList = isDistanceIncluded
        ? Float32List.fromList(fac._getDistanceList(ptr).asTypedList(count))
        : [];
  }
}
