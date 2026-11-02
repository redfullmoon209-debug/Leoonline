shader_type canvas_item;
render_mode unshaded;

// Premium crimson depth for EXISTING flat panels only.
// No borders, line art, frames, ornaments, or input-handling nodes.
uniform vec4 upper_tint : source_color = vec4(0.18, 0.035, 0.072, 0.94);
uniform vec4 lower_tint : source_color = vec4(0.073, 0.014, 0.035, 0.96);
uniform vec4 flare_tint : source_color = vec4(0.94, 0.12, 0.14, 1.0);
uniform float warmth : hint_range(0.0, 2.0) = 1.0;

void fragment() {
 vec2 uv = UV;
 float vertical = smoothstep(0.0, 1.0, uv.y);
 vec3 base = mix(upper_tint.rgb, lower_tint.rgb, vertical);
 // Diffuse ambient illumination—not a stroke or border.
 vec2 north_glow = (uv - vec2(0.18, 0.04)) * vec2(1.8, 2.5);
 vec2 south_glow = (uv - vec2(0.79, 0.85)) * vec2(1.7, 2.2);
 float glow_a = exp(-dot(north_glow, north_glow) * 2.7);
 float glow_b = exp(-dot(south_glow, south_glow) * 3.5);
 float volume = glow_a * 0.15 + glow_b * 0.06;
 float center_lift = 1.0 - 0.09 * distance(uv, vec2(0.5, 0.46));
 vec3 rgb = clamp((base + flare_tint.rgb * volume * warmth) * center_lift, vec3(0.0), vec3(1.0));
 float alpha = mix(upper_tint.a, lower_tint.a, vertical);
 COLOR = vec4(rgb, alpha);
}
