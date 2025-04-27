const std = @import("std");
const builtin = @import("builtin");

const esp = struct {
    usingnamespace @cImport({
        @cInclude("sdkconfig.h");
        @cInclude("esp_err.h");
        @cInclude("esp_log.h");
        @cInclude("driver/gpio.h");

        // As of Zig 0.11 and version 2.5.2 of the led_strip component, we cannot
        // include the header with @cImport because the led_strip_config_t struct in
        // led_strip_types.h contains a bitfield, which Zig's translate-c converts
        // into an opaque type which causes compilation to fail.
        // @cInclude("led_strip.h");
    });
};

const freertos = @cImport({
    @cInclude("freertos/FreeRTOS.h");
    @cInclude("freertos/task.h");
});

//const BLINK_GPIO = esp.CONFIG_BLINK_GPIO;

// pub const std_options = struct {
//     pub fn logFn(comptime message_level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
//         const color = switch (message_level) {
//             .err => "\x1b[31m", // red
//             .warn => "\x1b[33m", // yellow
//             .info => "\x1b[32m", // green
//             .debug => "",
//         };

//         const esp_level = switch (message_level) {
//             .err => esp.ESP_LOG_ERROR,
//             .warn => esp.ESP_LOG_WARN,
//             .info => esp.ESP_LOG_INFO,
//             .debug => esp.ESP_LOG_DEBUG,
//         };

//         const prefix = switch (message_level) {
//             .err => "E",
//             .warn => "W",
//             .info => "I",
//             .debug => "D",
//         };

//         const fmt = std.fmt.comptimePrint(color ++ prefix ++ " (%u): {s}\x1b[0m\n", .{format});
//         const timestamp = esp.esp_log_timestamp();
//         @call(.auto, esp.esp_log_write, .{ esp_level, @tagName(scope), fmt, timestamp } ++ args);
//     }
// };

export fn app_main() void {
    var io_conf = esp.gpio_config_t{
        .pin_bit_mask = 1 << 2, // (1 << GPIO_NUM_2)
        .mode = esp.GPIO_MODE_OUTPUT,
        .pull_up_en = esp.GPIO_PULLUP_DISABLE,
        .pull_down_en = esp.GPIO_PULLDOWN_DISABLE,
        .intr_type = esp.GPIO_INTR_DISABLE,
    };
    _ = esp.gpio_config(&io_conf);

    while (true) {
        // 2. Turn ON the LED (active low = write 0)
        _ = esp.gpio_set_level(2, 0);

        freertos.vTaskDelay(500 / freertos.portTICK_PERIOD_MS);

        // 3. Turn OFF the LED (active low = write 1)
        _ = esp.gpio_set_level(2, 1);

        freertos.vTaskDelay(500 / freertos.portTICK_PERIOD_MS);
    }
}

pub const std_options: std.Options = .{
    .log_level = .info,
    .logFn = customLogFn,
};

fn customLogFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const esp_level = switch (level) {
        .err => esp.ESP_LOG_ERROR,
        .warn => esp.ESP_LOG_WARN,
        .info => esp.ESP_LOG_INFO,
        .debug => esp.ESP_LOG_DEBUG,
    };

    const timestamp = esp.esp_log_timestamp();

    const color = switch (level) {
        .err => "\x1b[31m", // red
        .warn => "\x1b[33m", // yellow
        .info => "\x1b[32m", // green
        .debug => "",
    };

    const prefix = switch (level) {
        .err => "E",
        .warn => "W",
        .info => "I",
        .debug => "D",
    };

    const fmt = std.fmt.comptimePrint(color ++ prefix ++ " (%u): {s}\x1b[0m\n", .{format});

    @call(.auto, esp.esp_log_write, .{
        esp_level,
        @as([*c]const u8, @tagName(scope)), // still cast tagName
        fmt, // but just .ptr for format
        timestamp,
    } ++ args);
}
