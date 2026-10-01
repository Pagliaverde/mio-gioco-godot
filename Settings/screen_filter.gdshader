// Filtro sopra a tutto il gioco: luminosita', contrasto, saturazione e
// correzione dei colori per daltonici (daltonizzazione di Fidaner et al.).
// Lo usa Settings: e' acceso solo quando almeno un valore non e' quello neutro.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;
// 0 nessuno, 1 protanopia, 2 deuteranopia, 3 tritanopia
uniform int colorblind_mode = 0;

vec3 to_lms(vec3 c) {
	return vec3(
		dot(c, vec3(17.8824, 43.5161, 4.11935)),
		dot(c, vec3(3.45565, 27.1554, 3.86714)),
		dot(c, vec3(0.0299566, 0.184309, 1.46709))
	);
}

vec3 to_rgb(vec3 lms) {
	return vec3(
		dot(lms, vec3(0.0809444479, -0.130504409, 0.116721066)),
		dot(lms, vec3(-0.0102485335, 0.0540193266, -0.113614708)),
		dot(lms, vec3(-0.000365296938, -0.00412161469, 0.693511405))
	);
}

// Sposta l'informazione che il daltonico non vede su canali che vede.
vec3 daltonize(vec3 c, int mode) {
	vec3 lms = to_lms(c);
	vec3 sim = lms;
	if (mode == 1) {
		sim.x = 2.02344 * lms.y - 2.52581 * lms.z;
	} else if (mode == 2) {
		sim.y = 0.494207 * lms.x + 1.24827 * lms.z;
	} else {
		sim.z = -0.395913 * lms.x + 0.801109 * lms.y;
	}
	vec3 err = c - to_rgb(sim);
	vec3 shift = vec3(0.0, 0.7 * err.r + err.g, 0.7 * err.r + err.b);
	return c + shift;
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c = (c - 0.5) * contrast + 0.5;
	c *= brightness;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	if (colorblind_mode > 0) {
		c = daltonize(clamp(c, 0.0, 1.0), colorblind_mode);
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
