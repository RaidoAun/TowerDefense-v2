const std = @import("std");
const testing = @import("std").testing;

pub const Vector = struct {
    const Self = @This();
    pub const T = f32;
    x: T,
    y: T,

    pub fn length(self: Self) T {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn normalize(self: Self) Vector {
        const len = self.length();
        // If this happens at runtime (it can but maybe it never will)
        // then just make it either be a default value
        // or return an error and let the caller handle it.
        std.debug.assert(len != 0);
        return Vector{
            .x = self.x / len,
            .y = self.y / len,
        };
    }

    pub fn withLength(self: Self, new_length: T) Vector {
        const unit_vector = self.normalize();
        return Vector{
            .x = unit_vector.x * new_length,
            .y = unit_vector.y * new_length,
        };
    }
};
pub const Position = struct {
    const Self = @This();
    pub const T = f32;
    x: T,
    y: T,
    pub fn distanceTo(self: Self, p2: Position) T {
        return distanceBetween(self, p2);
    }

    pub fn distanceBetween(p1: Position, p2: Position) T {
        return @sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
    }

    pub fn vectorTo(self: Self, pos: Position) Vector {
        return Vector{
            .x = pos.x - self.x,
            .y = pos.y - self.y,
        };
    }
    pub fn applyVector(self: Self, vec: Vector) Self {
        return .{
            .x = self.x + vec.x,
            .y = self.y + vec.y,
        };
    }
};

test "vector length" {
    const v1 = Vector{ .x = 1.0, .y = 0 };
    try testing.expect(v1.length() == 1.0);

    const v2 = Vector{ .x = 0, .y = 1.0 };
    try testing.expect(v2.length() == 1.0);

    const v3 = Vector{ .x = 3.0, .y = 4.0 };
    try testing.expect(v3.length() == 5.0);
}

test "vector toLength" {
    const v1 = Vector{ .x = 1.0, .y = 0 };
    try testing.expect(v1.withLength(2.0).length() == 2.0);

    const v2 = Vector{ .x = 0, .y = 1.0 };
    try testing.expect(v2.withLength(2.0).length() == 2.0);

    const v3 = Vector{ .x = 3.0, .y = 4.0 };
    try testing.expect(v3.withLength(2.0).length() == 2.0);
    try testing.expect(v3.length() == 5.0);

    const v4 = Vector{ .x = 3.0, .y = 4.0 };
    try testing.expect(v4.withLength(50.0).length() == 50.0);
    try testing.expect(v4.length() == 5.0);
}
