#version 100
precision highp float;

varying float iTime;
uniform vec2 iResolution;

#define MAX_PALETTE_COLORS 4

// i defined this color for representing undesirable state for a pixel,
// just like unity does when a shader doesn't compile
#define ERROR_COLOR vec3(1.0, 0.0, 0.0)



struct NoiseParams {
    float amplitude, amplitudeModifier;
    float freq, freqModifier;
    int layers;
    float zOffsetSpeed;
};

vec3 rnd3D(vec3 uvw) {
    uvw = vec3(
        dot(uvw, vec3(127.1,311.7, 513.7)),
        dot(uvw, vec3(269.5,183.3, 396.5)),
        dot(uvw, vec3(421.3,314.1, 119.7))
    );
    
    return -1.0 + 2.0 * fract(sin(uvw) * 43758.5453123);
}

float noise3D(vec3 uvw, float frequency){
    vec2 v = vec2(1.0, 0.0);
    vec3 idx = floor(uvw * frequency); 
    vec3 offset = fract(uvw * frequency);
    vec3 blur = smoothstep(0.0, 1.0, offset);

    return mix(
        mix(
            mix(
                dot(rnd3D(idx + v.yyy), offset - v.yyy),
                dot(rnd3D(idx + v.xyy), offset - v.xyy),
                blur.x
            ),
            mix(
                dot(rnd3D(idx + v.yxy), offset - v.yxy),
                dot(rnd3D(idx + v.xxy), offset - v.xxy),
                blur.x
            ),
            blur.y
        ),
        mix(
            mix(
                dot(rnd3D(idx + v.yyx), offset - v.yyx),
                dot(rnd3D(idx + v.xyx), offset - v.xyx),
                blur.x
            ),
            mix(
                dot(rnd3D(idx + v.yxx), offset - v.yxx),
                dot(rnd3D(idx + v.xxx), offset - v.xxx),
                blur.x
            ),
            blur.y
        ),
        blur.z
    ) + 0.5;
}

float fbm(vec3 p, NoiseParams params) {
    float total = 0.0;
    
    for (int i = 0; i < params.layers; i++) {
        total += params.amplitude * noise3D(p, params.freq);
        params.amplitude *= params.amplitudeModifier;
        params.freq *= params.freqModifier;
    }
    
    return total;
}



struct Params {
    NoiseParams noise;
    float rotSpeed;

    // x,y,z stands for the r,g,b values
    // w represents the threshold to be applied
    vec4 colors[MAX_PALETTE_COLORS];
};

mat3 rotX(float angle) {
    return mat3(
         cos(angle),   0.0,   sin(angle),
            0.0    ,   1.0,      0.0    ,
        -sin(angle),   0.0,   cos(angle)
    );
}

vec3 sampleColor(vec2 uv, Params params) {
    float r = length(uv);

    if (r > 0.5) {
        return vec3(0.0);
    }

    vec3 sphereCoords = vec3(uv, sqrt(0.5 * 0.5 - r * r));
    vec3 rotated = rotX(iTime * params.rotSpeed) * sphereCoords;
    float noise = fbm(rotated + params.noise.zOffsetSpeed * vec3(iTime, 0.0, 0.0), params.noise);

    for (int i = 0; i < MAX_PALETTE_COLORS; i++) {
        vec4 color = params.colors[i];
        if (color.w >= noise) {
            return color.xyz;
        }
    }

    return ERROR_COLOR;
}

// the center of the screen corresponds to the (0.0, 0.0)
// if the window is horizontal the distance from top to bot will be 1.0 units
// if the window is vertical the distance from left to right will be 1.0 units
// the other dimension will be proportional to the ratio of the screen

vec2 computeUV() {
    if (iResolution.x > iResolution.y) {
        vec2 uv = gl_FragCoord.xy / iResolution.y;
        float ratio = iResolution.x / iResolution.y;
        return uv - vec2(ratio / 2.0, 0.5);
    }
    
    vec2 uv = gl_FragCoord.xy / iResolution.x;
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

    gl_FragColor = max(vec4(color, 1.0), vec4(0.07, 0.07, 0.07, 1.0));
}
