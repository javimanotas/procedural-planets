#version 100
precision highp float;

varying float iTime;
uniform vec2 iResolution;

#include "utils/noise3d.glsl"
#include "utils/transform.glsl"

#define MAX_PALETTE_COLORS 4
#define ERROR_COLOR vec3(1.0, 0.0, 0.0)



struct Params {
    NoiseParams noise;
    float rotSpeed;

    /* x,y,z stands for the r,g,b values
       w represents the threshold to be applied */
    vec4 colors[MAX_PALETTE_COLORS];
};

float quantization(float x, float amount) {
    return floor(x / amount) * amount;
}

vec3 sampleColor(vec2 uv, Params params) {
    float r = length(uv);

    if (r > 0.5) {
        return vec3(0.0);
    }

    vec3 sphereCoords = vec3(uv, sqrt(0.5 * 0.5 - r * r));
    vec3 rotated = rotate(sphereCoords, iTime * params.rotSpeed);
    float noise = fbm(rotated + params.noise.zOffsetSpeed * vec3(iTime, 0.0, 0.0), params.noise);

    vec3 color = ERROR_COLOR;
    for (int i = 0; i < MAX_PALETTE_COLORS; i++) {
        if (params.colors[i].w >= noise) {
            color = params.colors[i].xyz;
            break;
        }
    }

    vec3 lightDir = vec3(0.6, 0.0, 1.0);


    float brightness = max(0.0, dot(normalize(lightDir), normalize(sphereCoords)));



    color *= quantization(brightness * 100.0, 10.0) / 100.0;

    return color;
}

/* the center of the screen corresponds to the (0.0, 0.0)
   if the window is horizontal the distance from top to bot will be 1.0 units
   if the window is vertical the distance from left to right will be 1.0 units
   the other dimension will be proportional to the ratio of the screen */

vec2 computeUV() {
    vec2 pixel = gl_FragCoord.xy;

    pixel.x = quantization(pixel.x, 6.0);
    pixel.y = quantization(pixel.y, 6.0);


    if (iResolution.x > iResolution.y) {
        vec2 uv = pixel / iResolution.y;
        float ratio = iResolution.x / iResolution.y;
        return uv - vec2(ratio / 2.0, 0.5);
    }
    
    vec2 uv = pixel / iResolution.x;
    float ratio = iResolution.y / iResolution.x;
    return uv - vec2(0.5, ratio / 2.0);
}

void main() {
    vec2 uv = computeUV();

    vec4 earthColors[MAX_PALETTE_COLORS];
    earthColors[0] = vec4(0.42, 0.57, 0.84, 0.5);
    earthColors[1] = vec4(0.85, 0.77, 0.59, 0.55);
    earthColors[2] = vec4(0.62, 0.76, 0.39, 1.0);
    Params earthParams = Params(NoiseParams(0.5, 0.6, 2.0, 2.0, 5, 0.0), 0.15, earthColors);

    vec4 cloudColors[MAX_PALETTE_COLORS];
    cloudColors[0] = vec4(0.0, 0.0, 0.0, 0.7);
    cloudColors[1] = vec4(1.0, 1.0, 1.0, 1.0);
    Params cloudParams = Params(NoiseParams(0.5, 0.6, 2.0, 2.0, 5, 0.02), 0.24, cloudColors);

    vec3 color = sampleColor(uv, cloudParams);
    if (color == vec3(0.0, 0.0, 0.0)) {
        color = sampleColor(uv * 1.1, earthParams);
    }

    gl_FragColor = max(vec4(color, 1.0), vec4(0.00, 0.00, 0.00, 1.0));
}
