use libc::*;

// Full API doc: https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4.h
#[allow(non_snake_case)]
extern "C" {
    // LZ4LIB_API int LZ4_versionNumber (void);  /**< library version number; useful to check dll version */
    pub fn LZ4_versionNumber() -> c_int;

    // LZ4LIB_API const char* LZ4_versionString (void);   /**< library version string; useful to check dll version */
    pub fn LZ4_versionString() -> *const c_char;

    // LZ4FLIB_API unsigned LZ4F_getVersion(void);
    pub fn LZ4F_getVersion() -> c_uint;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4frame.h#L203
    // LZ4FLIB_API size_t LZ4F_compressFrameBound(size_t srcSize, const LZ4F_preferences_t* preferencesPtr);
    pub fn LZ4F_compressFrameBound(src_size: size_t, preferences_ptr: *const c_void) -> size_t;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4frame.h#L211
    // LZ4FLIB_API size_t LZ4F_compressFrame(void* dstBuffer, size_t dstCapacity,
    //     const void* srcBuffer, size_t srcSize,
    //     const LZ4F_preferences_t* preferencesPtr);
    pub fn LZ4F_compressFrame(
        dst_buffer: *mut u8,
        dst_capacity: size_t,
        src_buffer: *const u8,
        src_size: size_t,
        preferences_ptr: *const c_void,
    ) -> size_t;

    // LZ4FLIB_API LZ4F_errorCode_t LZ4F_createDecompressionContext(LZ4F_dctx** dctxPtr, unsigned version);
    pub fn LZ4F_createDecompressionContext(dctx_ptr: *mut size_t, version: c_uint) -> size_t;

    // LZ4FLIB_API LZ4F_errorCode_t LZ4F_freeDecompressionContext(LZ4F_dctx* dctx);
    pub fn LZ4F_freeDecompressionContext(dctx: *mut c_void) -> size_t;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4frame.h#L370
    // size_t LZ4F_headerSize(const void* src, size_t srcSize);
    pub fn LZ4F_headerSize(src: *const u8, src_size: size_t) -> size_t;

    // LZ4FLIB_API size_t LZ4F_getFrameInfo(LZ4F_dctx* dctx,
    //     LZ4F_frameInfo_t* frameInfoPtr,
    //     const void* srcBuffer, size_t* srcSizePtr);
    pub fn LZ4F_getFrameInfo(
        dctx: *mut c_void,
        frame_info_ptr: *mut c_void,
        src_buffer: *const u8,
        src_size_ptr: *const size_t,
    ) -> size_t;

    // LZ4FLIB_API size_t LZ4F_decompress(LZ4F_dctx* dctx,
    //     void* dstBuffer, size_t* dstSizePtr,
    //     const void* srcBuffer, size_t* srcSizePtr,
    //     const LZ4F_decompressOptions_t* dOptPtr);
    pub fn LZ4F_decompress(
        dctx: *mut c_void,
        dst_buffer: *mut u8,
        dst_size_ptr: *mut size_t,
        src_buffer: *const u8,
        src_size_ptr: *mut size_t,
        d_opt_ptr: *const c_void,
    ) -> size_t;
}
