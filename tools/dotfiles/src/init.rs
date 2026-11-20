//! `ws init` — scaffold `./.ws.ron` from the managed template.

use std::error::Error;
use std::fs;
use std::path::PathBuf;

const TEMPLATE_RELATIVE_PATH: &str = "dotfiles/ws.ron";
const PLACEHOLDER: &str = "pick-a-name";

pub fn run(name: Option<String>) -> Result<(), Box<dyn Error>> {
    let target = PathBuf::from(".ws.ron");
    if target.exists() {
        return Err(format!("{} already exists — leaving it alone", target.display()).into());
    }

    let template_path = template_path()?;
    let template = fs::read_to_string(&template_path)
        .map_err(|e| format!("reading {}: {e}", template_path.display()))?;

    let session_name = match name {
        Some(name) => name,
        None => current_dir_name()?,
    };
    fs::write(&target, render(&template, &session_name))
        .map_err(|e| format!("writing {}: {e}", target.display()))?;
    println!("wrote {} (session: {session_name})", target.display());
    Ok(())
}

/// `$XDG_CONFIG_HOME/dotfiles/ws.ron`, falling back to `~/.config`.
fn template_path() -> Result<PathBuf, Box<dyn Error>> {
    let config_home = match std::env::var_os("XDG_CONFIG_HOME") {
        Some(home) => PathBuf::from(home),
        None => {
            let home = std::env::var_os("HOME").ok_or("neither XDG_CONFIG_HOME nor HOME is set")?;
            PathBuf::from(home).join(".config")
        }
    };
    Ok(config_home.join(TEMPLATE_RELATIVE_PATH))
}

fn current_dir_name() -> Result<String, Box<dyn Error>> {
    let dir = std::env::current_dir()?;
    dir.file_name()
        .and_then(|name| name.to_str())
        .map(str::to_owned)
        .ok_or_else(|| format!("no directory name in {}", dir.display()).into())
}

fn render(template: &str, session_name: &str) -> String {
    // The derived env key must be a valid shell variable name — fish (like
    // bash) rejects dashes: `oiwn-dotfiles_ENV` breaks every pane's fish
    // startup via foreign-env `set -gx`. So `pick-a-name_ENV` renders as
    // the uppercased, dash-sanitized `<SESSION>_ENV` (theorb -> THEORB_ENV).
    let env_key = env_key_for(session_name);
    template
        .replace(&format!("{PLACEHOLDER}_ENV"), &env_key)
        .replace(PLACEHOLDER, session_name)
}

fn env_key_for(session_name: &str) -> String {
    let sanitized: String = session_name
        .chars()
        .map(|c| match c {
            'a'..='z' => c.to_ascii_uppercase(),
            'A'..='Z' | '0'..='9' | '_' => c,
            _ => '_',
        })
        .collect();
    format!("{sanitized}_ENV")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn render_replaces_session_placeholder() {
        let template = r#"(session: "pick-a-name", environment: {"pick-a-name_ENV": "dev"}, windows: [(name: "a", commands: ["herdr --session pick-a-name"])])"#;
        let rendered = render(template, "myproject");
        assert!(rendered.contains(r#"session: "myproject""#));
        assert!(rendered.contains(r#""MYPROJECT_ENV": "dev""#));
        assert!(rendered.contains(r#"herdr --session myproject"#));
        assert!(!rendered.contains(PLACEHOLDER));
    }

    #[test]
    fn render_sanitizes_env_key() {
        // Dashes (and anything else shell-hostile) become underscores, uppercased.
        let template =
            r#"(session: "pick-a-name", environment: {"pick-a-name_ENV": "dev"}, windows: [])"#;
        let rendered = render(template, "oiwn-dotfiles");
        assert!(rendered.contains(r#""OIWN_DOTFILES_ENV": "dev""#));
        assert!(rendered.contains(r#"session: "oiwn-dotfiles""#));
        assert!(!rendered.contains("oiwn-dotfiles_ENV"));
    }

    #[test]
    fn rendered_template_parses() {
        // The shipped template must stay loadable: parse `render` output.
        let template = include_str!("../../../dots/dotfiles/ws.ron");
        let rendered = render(template, "parse-check");
        crate::workspace::parse(&rendered).expect("rendered template parses");
    }
}
