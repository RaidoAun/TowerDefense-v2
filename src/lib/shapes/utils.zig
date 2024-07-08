pub fn clamp(comptime T: type, value: T, min: T, max: T) T {
    return if (value < min) min else if (value > max) max else value;
}
