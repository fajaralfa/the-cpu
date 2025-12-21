pub const assembler = @import("assembler.zig");
pub const cpu = @import("cpu.zig");

test {
    // This ensures tests in imported files are discovered
    _ = @import("assembler.zig");
    _ = @import("cpu.zig");
}
