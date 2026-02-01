#version 330 compatibility

attribute vec4 mc_Entity;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform int worldTime;

in vec4 at_midBlock;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

void main() {

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;

    /*        WAVING LEAVES          */
    bool isLeaves = (mc_Entity.x == 10001.0);
	bool isGrass  = (mc_Entity.x == 10002.0);

	if (isLeaves || isGrass) {

		vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos.xyz, 1.0)).xyz;
		worldPos += cameraPosition;

		float dist = length(worldPos - cameraPosition);
		float fade = clamp(1.0 - dist / (isLeaves ? 64.0 : 48.0), 0.0, 1.0);

		float phase =
			worldPos.x * 0.6 +
			worldPos.z * 0.6 +
			frameTimeCounter * (isLeaves ? 0.9 : 1.2);

		vec3 offset = vec3(0.0);

		if (isLeaves) {
			offset.x = sin(phase) * 0.12;
			offset.z = cos(phase * 0.7) * 0.07;
			offset.y = sin(phase * 0.5) * 0.02;
		}

		if (isGrass) {
			// vec3 center = worldPos.xyz + at_midBlock.xyz /64.0;                     
			float bladePos = gl_MultiTexCoord0.y;
			float bend = pow(bladePos, 3.0);
			offset.x = sin(phase) * 0.18 * bend;
			offset.z = cos(phase) * 0.11 * bend;
			offset.y = sin(phase * 0.9) * 0.02 * bend;
		}
		worldPos += offset * fade;
		viewPos = gbufferModelView * vec4(worldPos - cameraPosition, 1.0);
	}

    // Final position
    gl_Position = gl_ProjectionMatrix * viewPos;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
}