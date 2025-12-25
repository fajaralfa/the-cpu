const std = @import("std");
const cpu = @import("cpu.zig");

pub const UART = struct {
    rx_ready: bool = false,
    rx_data: u8 = 0,
};

pub fn uartRead(ctx: *anyopaque, addr: u16) cpu.CPUError!u16 {
    const uart: *UART = @ptrCast(@alignCast(ctx));

    return switch (addr) {
        0 => uart.rx_data,
        2 => blk: {
            var status: u16 = 0x2; // TX ready
            if (uart.rx_ready) status |= 0x1;
            break :blk status;
        },
        else => cpu.CPUError.InvalidAddress,
    };
}

pub fn uartWrite(ctx: *anyopaque, addr: u16, value: u16) cpu.CPUError!void {
    const uart: *UART = @ptrCast(@alignCast(ctx));
    _ = uart;

    switch (addr) {
        0 => {
            std.debug.print("{c}", .{@as(u8, @intCast(value))});
            return;
        },
        else => {
            return cpu.CPUError.InvalidAddress;
        },
    }
}
