shader_type sky;

uniform sampler2D source_panoram: filter_linear, source_color, hint_default_black;
uniform float energy_multiplier;

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	COLOR = texture(source_panoram, SKY_COORDS).rgb * energy_multiplier;
}
