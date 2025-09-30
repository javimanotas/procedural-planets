use macroquad::prelude::*;

const FRAGMENT_SHADER: &str = include_str!("shaders/fragment.glsl");
const VERTEX_SHADER:   &str = include_str!("shaders/vertex.glsl");

#[macroquad::main("Shader")]
async fn main() {

    let material = load_material(
        ShaderSource::Glsl {
            vertex: VERTEX_SHADER,
            fragment: FRAGMENT_SHADER,
        },
        MaterialParams {
            uniforms: vec![
                UniformDesc::new("iResolution", UniformType::Float2),
            ],
            ..Default::default()
        },
    ).unwrap();

    loop {

        material.set_uniform("iResolution", (screen_width(), screen_height()));
        gl_use_material(&material);
        
        let params = DrawTextureParams {
            dest_size: Some(vec2(screen_width(), screen_height())),
            ..Default::default()
        };

        let tex = render_target(1, 1).texture;
        draw_texture_ex(&tex, 0., 0., WHITE, params);

        next_frame().await
    }
}
