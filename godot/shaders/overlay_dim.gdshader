shader_type canvas_item;
render_mode unshaded;
// HTML #settings / #pausescreen backdrop: blur then a veil (radial on settings, flat on pause).
// Needs a BackBufferCopy earlier in the same viewport (Compatibility SCREEN_TEXTURE).
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
	vec2 px2 = px * 2.0;
	vec2 px15 = px * 1.5;
	// Weighted gaussian-ish — CSS blur(3px)/blur(4px)
	vec4 blur = texture(screen_texture, uv) * 0.16;
	blur += texture(screen_texture, uv + vec2(px.x, 0.0)) * 0.09;
	blur += texture(screen_texture, uv - vec2(px.x, 0.0)) * 0.09;
	blur += texture(screen_texture, uv + vec2(0.0, px.y)) * 0.09;
	blur += texture(screen_texture, uv - vec2(0.0, px.y)) * 0.09;
	blur += texture(screen_texture, uv + px) * 0.06;
	blur += texture(screen_texture, uv - px) * 0.06;
	blur += texture(screen_texture, uv + vec2(px.x, -px.y)) * 0.06;
	blur += texture(screen_texture, uv + vec2(-px.x, px.y)) * 0.06;
	blur += texture(screen_texture, uv + vec2(px15.x, 0.0)) * 0.04;
	blur += texture(screen_texture, uv - vec2(px15.x, 0.0)) * 0.04;
	blur += texture(screen_texture, uv + vec2(0.0, px15.y)) * 0.04;
	blur += texture(screen_texture, uv - vec2(0.0, px15.y)) * 0.04;
	blur += texture(screen_texture, uv + vec2(px2.x, 0.0)) * 0.02;
	blur += texture(screen_texture, uv - vec2(px2.x, 0.0)) * 0.02;
	blur += texture(screen_texture, uv + vec2(0.0, px2.y)) * 0.02;
	blur += texture(screen_texture, uv - vec2(0.0, px2.y)) * 0.02;

	vec4 veil = inner;
	if (radial > 0.5) {
		vec2 d = (uv - center) / radius;
		float t = clamp(length(d), 0.0, 1.0);
		veil = mix(inner, outer, t * t);
	}
	COLOR = vec4(mix(blur.rgb, veil.rgb, veil.a), 1.0);
}
