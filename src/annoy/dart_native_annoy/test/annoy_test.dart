import 'package:dart_native_annoy/annoy.dart';
import 'package:test/test.dart';

import 'setup_util.dart';

AnnoyIndex _loadIndex(indexFactory) {
  return indexFactory.loadIndex(
      'index.euclidean.5d.ann', 5, IndexType.Euclidean)!;
}

void main() async {
  final lib = await SetupUtil.getDylibAsync();
  final fac = AnnoyIndexFactory(lib);

  final expectedIdList = [0, 84, 20, 49, 94];
  final expectedDistanceList = [
    0.0,
    0.9348742961883545,
    1.1051676273345947,
    1.1057792901992798,
    1.1299806833267212,
  ];
  test('dimension', () {
    final index = _loadIndex(fac);
    expect(5, index.dimension);
    index.close();
  });

  test('size', () {
    final index = _loadIndex(fac);
    expect(100, index.size);
    index.close();
  });

  test('v3', () {
    final index = _loadIndex(fac);
    final v3 = index.getItemVector(3);
    expect([
      1.5223065614700317,
      -1.5206894874572754,
      0.22699929773807526,
      0.40814927220344543,
      0.6402528285980225,
    ], v3);
    index.close();
  });

  test('nearest', () {
    final index = _loadIndex(fac);
    final v0 = index.getItemVector(0);
    final nearest = index.getNearest(v0, 5, includeDistance: true);
    expect(nearest.count, 5);
    expect(nearest.isDistanceIncluded, true);
    expect(nearest.idList, expectedIdList);
    expect(nearest.distanceList, expectedDistanceList);
    index.close();
  });

  test('nearestToItem', () {
    final index = _loadIndex(fac);
    final nearest = index.getNearestToItem(0, 5, includeDistance: true);
    expect(nearest.count, 5);
    expect(nearest.isDistanceIncluded, true);
    expect(nearest.idList, expectedIdList);
    expect(nearest.distanceList, expectedDistanceList);
    index.close();
  });

  test('noDistance', () {
    final index = _loadIndex(fac);
    final nearest = index.getNearestToItem(0, 5, includeDistance: false);
    expect(nearest.count, 5);
    expect(nearest.isDistanceIncluded, false);
    expect(nearest.idList, expectedIdList);
    expect(nearest.distanceList, []);
    index.close();
  });
}
