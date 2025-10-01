mat3 _rotX(float angle) {
    return mat3(
         cos(angle),   0.0,   sin(angle),
            0.0    ,   1.0,      0.0    ,
        -sin(angle),   0.0,   cos(angle)
    );
}

vec3 rotate(vec3 v, float amount) {
    return _rotX(amount) * v;
}
