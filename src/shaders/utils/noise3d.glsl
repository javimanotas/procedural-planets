struct NoiseParams {
    float amplitude, amplitudeModifier;
    float freq, freqModifier;
    int layers;
    float zOffsetSpeed;
};

vec3 _rnd3D(vec3 uvw) {
    uvw = vec3(
        dot(uvw, vec3(127.1,311.7, 513.7)),
        dot(uvw, vec3(269.5,183.3, 396.5)),
        dot(uvw, vec3(421.3,314.1, 119.7))
    );
    
    return -1.0 + 2.0 * fract(sin(uvw) * 43758.5453123);
}

float _noise(vec3 uvw, float frequency){
    vec2 v = vec2(1.0, 0.0);
    vec3 idx = floor(uvw * frequency); 
    vec3 offset = fract(uvw * frequency);
    vec3 blur = smoothstep(0.0, 1.0, offset);

    return mix(
        mix(
            mix(
                dot(_rnd3D(idx + v.yyy), offset - v.yyy),
                dot(_rnd3D(idx + v.xyy), offset - v.xyy),
                blur.x
            ),
            mix(
                dot(_rnd3D(idx + v.yxy), offset - v.yxy),
                dot(_rnd3D(idx + v.xxy), offset - v.xxy),
                blur.x
            ),
            blur.y
        ),
        mix(
            mix(
                dot(_rnd3D(idx + v.yyx), offset - v.yyx),
                dot(_rnd3D(idx + v.xyx), offset - v.xyx),
                blur.x
            ),
            mix(
                dot(_rnd3D(idx + v.yxx), offset - v.yxx),
                dot(_rnd3D(idx + v.xxx), offset - v.xxx),
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
        total += params.amplitude * _noise(p, params.freq);
        params.amplitude *= params.amplitudeModifier;
        params.freq *= params.freqModifier;
    }
    
    return total;
}
