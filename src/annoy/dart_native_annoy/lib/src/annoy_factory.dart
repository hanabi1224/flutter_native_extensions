part of 'annoy_index.dart';

/// fn load_annoy_index(path: *const c_char, dimension: i32, index_type: u8) -> *const AnnoyIndex
typedef LoadAnnoyIndexNative = Pointer Function(Pointer<Utf8>, Int32, Uint8);
typedef LoadAnnoyIndex = Pointer Function(Pointer<Utf8>, int, int);

/// fn free_annoy_index(index: *const AnnoyIndex)
typedef FreeAnnoyIndexNative = Void Function(Pointer);
typedef FreeAnnoyIndex = void Function(Pointer);

/// fn get_dimension(index_ptr: *const AnnoyIndex) -> i32
typedef GetDimensionNative = Int32 Function(Pointer);
typedef GetDimension = int Function(Pointer);

/// fn get_size(index_ptr: *const AnnoyIndex) -> u64
typedef GetSizeNative = Uint64 Function(Pointer);
typedef GetSize = int Function(Pointer);

/// fn get_item_vector(index_ptr: *const AnnoyIndex, item_index: i64, item_vector: *mut f32)
typedef GetItemVectorNative = Void Function(Pointer, Int64, Pointer<Float>);
typedef GetItemVector = void Function(Pointer, int, Pointer<Float>);

/// fn get_nearest(
//     index_ptr: *const AnnoyIndex,
//     query_vector_ptr: *const f32,
//     n_results: size_t,
//     search_k: i32,
//     should_include_distance: bool) -> *const AnnoyIndexSearchResult
typedef GetNearestNative = Pointer Function(
    Pointer, Pointer<Float>, Int64, Int32, Uint8);
typedef GetNearest = Pointer Function(Pointer, Pointer<Float>, int, int, int);

/// fn get_nearest_to_item(
//     index_ptr: *const AnnoyIndex,
//     item_index: i64,
//     n_results: size_t,
//     search_k: i32,
//     should_include_distance: bool,
// ) -> *const AnnoyIndexSearchResult
typedef GetNearestToItemNative = Pointer Function(
    Pointer, Int64, Int64, Int32, Uint8);
typedef GetNearestToItem = Pointer Function(Pointer, int, int, int, int);

/// fn free_search_result(search_result_ptr: *const AnnoyIndexSearchResult)
typedef FreeSearchResultNative = Void Function(Pointer);
typedef FreeSearchResult = void Function(Pointer);

/// fn get_result_count(search_result_ptr: *const AnnoyIndexSearchResult) -> usize
typedef GetResultCountNative = Uint64 Function(Pointer);
typedef GetResultCount = int Function(Pointer);

/// fn get_id_list(search_result_ptr: *const AnnoyIndexSearchResult)->*const u64
typedef GetIdListNative = Pointer<Uint64> Function(Pointer);
typedef GetIdList = Pointer<Uint64> Function(Pointer);

/// fn get_distance_list(search_result_ptr: *const AnnoyIndexSearchResult)->*const f32
typedef GetDistanceListNative = Pointer<Float> Function(Pointer);
typedef GetDistanceList = Pointer<Float> Function(Pointer);

/// Factory to load pre-built annoy index
class AnnoyIndexFactory {
  final DynamicLibrary _lib;
  AnnoyIndexFactory(this._lib) {
    _loadAnnoyIndex = _lib.lookupFunction<LoadAnnoyIndexNative, LoadAnnoyIndex>(
        'load_annoy_index');
    _freeAnnoyIndex = _lib.lookupFunction<FreeAnnoyIndexNative, FreeAnnoyIndex>(
        'free_annoy_index');
    _getDimension =
        _lib.lookupFunction<GetDimensionNative, GetDimension>('get_dimension');
    _getSize = _lib.lookupFunction<GetSizeNative, GetSize>('get_size');
    _getItemVector = _lib
        .lookupFunction<GetItemVectorNative, GetItemVector>('get_item_vector');
    _getNearest =
        _lib.lookupFunction<GetNearestNative, GetNearest>('get_nearest');
    _getNearestToItem =
        _lib.lookupFunction<GetNearestToItemNative, GetNearestToItem>(
            'get_nearest_to_item');
    _freeSearchResult =
        _lib.lookupFunction<FreeSearchResultNative, FreeSearchResult>(
            'free_search_result');
    _getResultCount = _lib.lookupFunction<GetResultCountNative, GetResultCount>(
        'get_result_count');
    _getIdList = _lib.lookupFunction<GetIdListNative, GetIdList>('get_id_list');
    _getDistanceList =
        _lib.lookupFunction<GetDistanceListNative, GetDistanceList>(
            'get_distance_list');
  }

  late LoadAnnoyIndex _loadAnnoyIndex;

  /// Load a pre-built annoy index, returns null if failed.
  AnnoyIndex? loadIndex(String path, int dimension, IndexType type) {
    var indexPtr = _loadAnnoyIndex(path.toNativeUtf8(), dimension, type.index);
    if (indexPtr.address == 0) {
      return null;
    }
    return AnnoyIndex._create(this, indexPtr, type);
  }

  late FreeAnnoyIndex _freeAnnoyIndex;
  late GetDimension _getDimension;
  late GetSize _getSize;
  late GetItemVector _getItemVector;
  late GetNearest _getNearest;
  late GetNearestToItem _getNearestToItem;
  late FreeSearchResult _freeSearchResult;
  late GetResultCount _getResultCount;
  late GetIdList _getIdList;
  late GetDistanceList _getDistanceList;
}
