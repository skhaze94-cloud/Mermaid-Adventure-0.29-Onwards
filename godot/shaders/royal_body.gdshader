shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
uniform float strength = 0.0;
uniform vec3 pose = vec3(0.0);
uniform vec4 limbs = vec4(0.0);     // near shoulder, near elbow, near wrist, far shoulder
uniform vec4 secondary = vec4(0.0); // far elbow, far wrist, head turn, torso lean
uniform bool is_queen = false;
uniform float tutorial_life = 0.0;
uniform vec2 travel = vec2(0.0);
uniform float attention = 0.0;
uniform float breath = 0.0;

vec2 rotate_about(vec2 p, vec2 pivot, float angle) {
	vec2 d = p - pivot;
	// Small-angle second-order rotation keeps the six soft joint bends inexpensive
	// on mobile GPUs while remaining accurate across the authored tutorial range.
	float half_square = 0.5 * angle * angle;
	return p + vec2(-d.y * angle - d.x * half_square, d.x * angle - d.y * half_square);
}

float segment_weight(vec2 p, vec2 a, vec2 b, float radius) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	float distance_to_bone = length(p - (a + ab * t));
	return 1.0 - smoothstep(radius * 0.60, radius, distance_to_bone);
}

void vertex() {
	vec2 p = VERTEX;
	vec2 uv = UV;
	float life = strength * tutorial_life;
	float near_upper;
	float near_forearm;
	float near_hand;
	float far_upper;
	float far_forearm;
	float far_hand;
	vec2 near_shoulder;
	vec2 near_elbow;
	vec2 near_wrist;
	vec2 far_shoulder;
	vec2 far_elbow;
	vec2 far_wrist;

	if (is_queen) {
		// Antonella's open pearl hand and flowing sleeve.
		near_shoulder = vec2(0.66, 0.34);
		near_elbow = vec2(0.78, 0.28);
		near_wrist = vec2(0.90, 0.23);
		far_shoulder = vec2(0.36, 0.34);
		far_elbow = vec2(0.24, 0.43);
		far_wrist = vec2(0.14, 0.45);
		near_upper = segment_weight(uv, near_shoulder, near_elbow, 0.072);
		near_forearm = segment_weight(uv, near_elbow, near_wrist, 0.054);
		near_hand = segment_weight(uv, near_wrist, vec2(0.98, 0.22), 0.042);
		far_upper = segment_weight(uv, far_shoulder, far_elbow, 0.075);
		far_forearm = segment_weight(uv, far_elbow, far_wrist, 0.050);
		far_hand = segment_weight(uv, far_wrist, vec2(0.105, 0.42), 0.040);
	} else {
		// Daddy's offering arm is expressive; his trident hand stays deliberately steady.
		near_shoulder = vec2(0.65, 0.27);
		near_elbow = vec2(0.78, 0.35);
		near_wrist = vec2(0.86, 0.30);
		far_shoulder = vec2(0.38, 0.27);
		far_elbow = vec2(0.27, 0.36);
		far_wrist = vec2(0.21, 0.32);
		near_upper = segment_weight(uv, near_shoulder, near_elbow, 0.078);
		near_forearm = segment_weight(uv, near_elbow, near_wrist, 0.060);
		near_hand = segment_weight(uv, near_wrist, vec2(0.94, 0.30), 0.050);
		far_upper = segment_weight(uv, far_shoulder, far_elbow, 0.062);
		far_forearm = segment_weight(uv, far_elbow, far_wrist, 0.043);
		far_hand = segment_weight(uv, far_wrist, vec2(0.19, 0.25), 0.032);
	}

	// A gently connected torso and neck lead the action. The head gets its own pivot,
	// so nods and attention shifts do not twist the shoulders or flatten the face.
	float torso = smoothstep(0.21, 0.32, uv.y) * (1.0 - smoothstep(0.69, 0.82, uv.y)) * (1.0 - smoothstep(0.26, 0.48, abs(uv.x - 0.5)));
	float head = 1.0 - smoothstep(0.115, 0.175, length((uv - vec2(0.51, 0.145)) * vec2(1.0, 0.88)));
	float head_angle = secondary.z + attention * 0.035 + pose.y * 0.10;
	vec2 head_pivot = vec2(0.0, -0.20);
	p = rotate_about(p, head_pivot, head_angle * head);
	float head_yaw = clamp(attention * 0.075, -0.075, 0.075) * head;
	p.x = head_pivot.x + (p.x - head_pivot.x) * (1.0 - head_yaw);

	float torso_lean = secondary.w + pose.z;
	p = rotate_about(p, vec2(0.0, 0.12), torso_lean * torso);
	p.y += breath * strength * 0.0022 * torso;

	// Each arm turns at the shoulder, bends at its own elbow and lets the wrist settle
	// last. Smooth bone masks keep the painted joins intact without detached cutouts.
	p = rotate_about(p, near_shoulder - vec2(0.5), (limbs.x + pose.x * 0.18) * near_upper * life);
	p = rotate_about(p, near_elbow - vec2(0.5), limbs.y * near_forearm * life);
	p = rotate_about(p, near_wrist - vec2(0.5), limbs.z * near_hand * life);
	p = rotate_about(p, far_shoulder - vec2(0.5), limbs.w * far_upper * life);
	p = rotate_about(p, far_elbow - vec2(0.5), secondary.x * far_forearm * life);
	p = rotate_about(p, far_wrist - vec2(0.5), secondary.y * far_hand * life);

	// Hair, cape and skirt use their own delayed currents, kept subtle at the actual
	// tutorial scale. Sarah's body remains unobstructed by decorative effects.
	float hair_left = (1.0 - smoothstep(0.13, 0.30, uv.x)) * (1.0 - smoothstep(0.37, 0.53, uv.y));
	float hair_right = smoothstep(0.69, 0.86, uv.x) * (1.0 - smoothstep(0.28, 0.47, uv.y));
	float hair = max(hair_left, hair_right);
	p.x += strength * sin(clock * 1.55 - uv.y * 7.0) * 0.0065 * hair;
	float fabric = smoothstep(0.48, 0.68, uv.y);
	float fabric_amp = is_queen ? 0.010 : 0.008;
	p.x += strength * (sin(clock * 1.4 - uv.y * 6.0) * fabric_amp + sin(clock * 2.3 - uv.y * 9.0) * 0.002) * fabric;
	p.y += strength * sin(clock * 1.7 - uv.x * 5.0) * 0.003 * fabric * abs(uv.x - 0.5) * 2.0;

	// Daddy's sandals and Antonella's visible foot receive a restrained travelling
	// kick while swimming. It fades away in quiet dialogue and gentle motion.
	float stride = sin(clock * 2.6 + (is_queen ? 0.8 : 0.0)) * (0.012 + travel.y * 0.028);
	float lower_body = smoothstep(0.70, 0.82, uv.y);
	float left_leg = 1.0 - smoothstep(0.06, 0.13, abs(uv.x - 0.37));
	float right_leg = 1.0 - smoothstep(0.06, 0.13, abs(uv.x - 0.64));
	if (is_queen) {
		p.x += sin(clock * 1.6 - uv.y * 5.0) * 0.003 * lower_body * fabric;
	} else {
		p = rotate_about(p, vec2(-0.12, 0.28), stride * left_leg * lower_body * life);
		p = rotate_about(p, vec2(0.13, 0.28), -stride * right_leg * lower_body * life);
	}
	p.x += travel.x * 0.006 * life * smoothstep(0.24, 0.75, uv.y);

	VERTEX = p;
}

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
