shader_type canvas_item;
// HTML #settings / #pausescreen backdrop: blur then a veil (radial on settings, flat on pause).
uniform vec4 inner : source_color = vec4(0.118, 0.094, 0.212, 0.94);
uniform vec4 outer : source_color = vec4(0.024, 0.016, 0.047, 0.97);
uniform vec2 center = vec2(0.5, 0.40);
uniform vec2 radius = vec2(0.73, 0.96);
uniform float radial = 1.0;
uniform float blur_px = 4.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE * blur_px;
	vec4 blur = texture(screen_texture, uv);
	blur += texture(screen_texture, uv + vec2(px.x, 0.0));
	blur += texture(screen_texture, uv - vec2(px.x, 0.0));
	blur += texture(screen_texture, uv + vec2(0.0, px.y));
	blur += texture(screen_texture, uv - vec2(0.0, px.y));
	blur += texture(screen_texture, uv + px);
	blur += texture(screen_texture, uv - px);
	blur += texture(screen_texture, uv + vec2(px.x, -px.y));
	blur += texture(screen_texture, uv + vec2(-px.x, px.y));
	blur *= 0.111111;

	vec4 veil = inner;
	if (radial > 0.5) {
		vec2 d = (uv - center) / radius;
		float t = clamp(length(d), 0.0, 1.0);
		veil = mix(inner, outer, t * t);
	}
	COLOR = vec4(mix(blur.rgb, veil.rgb, veil.a), 1.0);
}
