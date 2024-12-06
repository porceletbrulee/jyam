// loosely based on https://godotshaders.com/shader/animated-stripes/ (which has a CC0 license)
shader_type canvas_item;

uniform vec4 CHEVRON_COLOR: source_color  = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 BACKGROUND_COLOR: source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float SPEED = 0.3;
uniform float THICKNESS = 0.1;
uniform float HEIGHT = 0.05; // distance from base to inner point of chevron
uniform float GAP = 0.05; // gap between chevrons
// TODO: can undo the make unique and do use "Local to resource" once
// "instance uniform ..." is supported:
// https://github.com/godotengine/godot/issues/62943
// WARNING: parameters behave strangely with saved materials, if the scene
// becomes a child of another scene, and other cases.
uniform bool ALONG_POSITIVE_AXIS = true;
uniform bool ALONG_X_AXIS = true;

void fragment() {
	vec2 rotated_uv = ALONG_X_AXIS ? UV : vec2(UV.y, UV.x);
	float adjust_y = rotated_uv.y > 0.5 ? 1.0 - rotated_uv.y : rotated_uv.y;
	
	// if calculating pixels, both pixel size and the angle cancel out
	// leg_angle is imagine an isosceles triangle pointing right, it would be the
	// top and bottom angle. we're calculating the similar triangle with sides
	// y=0.5 and height (side-angle-side) and the one with the current UV.y
	// value
	// max_pixels_y = TEXTURE_PIXEL_SIZE.x * height / tan(leg_angle);
	// pixels_y = 2.0 * adjust_y * max_pixels_y
	// pixels_x = pixels_y * tan(leg_angle)
	// scaled_x = pixels_x / TEXTURE_PIXEL_SIZE.x
	float left_x = 2.0 * adjust_y * HEIGHT;
	float right_x = left_x + THICKNESS;
	float adjust_x = ALONG_POSITIVE_AXIS ? rotated_uv.x : 1.0 - rotated_uv.x;
	
	float chunk = HEIGHT + THICKNESS + GAP;
	// can compiler remove this code when speed is 0?
	// TODO: when using fract, there's a weird choppiness, not sure from what
	adjust_x = (SPEED == 0.0) ? adjust_x : adjust_x - mod(TIME * SPEED, chunk);
	adjust_x = mod(adjust_x, chunk);
	
	// is this actually better than branch??
	COLOR = mix(BACKGROUND_COLOR, CHEVRON_COLOR,
				step(left_x, adjust_x) - step(right_x, adjust_x));
	//COLOR = rotated_uv.x > adjust_x ? CHEVRON_COLOR : BACKGROUND_COLOR;
	//if (step(left_x, adjust_x) == step(right_x, adjust_x)) {
		//COLOR = BACKGROUND_COLOR;
	//} else {
		//COLOR = CHEVRON_COLOR;
	//}
}
