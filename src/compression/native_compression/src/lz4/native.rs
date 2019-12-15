use libc::{c_char, c_int};

// Full API doc: https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4.h
#[allow(non_snake_case)]
extern "C" {
    // LZ4LIB_API int LZ4_versionNumber (void);  /**< library version number; useful to check dll version */
    pub fn LZ4_versionNumber() -> c_int;

    // LZ4LIB_API const char* LZ4_versionString (void);   /**< library version string; useful to check dll version */
    pub fn LZ4_versionString() -> *const c_char;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4.h#L134
    // LZ4LIB_API int LZ4_compress_default(const char* src, char* dst, int srcSize, int dstCapacity);
    pub fn LZ4_compress_default(
        src: *const c_char,
        dst: *mut c_char,
        srcSize: c_int,
        dstCapacity: c_int,
    ) -> c_int;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4.h#L150
    // LZ4LIB_API int LZ4_decompress_safe (const char* src, char* dst, int compressedSize, int dstCapacity);
    pub fn LZ4_decompress_safe(
        src: *const c_char,
        dst: *mut c_char,
        compressedSize: c_int,
        dstCapacity: c_int,
    ) -> c_int;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4.h#L173
    // LZ4LIB_API int LZ4_compressBound(int inputSize);
    pub fn LZ4_compressBound(inputSize: c_int) -> c_int;

    // https://github.com/lz4/lz4/blob/v1.9.2/lib/lz4.h#L184
    // LZ4LIB_API int LZ4_compress_fast (const char* src, char* dst, int srcSize, int dstCapacity, int acceleration);
    pub fn LZ4_compress_fast(
        src: *const c_char,
        dst: *mut c_char,
        srcSize: c_int,
        dstCapacity: c_int,
        acceleration: c_int,
    ) -> c_int;
}
