part of 'annoy_index.dart';

class AnnoyIndexSearchResult {
  late final int count;
  late final bool isDistanceIncluded;
  late final List<int> idList;
  late final List<double> distanceList;
  AnnoyIndexSearchResult._create(
      this.isDistanceIncluded, AnnoyIndexFactory fac, Pointer ptr) {
    count = fac._getResultCount(ptr);
    idList = List<int>.unmodifiable(fac._getIdList(ptr).asTypedList(count));
    distanceList = isDistanceIncluded
        ? List<double>.unmodifiable(
            fac._getDistanceList(ptr).asTypedList(count))
        : [];
  }
}
