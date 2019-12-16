use libc::{c_char, c_int, c_uint, c_void, size_t};
use std::mem::transmute;
use std::ptr;

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
pub extern "C" fn ffi_lz4f_get_version() -> c_uint {
    return unsafe { LZ4F_getVersion() };
}

#[no_mangle]
pub extern "C" fn ffi_lz4f_compress_frame_bound(src_size: size_t) -> size_t {
    return unsafe { LZ4F_compressFrameBound(src_size, ptr::null()) };
}

#[no_mangle]
pub extern "C" fn ffi_lz4f_compress_frame(
    dst_buffer: *mut u8,
    dst_capacity: size_t,
    src_buffer: *const u8,
    src_size: size_t,
) -> size_t {
    return unsafe {
        LZ4F_compressFrame(dst_buffer, dst_capacity, src_buffer, src_size, ptr::null())
    };
}

#[no_mangle]
pub extern "C" fn ffi_lz4f_create_decompression_context(dctx_ptr: *mut size_t) -> size_t {
    return unsafe { LZ4F_createDecompressionContext(dctx_ptr, ffi_lz4f_get_version()) };
}

#[no_mangle]
pub fn ffi_lz4f_free_decompression_context(dctx: *mut c_void) -> size_t {
    return unsafe { LZ4F_freeDecompressionContext(dctx) };
}

#[no_mangle]
pub extern "C" fn ffi_lz4f_header_size(src: *const u8, src_size: size_t) -> size_t {
    return unsafe { LZ4F_headerSize(src, src_size) };
}

#[no_mangle]
pub extern "C" fn ffi_lz4f_get_frame_info(
    dctx: *mut c_void,
    frame_info_ptr: *mut c_void,
    src_buffer: *const u8,
    src_size_ptr: *const size_t,
) -> size_t {
    return unsafe { LZ4F_getFrameInfo(dctx, frame_info_ptr, src_buffer, src_size_ptr) };
}

#[no_mangle]
pub extern "C" fn ffi_lz4f_decompress(
    dctx: *mut c_void,
    dst_buffer: *mut u8,
    dst_size_ptr: *mut size_t,
    src_buffer: *const u8,
    src_size_ptr: *mut size_t,
) -> size_t {
    return unsafe {
        LZ4F_decompress(
            dctx,
            dst_buffer,
            dst_size_ptr,
            src_buffer,
            src_size_ptr,
            ptr::null(),
        )
    };
}

#[test]
fn test_ffi_lz4_version_number() {
    ffi_lz4_version_number();
}

#[test]
fn test_ffi_lz4_version_string() {
    ffi_lz4_version_string();
}

#[test]
fn test_ffi_lz4f_get_version() {
    let version = ffi_lz4f_get_version();
    println!("lz4 frame version: {}", version);
}

#[test]
fn test_ffi_lz4f_create_and_free_decompression_context() {
    let mut address: usize = 0;
    let p_address: *mut usize = &mut address;
    ffi_lz4f_create_decompression_context(p_address);
    println!("decompression context address: {}", address);
    let decompression_context_ptr = address as *const ();
    let decompression_context: *mut c_void = unsafe { transmute(decompression_context_ptr) };
    ffi_lz4f_free_decompression_context(decompression_context);
}

#[test]
fn test_ffi_lz4f_compress_frame_and_decompress_frame() {
    let src: Vec<u8> = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 9, 8, 7, 6, 5, 4, 3, 2, 1];
    let src_ptr = src.as_ptr();
    let bound = ffi_lz4f_compress_frame_bound(src.len());
    println!("lz4 frame bound: {}", bound);

    let mut compressed = Vec::with_capacity(bound);
    let compressed_ptr = compressed.as_mut_ptr();
    let compressed_size = ffi_lz4f_compress_frame(compressed_ptr, bound, src_ptr, src.len());
    unsafe { compressed.set_len(compressed_size) };
    println!(
        "lz4 frame compress done, compressed size: {}, array: {:?}",
        compressed_size, compressed,
    );

    let compressed_header_size = ffi_lz4f_header_size(compressed_ptr, compressed_size);
    println!("lz4 frame compress header size: {}", compressed_header_size,);

    let mut decompression_context_address: usize = 0;
    let decompression_context_address_ptr: *mut usize = &mut decompression_context_address;
    ffi_lz4f_create_decompression_context(decompression_context_address_ptr);
    println!(
        "decompression context address: {}",
        decompression_context_address
    );
    let decompression_context_ptr = decompression_context_address as *const ();
    let decompression_context: *mut c_void = unsafe { transmute(decompression_context_ptr) };

    let mut dst_size: usize = compressed_size * 2;
    let dst_size_ptr: *mut usize = &mut dst_size;
    let mut src_size: usize = compressed_size;
    let src_size_ptr: *mut usize = &mut src_size;

    let mut decompressed = Vec::with_capacity(dst_size);
    let decompressed_ptr = decompressed.as_mut_ptr();

    let ret = ffi_lz4f_decompress(
        decompression_context,
        decompressed_ptr,
        dst_size_ptr,
        compressed_ptr,
        src_size_ptr,
    );
    assert!(ret == 0);
    unsafe { decompressed.set_len(dst_size) };
    println!(
        "ret: {}, src size: {}, dst size: {}, decompressed: {:?}",
        ret, src_size, dst_size, decompressed
    );

    assert_eq!(src, decompressed);

    ffi_lz4f_free_decompression_context(decompression_context);
}
