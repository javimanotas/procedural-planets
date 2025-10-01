use std::path::Path;
use macroquad::prelude::*;
mod shader;

#[macroquad::main("Planets")]
async fn main() {
    let vertex = shader::preprocess(Path::new("src/shaders/vertex.glsl"))
        .unwrap_or_else(|err| panic!("Error loading vertex shader, {err}"));
    
    let fragment = shader::preprocess(Path::new("src/shaders/planets.glsl"))
        .unwrap_or_else(|err| panic!("Error loading vertex shader, {err}"));

    let material = load_material(
        ShaderSource::Glsl {
            vertex: &vertex,
            fragment: &fragment,
        },
        MaterialParams {
            uniforms: vec![
                UniformDesc::new("iResolution", UniformType::Float2),
            ],
            ..Default::default()
        },
    ).unwrap_or_else(|err| panic!("Error compiling shaders: {err}"));

    loop {
        material.set_uniform("iResolution", (screen_width(), screen_height()));
        gl_use_material(&material);
        draw_rectangle(0., 0., screen_width(), screen_height(), WHITE);
        next_frame().await
    }
}
