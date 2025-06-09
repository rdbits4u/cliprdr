const std = @import("std");
const parse = @import("parse");
const c = @cImport(
{
    @cInclude("libcliprdr.h");
});

const g_devel = false;

const CB_USE_LONG_FORMAT_NAMES      = 0x00000002;
const CB_STREAM_FILECLIP_ENABLED    = 0x00000004;
const CB_FILECLIP_NO_FILE_PATHS     = 0x00000008;
const CB_CAN_LOCK_CLIPDATA          = 0x00000010;
const CB_HUGE_FILE_SUPPORT_ENABLED  = 0x00000020;

// message type values
const CB_MONITOR_READY          = 0x0001;
const CB_FORMAT_LIST            = 0x0002;
const CB_FORMAT_LIST_RESPONSE   = 0x0003;
const CB_FORMAT_DATA_REQUEST    = 0x0004;
const CB_FORMAT_DATA_RESPONSE   = 0x0005;
const CB_TEMP_DIRECTORY         = 0x0006;
const CB_CLIP_CAPS              = 0x0007;
const CB_FILECONTENTS_REQUEST   = 0x0008;
const CB_FILECONTENTS_RESPONSE  = 0x0009;
const CB_LOCK_CLIPDATA          = 0x000A;
const CB_UNLOCK_CLIPDATA        = 0x000B;
const CB_CLIPBOARD_CHANGED      = 0x0010;

const CB_CAPSTYPE_GENERAL       = 0x0001;

