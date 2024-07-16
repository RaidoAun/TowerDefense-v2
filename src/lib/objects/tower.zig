const Tower = union(enum) {
    const Self = @This();
    basic: BasicTurret,
    laser: Laser,

    fn attack(self: Self) void {
        switch (self) {
            .basic => |v| {
                v.bullets;
            },
        }
    }
};

const Base = struct {
    // assume these to be the center of the tower
    x: i32,
    y: i32,
    level: u16,
};

const BasicTurret = struct {
    tower: Base,
    bullets: []bool, //temp
};
const Laser = struct {
    tower: Base,
    a_field: []bool, //temp
};
