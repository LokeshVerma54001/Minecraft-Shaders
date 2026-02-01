#version 330 compatibility

uniform float frameTimeCounter;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

float CLOUD_FOG = 0.5;
float CLOUD_SPEED = 1.0;
float CLOUD_PERMUTATION_SPEED = 1.0;
uniform float rainStrength;

in vec2 texcoord;

float random(in vec2 p){
    return fract(sin(p.x*456.0 + p.y*56.0)*100.0);
}

vec2 smoothv2(in vec2 v){
    return v*v*(3.0 - 2.0*v);
}

float smooth_noise(in vec2 p){
    vec2 f = smoothv2(fract(p));
    float a = random(floor(p));
    float b = random(vec2(ceil(p.x),floor(p.y)));
    float c = random(vec2(floor(p.x), ceil(p.y)));
    float d = random(ceil(p));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fractal_noise(in vec2 p){
    float total = 0.5;
    float amplitude = 1.0;
    float frequency = 1.0;
    float iterations = 4.0;
    for(float i = 0.0;i<iterations;i++){
        total += (smooth_noise(p*frequency)-0.5)*amplitude;
        amplitude *= 0.5;
        frequency*=2.0;
    }
    return total;
}

vec3 projectanddivide(mat4 pm, vec3 p){
    vec4 hp = pm * vec4(p, 1.0);
    return hp.xyz/hp.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0)out vec4 color;

void main(){
    
    vec3 src = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).r;
    if(depth == 1.0){
        vec4 pos = vec4(texcoord, depth, 1.0)* 2.0 - 1.0;//ndc
        pos.xyz = projectanddivide(gbufferProjectionInverse, pos.xyz); // view pos
        pos = gbufferModelViewInverse * vec4(pos.xyz, 1);
        vec3 raydir = normalize(pos.xyz);
        vec2 uv = raydir.xz * 1.0/raydir.y+ 0.05 * frameTimeCounter*CLOUD_SPEED;
        vec2 uv2 = raydir.xz * 3.0/raydir.y - 0.02 * frameTimeCounter*CLOUD_PERMUTATION_SPEED;
        vec4 clouds;
        if(raydir.y > 0){
            clouds = vec4(fractal_noise(uv) * fractal_noise(uv2));
        }else{
            clouds = vec4(0.0);
        }
        
        float cloud_fog = 1.0 + 1.0/raydir.y;
        
        //to makes holes in cloud density
        clouds.a = clamp((clouds.a - (0.3*(1.0-rainStrength)))*4.0, 0.0, 2.0);
        
        clouds.rgb = vec3(1, 1, 1);
        clouds.rgb*=1.0 -clamp((clouds.a - 0.5)*0.1, 0.0, 0.25);
        src.rgb = mix(src.rgb, clouds.rgb, min(clouds.a, 1.)/ max(1.0, cloud_fog * CLOUD_FOG));
    }
    color = vec4(src, 1.0);
}