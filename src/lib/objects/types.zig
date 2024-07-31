pub const Position = struct {
    pub const T = f32;
    x: T,
    y: T,
    pub fn distanceBetween(p1: Position, p2: Position) T {
        return @sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
    }
};
