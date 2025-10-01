float quantization(float x, float maxValue, float levels) {
    x /= maxValue;
    x *= levels;
    x = ceil(x);
    x /= levels;
    x *= maxValue;
    return x;
}
