shader_type particles;

uniform vec3 box_size = vec3(60.0, 20.0, 40.0); // The size of your "sky area"
uniform float move_speed = 3.0;

// Helper to create a random-ish starting position
float rand(uint seed) {
	seed = (seed << 13U) ^ seed;
	return float((seed * (seed * seed * 15731U + 789221U) + 1376312589U) & 0x7fffffffU) / 2147483647.0;
}

void start() {
	// Randomly scatter particles within the box when they first spawn
	float rx = (rand(NUMBER + uint(1)) - 0.5) * box_size.x;
	float ry = (rand(NUMBER + uint(2)) - 0.5) * box_size.y;
	float rz = (rand(NUMBER + uint(3)) - 0.5) * box_size.z;
	
	TRANSFORM[3].xyz = vec3(rx, ry, rz);
}

void process() {
	// 1. Move them in one direction (X axis)
	TRANSFORM[3].x += DELTA * move_speed;

	// 2. The "Wrap Around" Logic
	// If particle goes past the right side of the box, teleport to the left
	float half_width = box_size.x / 2.0;
	if (TRANSFORM[3].x > half_width) {
		TRANSFORM[3].x = -half_width;
	}

	// 3. Simple rotation so they tumble
	float angle = TIME * 0.5 + float(NUMBER);
	mat3 rot_y = mat3(vec3(cos(angle), 0, sin(angle)), vec3(0, 1, 0), vec3(-sin(angle), 0, cos(angle)));
	TRANSFORM[0].xyz = rot_y[0];
	TRANSFORM[1].xyz = rot_y[1];
	TRANSFORM[2].xyz = rot_y[2];
}