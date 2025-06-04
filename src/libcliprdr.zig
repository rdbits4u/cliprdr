const std = @import("std");
const cliprdr_priv = @import("cliprdr_priv.zig");
const c = @cImport(
{
    @cInclude("libcliprdr.h");
});

var g_allocator: std.mem.Allocator = std.heap.c_allocator;

// int cliprdr_init(void);
export fn cliprdr_init() c_int
{
    return c.LIBCLIPRDR_ERROR_NONE;
}

// int cliprdr_deinit(void);
export fn cliprdr_deinit() c_int
{
    return c.LIBCLIPRDR_ERROR_NONE;
}

// int cliprdr_create(struct cliprdr_t** cliprdr);
export fn cliprdr_create(cliprdr: ?**c.cliprdr_t) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        const priv = cliprdr_priv.create(&g_allocator) catch
                return c.LIBCLIPRDR_ERROR_MEMORY;
        acliprdr.* = @ptrCast(priv);
        return c.LIBCLIPRDR_ERROR_NONE;
    }
    return c.LIBCLIPRDR_ERROR_MEMORY;
}

// int cliprdr_delete(struct cliprdr_t* cliprdr);
export fn cliprdr_delete(cliprdr: ?*c.cliprdr_t) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        priv.delete();
    }
    return c.LIBCLIPRDR_ERROR_NONE;
}

// int cliprdr_process_data(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                          void* data, uint32_t bytes);
export fn cliprdr_process_data(cliprdr: ?*c.cliprdr_t, channel_id: u16,
        data: ?*anyopaque, bytes: u32) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        if (data) |adata|
        {
            var slice: []u8 = undefined;
            slice.ptr = @ptrCast(adata);
            slice.len = bytes;
            return priv.process_slice(channel_id, slice) catch
                    c.LIBCLIPRDR_ERROR_PROCESS_DATA;
        }
    }
    return c.LIBCLIPRDR_ERROR_PROCESS_DATA;
}

// int cliprdr_send_capabilities(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                               uint32_t version, uint32_t general_flags);
export fn cliprdr_send_capabilities(cliprdr: ?*c.cliprdr_t, channel_id: u16,
        version: u32, general_flags: u32) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        return priv.send_capabilities(channel_id, version, general_flags)
                catch c.LIBCLIPRDR_ERROR_SEND_CAPS;
    }
    return c.LIBCLIPRDR_ERROR_SEND_CAPS;
}

