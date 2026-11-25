shader_type canvas_item;
uniform bool slash_only = false;
uniform bool crimson = false;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float aqua = smoothstep(0.04, 0.14, min(ink.g, ink.b) - ink.r);
	float light = max(ink.b, ink.g);
	vec3 red = vec3(light, light * light * 0.23, light * 0.22);
	COLOR = tint * vec4(mix(ink.rgb, red, crimson ? aqua : 0.0), ink.a * (slash_only ? aqua : 1.0));
}
