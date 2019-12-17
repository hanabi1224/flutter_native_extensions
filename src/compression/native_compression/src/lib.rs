mod lz4;

use libc::size_t;

#[no_mangle]
pub extern "C" fn ffi_create_buffer(size: size_t) -> *mut u8 {
    let mut buffer: Vec<u8> = vec![0; size];
    // The caller must ensure that the vector outlives the pointer this function returns,
    // or else it will end up pointing to garbage.
    // Modifying the vector may cause its buffer to be reallocated,
    // which would also make any pointers to it invalid.
    let ptr = buffer.as_mut_ptr();
    std::mem::forget(buffer);
    return ptr;
}

#[no_mangle]
pub extern "C" fn ffi_free_buffer(buffer: *mut u8, size: size_t) {
    // The ownership of ptr is effectively transferred to the Vec<T> which may then deallocate,
    // reallocate or change the contents of memory pointed to by the pointer at will.
    // Ensure that nothing else uses the pointer after calling this function.
    drop(unsafe { Vec::<u8>::from_raw_parts(buffer, size, size) });
}
