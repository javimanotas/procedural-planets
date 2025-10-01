#version 100
precision highp float;

varying float iTime;
uniform vec2 iResolution;

#insert "utils/noise3d.glsl"
#insert "utils/transform.glsl"
#insert "utils/random.glsl"
#insert "utils/quantization.glsl"

#define MAX_PALETTE_COLORS 5
#define ERROR_COLOR vec3(1.0, 0.0, 0.0)

struct Params {
    NoiseParams noise;
    float rotSpeed;

    /* x,y,z stands for the r,g,b values
       w represents the threshold to be applied */
    vec4 colors[MAX_PALETTE_COLORS];
};

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
    return color * quantization(brightness, 1.0, 10.0);
}

vec3 atmosphere(vec2 uv, vec3 color) {
    float r = length(uv);
    vec3 sphereCoords = vec3(uv, sqrt(0.5 * 0.5 - r * r));
   
    float rim = pow(1.0 - dot(normalize(sphereCoords), vec3(0.0, 0.0, 1.0)), 4.0);
    color *= rim;
    vec3 lightDir = vec3(0.6, 0.0, 1.0);
    float brightness = max(0.0, dot(normalize(lightDir), normalize(sphereCoords)));
   
    return clamp(color * quantization(brightness, 1.0, 10.0), 0.0, 1.0);
}

vec3 stars(vec2 uv, float threshold) {
    float rnd = random(uv * 1000.0);
    vec3 tint = vec3(1.0, 1.0, 0.9);
    if (rnd < 0.333) {
        tint = vec3(0.9, 1.0, 1.0);
    }
    else if (rnd < 0.666) {
        tint = vec3(1.0, 0.9, 1.0);
    }

    vec3 star = step(threshold, random(floor(uv * 500.0))) * tint;
    star *= 0.5 + 0.4 * sin(iTime * 2.0 + random(uv) * 6.2831);
    return star;
}

/* the center of the screen corresponds to the (0.0, 0.0)
   if the window is horizontal the distance from top to bot will be 1.0 units
   if the window is vertical the distance from left to right will be 1.0 units
   the other dimension will be proportional to the ratio of the screen */

vec2 computeUV() {
    vec2 pixel = gl_FragCoord.xy;
    vec2 resolution = iResolution.xy;
    if (iResolution.y > iResolution.x) {
        resolution = resolution.yx;
    }

    pixel.x = quantization(pixel.x, resolution.y, 100.0);
    pixel.y = quantization(pixel.y, resolution.y, 100.0);
    vec2 uv = pixel / resolution.y;
    return uv - vec2(iResolution.x / resolution.y / 2.0, iResolution.y / resolution.y / 2.0);
}

void main() {
    vec2 uv = computeUV();

    #insert "templates/earth.glsl"

    vec4 cloudColors[MAX_PALETTE_COLORS];
    cloudColors[0] = vec4(0.0, 0.0, 0.0, 0.7);
    cloudColors[1] = vec4(cloudColor, 1.0);

    Params cloudParams = Params(NoiseParams(0.5, 0.6, 3.0, 2.0, 5, 0.02), 0.26, cloudColors);
    Params earthParams = Params(NoiseParams(0.48, 0.55, 2.5, 2.0, 5, 0.0), 0.15, planetColors);

    vec3 color = sampleColor(uv, cloudParams);
    if (color == vec3(0.0)) {
        color = sampleColor(uv * 1.1, earthParams);
    }
    if (color == vec3(0.0)) {
        color = stars(uv, 0.99);
    }
    color += atmosphere(uv, atmosphereColor);

    gl_FragColor = max(vec4(color, 1.0), vec4(0.00, 0.00, 0.00, 1.0));
}
