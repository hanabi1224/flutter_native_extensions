use libc::{c_char, c_int};

mod native;
use native::*;

#[no_mangle]
pub extern "C" fn ffi_lz4_version_number() -> c_int {
    return unsafe { LZ4_versionNumber() };
}

#[no_mangle]
pub extern "C" fn ffi_lz4_version_string() -> *const c_char {
    return unsafe { LZ4_versionString() };
}

#[no_mangle]
pub extern "C" fn ffi_lz4_compress_default(
    src: *const c_char,
    dst: *mut c_char,
    src_size: c_int,
    dst_capacity: c_int,
) -> c_int {
    return unsafe { LZ4_compress_default(src, dst, src_size, dst_capacity) };
}

#[no_mangle]
pub extern "C" fn ffi_lz4_decompress_safe(
    src: *const c_char,
    dst: *mut c_char,
    compressed_size: c_int,
    dst_capacity: c_int,
) -> c_int {
    return unsafe { LZ4_decompress_safe(src, dst, compressed_size, dst_capacity) };
}

#[no_mangle]
pub extern "C" fn ffi_lz4_compress_bound(input_size: c_int) -> c_int {
    return unsafe { LZ4_compressBound(input_size) };
}

#[no_mangle]
pub fn ffi_lz4_compress_fast(
    src: *const c_char,
    dst: *mut c_char,
    src_size: c_int,
    dst_capacity: c_int,
    acceleration: c_int,
) -> c_int {
    return unsafe { LZ4_compress_fast(src, dst, src_size, dst_capacity, acceleration) };
}

#[test]
fn test_ffi_lz4_version_number() {
    ffi_lz4_version_number();
}

#[test]
fn test_ffi_lz4_version_string() {
    ffi_lz4_version_string();
}