// c abi struct
pub const cliprdr_priv_t = extern struct
{
    cliprdr: c.struct_cliprdr_t = .{},
    allocator: *const std.mem.Allocator,
    version: u32 = 0,
    general_flags: u32 = 0,
    got_caps: bool = false,

    //*************************************************************************
    pub fn delete(self: *cliprdr_priv_t) void
    {
        self.allocator.destroy(self);
    }

    //*************************************************************************
    pub fn logln(self: *cliprdr_priv_t, src: std.builtin.SourceLocation,
            comptime fmt: []const u8, args: anytype) !void
    {
        // check if function is assigned
        if (self.cliprdr.log_msg) |alog_msg|
        {
            const alloc_buf = try std.fmt.allocPrint(self.allocator.*,
                    fmt, args);
            defer self.allocator.free(alloc_buf);
            const alloc1_buf = try std.fmt.allocPrintZ(self.allocator.*,
                    "cliprdr:{s}:{s}", .{src.fn_name, alloc_buf});
            defer self.allocator.free(alloc1_buf);
            _ = alog_msg(&self.cliprdr, alloc1_buf.ptr);
        }
    }

    //*************************************************************************
    pub fn logln_devel(self: *cliprdr_priv_t, src: std.builtin.SourceLocation,
            comptime fmt: []const u8, args: anytype) !void
    {
        if (g_devel)
        {
            return self.logln(src, fmt, args);
        }
    }

    //*************************************************************************
    fn cliprdr_process_monitor_ready(self: *cliprdr_priv_t, channel_id: u16,
            s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "", .{});
        _ = s;
        var rv: c_int = 0;
        if (self.cliprdr.ready) |aready|
        {
            rv = aready(&self.cliprdr, channel_id, self.version,
                    self.general_flags);
        }
        return rv;
    }

    //*************************************************************************
    fn cliprdr_process_format_list(self: *cliprdr_priv_t, channel_id: u16,
            s: *parse.parse_t, msg_flags: u16) !c_int
    {
        try self.logln(@src(), "", .{});
        var rv: c_int = c.LIBCLIPRDR_ERROR_FORMAT_LIST;
        var formats = std.ArrayList(c.cliprdr_format_t).init(self.allocator.*);
        defer formats.deinit();
        if ((self.general_flags & CB_USE_LONG_FORMAT_NAMES) != 0)
        {
            while (s.check_rem_bool(6))
            {
                var format: c.cliprdr_format_t = .{};
                format.format_id = s.in_u32_le();
                format.format_name = &s.data[s.offset];
                while (s.check_rem_bool(2))
                {
                    const chr16 = s.in_u16_le();
                    format.format_name_bytes += 2;
                    if (chr16 == 0)
                    {
                        break;
                    }
                }
                try formats.append(format);
            }
        }
        else
        {
            while (s.check_rem_bool(36))
            {
                var format: c.cliprdr_format_t = .{};
                format.format_id = s.in_u32_le();
                format.format_name = &s.data[s.offset];
                format.format_name_bytes = 32;
                s.in_u8_skip(32);
                try formats.append(format);
            }
        }
        if (self.cliprdr.format_list) |aformat_list|
        {
            rv = aformat_list(&self.cliprdr, channel_id, msg_flags,
                    @truncate(formats.items.len), formats.items.ptr);
        }
        return rv;
    }

    //*************************************************************************
    fn cliprdr_process_format_list_response(self: *cliprdr_priv_t,
            channel_id: u16, msg_flags: u16) !c_int
    {
        try self.logln(@src(), "", .{});
        var rv: c_int = c.LIBCLIPRDR_ERROR_FORMAT_LIST_RESPONSE;
        if (self.cliprdr.format_list_response) |aformat_list_response|
        {
            rv = aformat_list_response(&self.cliprdr, channel_id, msg_flags);
        }
        return rv;
    }

    //*************************************************************************
    fn cliprdr_process_data_request(self: *cliprdr_priv_t,
            channel_id: u16, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "", .{});
        var rv: c_int = c.LIBCLIPRDR_ERROR_DATA_REQUEST;
        try s.check_rem(4);
        const requested_format_id = s.in_u32_le();
        if (self.cliprdr.data_request) |adata_request|
        {
            rv = adata_request(&self.cliprdr, channel_id, requested_format_id);
        }
        return rv;
    }

    //*************************************************************************
    fn cliprdr_process_data_response(self: *cliprdr_priv_t,
            channel_id: u16, s: *parse.parse_t, msg_flags: u16) !c_int
    {
        try self.logln(@src(), "", .{});
        var rv: c_int = c.LIBCLIPRDR_ERROR_DATA_RESPONSE;
        const bytes: u32 = @truncate(s.get_rem());
        const data: *u8 = &s.data[s.offset];
        if (self.cliprdr.data_response) |adata_response|
        {
            rv = adata_response(&self.cliprdr, channel_id, msg_flags,
                    data, bytes);
        }
        return rv;
    }

    //*************************************************************************
    fn cliprdr_process_caps_general(self: *cliprdr_priv_t, channel_id: u16,
            s: *parse.parse_t) !c_int
    {
        try s.check_rem(8);
        self.version = s.in_u32_le();
        self.general_flags = s.in_u32_le();
        try self.logln(@src(),
                "channel_id 0x{X} version {} general_flags {}",
                .{channel_id, self.version, self.general_flags});
        return c.LIBCLIPRDR_ERROR_NONE;
    }

    //*************************************************************************
    fn cliprdr_process_caps(self: *cliprdr_priv_t, channel_id: u16,
            s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "", .{});
        var rv: c_int = c.LIBCLIPRDR_ERROR_NONE;
        try s.check_rem(4);
        const cCapabilitiesSets = s.in_u16_le();
        s.in_u8_skip(2); // pad1
        var index: u16 = 0;
        while (index < cCapabilitiesSets) : (index += 1)
        {
            try s.check_rem(4);
            const capabilitySetType = s.in_u16_le();
            const lengthCapability = s.in_u16_le();
            if (lengthCapability < 4)
            {
                return c.LIBCLIPRDR_ERROR_PARSE;
            }
            try s.check_rem(lengthCapability - 4);
            const cap_s = try parse.create_from_slice(self.allocator,
                    s.in_u8_slice(lengthCapability - 4));
            defer cap_s.delete();
            rv = switch (capabilitySetType)
            {
                CB_CAPSTYPE_GENERAL => try self.cliprdr_process_caps_general(channel_id, cap_s),
                else => c.LIBCLIPRDR_ERROR_NONE,
            };
        }
        self.got_caps = true;
        return rv;
    }

    //*************************************************************************
    pub fn process_slice(self: *cliprdr_priv_t, channel_id: u16,
            slice: []u8) !c_int
    {
        const s = try parse.create_from_slice(self.allocator, slice);
        defer s.delete();
        try s.check_rem(8);
        const msg_type = s.in_u16_le();
        const msg_flags = s.in_u16_le();
        const msg_length = s.in_u32_le();
        try s.check_rem(msg_length);
        try self.logln(@src(),
                "channel_id 0x{X} msg_type {} msg_flags 0x{X} msg_length {}",
                .{channel_id, msg_type, msg_flags, msg_length});
        return switch (msg_type)
        {
            CB_MONITOR_READY => try self.cliprdr_process_monitor_ready(channel_id, s),
            CB_FORMAT_LIST => try self.cliprdr_process_format_list(channel_id, s, msg_flags),
            CB_FORMAT_LIST_RESPONSE => try self.cliprdr_process_format_list_response(channel_id, msg_flags),
            CB_FORMAT_DATA_REQUEST => try self.cliprdr_process_data_request(channel_id, s),
            CB_FORMAT_DATA_RESPONSE => try self.cliprdr_process_data_response(channel_id, s, msg_flags),
            CB_CLIP_CAPS => try self.cliprdr_process_caps(channel_id, s),
            else => c.LIBCLIPRDR_ERROR_NONE,
        };
    }

    //*************************************************************************
    pub fn send_capabilities(self: *cliprdr_priv_t, channel_id: u16,
            version: u32, general_flags: u32) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} version {} general_flags {}",
                .{channel_id, version, general_flags});
        if (!self.got_caps)
        {
            return c.LIBCLIPRDR_ERROR_SEND_CAPS;
        }
        const s = try parse.create(self.allocator, 64);
        defer s.delete();
        try s.check_rem(8);
        s.push_layer(8, 0);
        try s.check_rem(16);
        s.out_u16_le(1); // num caps
        s.out_u8_skip(2); // pad
        s.out_u16_le(CB_CAPSTYPE_GENERAL);
        s.out_u16_le(12);
        s.out_u32_le(version);
        s.out_u32_le(general_flags);
        s.push_layer(0, 1);
        s.pop_layer(0);
        s.out_u16_le(CB_CLIP_CAPS);
        s.out_u16_le(0);
        s.out_u32_le(s.layer_subtract(1, 0) - 8);
        s.pop_layer(1);
        const slice = s.get_out_slice();
        try self.logln(@src(), "send slice len {}", .{slice.len});
        if (self.cliprdr.send_data) |asend_data|
        {
            return asend_data(&self.cliprdr, channel_id,
                    slice.ptr, @truncate(slice.len));
        }
        return c.LIBCLIPRDR_ERROR_SEND_CAPS;
    }

    //*************************************************************************
    pub fn send_format_list(self: *cliprdr_priv_t, channel_id: u16,
            msg_flags: u16, num_fomats: u32,
            formats: [*]c.cliprdr_format_t) !c_int
    {
        try self.logln(@src(), "", .{});
        _ = channel_id;
        _ = msg_flags;
        _ = num_fomats;
        _ = formats;
        return c.LIBCLIPRDR_ERROR_SEND_FORMAT_LIST;
    }

    //*************************************************************************
    pub fn send_format_list_response(self: *cliprdr_priv_t, channel_id: u16,
            msg_flags: u16) !c_int
    {
        try self.logln(@src(), "msg_flags {}", .{msg_flags});
        const s = try parse.create(self.allocator, 64);
        defer s.delete();
        try s.check_rem(4);
        s.out_u16_le(CB_FORMAT_LIST_RESPONSE);
        s.out_u16_le(msg_flags);
        const slice = s.get_out_slice();
        try self.logln(@src(), "send slice len {}", .{slice.len});
        if (self.cliprdr.send_data) |asend_data|
        {
            return asend_data(&self.cliprdr, channel_id,
                    slice.ptr, @truncate(slice.len));
        }
        return c.LIBCLIPRDR_ERROR_FORMAT_LIST_RESPONSE;
    }

    //*************************************************************************
    pub fn send_data_request(self: *cliprdr_priv_t, channel_id: u16,
            requested_format_id: u32) !c_int
    {
        try self.logln(@src(), "requested_format_id {}",
                .{requested_format_id});
        const s = try parse.create(self.allocator, 64);
        defer s.delete();
        try s.check_rem(8);
        s.out_u16_le(CB_FORMAT_DATA_REQUEST);
        s.out_u16_le(0);
        s.out_u32_le(requested_format_id);
        const slice = s.get_out_slice();
        try self.logln(@src(), "send slice len {}", .{slice.len});
        if (self.cliprdr.send_data) |asend_data|
        {
            return asend_data(&self.cliprdr, channel_id,
                    slice.ptr, @truncate(slice.len));
        }
        return c.LIBCLIPRDR_ERROR_DATA_REQUEST;
    }

    //*************************************************************************
    pub fn send_data_response(self: *cliprdr_priv_t, channel_id: u16,
            msg_flags: u16, requested_format_data: ?*anyopaque,
            requested_format_data_bytes: u32) !c_int
    {
        try self.logln(@src(), "", .{});
        _ = channel_id;
        _ = msg_flags;
        _ = requested_format_data;
        _ = requested_format_data_bytes;
        return c.LIBCLIPRDR_ERROR_DATA_RESPONSE;
    }

};

//*****************************************************************************
pub fn create(allocator: *const std.mem.Allocator) !*cliprdr_priv_t
{
    const priv: *cliprdr_priv_t = try allocator.create(cliprdr_priv_t);
    errdefer allocator.destroy(priv);
    priv.* = .{.allocator = allocator};
    return priv;
}
