shader_type canvas_item;
render_mode unshaded;

uniform float temperatureRange : hint_range(-1.0, 1.0);
uniform vec4 hotColor : hint_color;
uniform vec4 coldColor : hint_color;

uniform float heatAmplitude : hint_range(0.0, 0.15);
uniform float heatPeriod;
uniform float heatPhaseShift;
uniform float heatUpperLimit : hint_range(0.5, 10.0);

uniform sampler2D coldNormal : hint_normal;
uniform float coldFXStrength : hint_range(0.0, 1.0);

void fragment() {
	float currentHot = clamp(temperatureRange, 0.0, 1.0);
	float currentCold = -clamp(temperatureRange, -1.0, 0.0);
	vec4 hotnessColor = (hotColor * currentHot);
	vec4 coldnessColor = (coldColor * currentCold);
	float effectStrength = coldFXStrength * currentCold;
	vec2 modifiedUVHot = SCREEN_UV;
	vec2 modifiedUVCold = SCREEN_UV;
	
	modifiedUVHot.x -= (((1.0 - modifiedUVHot.y) * heatAmplitude) *
		sin(heatPeriod * (modifiedUVHot.y - (TIME * 0.016  * heatPhaseShift)))) *
		clamp(1.0 - (modifiedUVHot.y * (10.0 - heatUpperLimit)), 0.0, 0.5) *
		currentHot;
	
	modifiedUVCold += (texture(coldNormal, UV).xy * effectStrength) - effectStrength * 0.5;
	
	COLOR = texture(SCREEN_TEXTURE, (modifiedUVHot + modifiedUVCold) * 0.5);
	COLOR.rgb += hotnessColor.rgb * hotnessColor.a;
	COLOR.rgb += coldnessColor.rgb * coldnessColor.a; 
}