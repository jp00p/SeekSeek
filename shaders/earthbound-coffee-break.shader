shader_type canvas_item;

// POORLY converted from https://www.shadertoy.com/view/WlScWh
// --------------------------------------------------------------------
// Cellular noise ("Worley noise") in 3D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.

// Permutation polynomial: (34x^2 + x) mod 289
vec4 permute4(vec4 x) {
  return mod((34.0 * x + 1.0) * x, 289.0);
}
vec3 permute3(vec3 x) {
  return mod((34.0 * x + 1.0) * x, 289.0);
}

// Cellular noise, returning F1 and F2 in a vec2.
// Speeded up by using 2x2x2 search window instead of 3x3x3,
// at the expense of some pattern artifacts.
// F2 is often wrong and has sharp discontinuities.
// If you need a good F2, use the slower 3x3x3 version.
vec2 cellular2x2x2(vec3 P) {
	float K = 0.142857142857; // 1/7
	float Ko = 0.428571428571; // 1/2-K/2
	float K2 = 0.020408163265306; // 1/(7*7)
	float Kz = 0.166666666667; // 1/6
	float Kzo = 0.416666666667; // 1/2-1/6*2
	float jitter = 0.8; // smaller jitter gives less errors in F2
	vec3 Pi = mod(floor(P), 289.0);
 	vec3 Pf = fract(P);
	vec4 Pfx = Pf.x + vec4(0.0, -1.0, 0.0, -1.0);
	vec4 Pfy = Pf.y + vec4(0.0, 0.0, -1.0, -1.0);
	vec4 p = permute4(Pi.x + vec4(0.0, 1.0, 0.0, 1.0));
	p = permute4(p + Pi.y + vec4(0.0, 0.0, 1.0, 1.0));
	vec4 p1 = permute4(p + Pi.z); // z+0
	vec4 p2 = permute4(p + Pi.z + vec4(1.0)); // z+1
	vec4 ox1 = fract(p1*K) - Ko;
	vec4 oy1 = mod(floor(p1*K), 7.0)*K - Ko;
	vec4 oz1 = floor(p1*K2)*Kz - Kzo; // p1 < 289 guaranteed
	vec4 ox2 = fract(p2*K) - Ko;
	vec4 oy2 = mod(floor(p2*K), 7.0)*K - Ko;
	vec4 oz2 = floor(p2*K2)*Kz - Kzo;
	vec4 dx1 = Pfx + jitter*ox1;
	vec4 dy1 = Pfy + jitter*oy1;
	vec4 dz1 = Pf.z + jitter*oz1;
	vec4 dx2 = Pfx + jitter*ox2;
	vec4 dy2 = Pfy + jitter*oy2;
	vec4 dz2 = Pf.z - 1.0 + jitter*oz2;
	vec4 d1 = dx1 * dx1 + dy1 * dy1 + dz1 * dz1; // z+0
	vec4 d2 = dx2 * dx2 + dy2 * dy2 + dz2 * dz2; // z+1

	// Do it right and sort out both F1 and F2
	vec4 d = min(d1,d2); // F1 is now in d
	d2 = max(d1,d2); // Make sure we keep all candidates for F2
	d.xy = (d.x < d.y) ? d.xy : d.yx; // Swap smallest to d.x
	d.xz = (d.x < d.z) ? d.xz : d.zx;
	d.xw = (d.x < d.w) ? d.xw : d.wx; // F1 is now in d.x
	d.yzw = min(d.yzw, d2.yzw); // F2 now not in d2.yzw
	d.y = min(d.y, d.z); // nor in d.z
	d.y = min(d.y, d.w); // nor in d.w
	d.y = min(d.y, d2.x); // F2 is now in d.y
	return sqrt(d.xy); // F1 and F2

}

// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}

// Copyright (c) 2020 Maki. All rights reserved.

// precision mediump float;

vec2 wobbly(vec2 uv, float speed, float repetition, float amount, float offset, float time) {
    return vec2(
        uv.x,
        uv.y + sin(uv.y * repetition + (time+offset) * speed) / amount
    );
}

float bubbles(vec2 uv, float offset, float direction, float time) {
	float zoom = 6.0;

    uv*=zoom;

    uv = wobbly(uv, 0.8, 0.17*zoom, 0.2*zoom, offset, time);
    uv.x -= time * 0.3 * direction;
    uv.y -= time * 0.8;

	vec2 F = cellular2x2x2(
		vec3(
			uv,
			(time + offset) * 0.2
		)
	);

	float maxSs = 0.33;
	float minSs = maxSs - 0.0001;

	float _size = 0.0;
	float ringVisibleWidth = 0.02;
	float ringInvisibleWidth = 0.045;

	float final = 1.0 - smoothstep(minSs, maxSs, F.x);

	_size += ringVisibleWidth;
	final -= 1.0 - smoothstep(minSs-_size, maxSs-_size, F.x);
	
	for (int i=0; i<3; i++) {
		_size += ringInvisibleWidth;
		final += 1.0 - smoothstep(minSs-_size, maxSs-_size, F.x);

		_size += ringVisibleWidth;
		final -= 1.0 - smoothstep(minSs-_size, maxSs-_size, F.x);
	}

	return clamp(final, 0.0, 1.0);
}

vec2 pixelateUV(vec2 uv, float amount) {
	return floor(uv * amount) / amount;
}

const vec3 colorBg = vec3(1.0, 47.0, 113.0) / 255.0;
const vec3 colorBlue = vec3(8.0, 48.0, 170.0)/255.0;
const vec3 colorGreen = vec3(2.0, 87.0, 53.0)/255.0;

void fragment() {
	vec2 iResolution = 1.0/SCREEN_PIXEL_SIZE;
    vec2 uv = FRAGCOORD.xy/iResolution.xy;
	uv = pixelateUV(UV, 200.0);

    float blueBubbles = bubbles(uv, 11512.11, 1.0, TIME);
	float blueOpacity = smoothstep(0.2, 0.6, noise((TIME + 11512.11) * 1.0));
	float blueCombined = clamp(blueBubbles * blueOpacity, 0.0, 1.0);
	
    float greenBubbles = bubbles(uv, 82351.93, -1.0, TIME);
	float greenOpacity = smoothstep(0.2, 0.6, noise((TIME + 82351.93) * 1.0));
	float greenCombined = clamp(greenBubbles * greenOpacity, 0.0, 1.0);
	
	vec3 color = mix(
		mix(
			colorBg, // a
			colorBlue, // b
			blueCombined // alpha
		), // a
		colorGreen, // b
		greenCombined // alpha
	);

	COLOR = vec4(vec3(color), 1.0);
}