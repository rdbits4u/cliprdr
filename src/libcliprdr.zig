const std = @import("std");
const cliprdr_priv = @import("cliprdr_priv.zig");
const c = cliprdr_priv.c;

var g_allocator: std.mem.Allocator = std.heap.c_allocator;

//*****************************************************************************
// int cliprdr_init(void);
export fn cliprdr_init() c_int
{
    return c.LIBCLIPRDR_ERROR_NONE;
}

//*****************************************************************************
// int cliprdr_deinit(void);
export fn cliprdr_deinit() c_int
{
    return c.LIBCLIPRDR_ERROR_NONE;
}

//*****************************************************************************
// int cliprdr_create(struct cliprdr_t** cliprdr);
export fn cliprdr_create(cliprdr: ?**c.cliprdr_t) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        const priv = cliprdr_priv.cliprdr_priv_t.create(&g_allocator) catch
                return c.LIBCLIPRDR_ERROR_MEMORY;
        acliprdr.* = @ptrCast(priv);
        return c.LIBCLIPRDR_ERROR_NONE;
    }
    return c.LIBCLIPRDR_ERROR_MEMORY;
}

//*****************************************************************************
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

//*****************************************************************************
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

//*****************************************************************************
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

//*****************************************************************************
// int cliprdr_send_format_list(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                              uint16_t msg_flags, uint32_t num_formats,
//                              struct cliprdr_format_t* formats);
export fn cliprdr_send_format_list(cliprdr: ?*c.cliprdr_t,
        channel_id: u16, msg_flags: u16, num_formats: u32,
        formats: [*]c.cliprdr_format_t) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        return priv.send_format_list(channel_id, msg_flags,
                num_formats, formats)
                catch c.LIBCLIPRDR_ERROR_FORMAT_LIST;
    }
    return c.LIBCLIPRDR_ERROR_FORMAT_LIST;
}

//*****************************************************************************
// int cliprdr_send_format_list_response(struct cliprdr_t* cliprdr,
//                                       uint16_t msg_flags);
export fn cliprdr_send_format_list_response(cliprdr: ?*c.cliprdr_t,
        channel_id: u16, msg_flags: u16) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        return priv.send_format_list_response(channel_id, msg_flags)
                catch c.LIBCLIPRDR_ERROR_FORMAT_LIST_RESPONSE;
    }
    return c.LIBCLIPRDR_ERROR_FORMAT_LIST_RESPONSE;
}

//*****************************************************************************
// int cliprdr_send_data_request(struct cliprdr_t* cliprdr,
//                               uint16_t channel_id,
//                               uint32_t requested_format_id);
export fn cliprdr_send_data_request(cliprdr: ?*c.cliprdr_t,
        channel_id: u16, requested_format_id: u32) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        return priv.send_data_request(channel_id, requested_format_id)
                catch c.LIBCLIPRDR_ERROR_DATA_REQUEST;
    }
    return c.LIBCLIPRDR_ERROR_DATA_REQUEST;
}

//*****************************************************************************
// int cliprdr_send_data_response(struct cliprdr_t* cliprdr,
//                                uint16_t channel_id, uint16_t msg_flags,
//                                void* requested_format_data,
//                                uint32_t requested_format_data_bytes);
export fn cliprdr_send_data_response(cliprdr: ?*c.cliprdr_t, channel_id: u16,
        msg_flags: u16,  requested_format_data: ?*anyopaque,
        requested_format_data_bytes: u32) c_int
{
    // check if cliprdr is nil
    if (cliprdr) |acliprdr|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *cliprdr_priv.cliprdr_priv_t = @ptrCast(acliprdr);
        return priv.send_data_response(channel_id, msg_flags,
                requested_format_data, requested_format_data_bytes)
                catch c.LIBCLIPRDR_ERROR_DATA_RESPONSE;
    }
    return c.LIBCLIPRDR_ERROR_DATA_RESPONSE;
}
