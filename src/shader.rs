use std::{fs, fmt, path::Path};

#[derive(Debug)]
pub enum PreprocessError {
    Io(std::io::Error),
    InvalidIncludeSyntax(String),
    IncludeNotFound(String),
}

impl fmt::Display for PreprocessError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PreprocessError::Io(err) =>
                write!(f, "I/O error: {err}"),
            PreprocessError::InvalidIncludeSyntax(line) => 
                write!(f, "Invalid include directive: {line}"),
            PreprocessError::IncludeNotFound(path) =>
                write!(f, "Included file not found: {path}"),
        }
    }
}

impl From<std::io::Error> for PreprocessError {
    fn from(err: std::io::Error) -> Self {
        PreprocessError::Io(err)
    }
}

/* GLSL does not support `#include` directives by default so i addded this
   pre-processing step that replaces `#include "shader"` with the contents
   of the referenced shader file, resolved relative to the current shader’s directory. */

pub fn preprocess(path: &Path) -> Result<String, PreprocessError> {
    let mut output = String::new();

    for line in fs::read_to_string(path)?.lines() {
        let line = line.trim();
        if !line.starts_with("#insert") {
            output.push_str(line);
            output.push('\n');
            continue;
        }

        if let Some(start) = line.find('"') {
            if let Some(end) = line[start + 1..].find('"') {
                let include_path = &line[start + 1..start + 1 + end];

                let full_path = path
                    .parent()
                    .unwrap_or_else(|| Path::new("."))
                    .join(include_path);

                if !full_path.exists() {
                    return Err(PreprocessError::IncludeNotFound(include_path.to_string()));
                }

                let included = preprocess(&full_path)?;
                output.push_str(&included);
                output.push('\n');
                continue;
            }
        }
        return Err(PreprocessError::InvalidIncludeSyntax(line.to_string()));
    }
    Ok(output)
}
