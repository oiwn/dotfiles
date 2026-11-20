//! `.ws.ron` workspace files — the tmuxp subset this tool replaces.
//!
//! Flattened schema (RON, `implicit_some` enabled by the parser):
//! one line per window; `panes` is the optional multi-pane escape hatch.
//!
//! ```ron
//! (
//!     session: "myproject",
//!     environment: {"RUST_LOG": "info"},
//!     before: "clear",
//!     windows: [
//!         (name: "code", focus: true, dir: "./", commands: ["hx"]),
//!         (name: "srv", commands: ["cargo watch -x check"],
//!          panes: [(commands: ["tail -f log"])]),
//!     ],
//! )
//! ```

use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Workspace {
    pub session: String,
    #[serde(default)]
    pub environment: BTreeMap<String, String>,
    pub before: Option<String>,
    pub windows: Vec<Window>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Window {
    pub name: String,
    pub focus: Option<bool>,
    pub dir: Option<String>,
    pub commands: Vec<String>,
    pub panes: Option<Vec<Pane>>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Pane {
    pub commands: Vec<String>,
}

pub fn parse(input: &str) -> Result<Workspace, ron::error::SpannedError> {
    ron::Options::default()
        .with_default_extension(ron::extensions::Extensions::IMPLICIT_SOME)
        .from_str(input)
}

pub fn load(path: &Path) -> Result<Workspace, Box<dyn std::error::Error>> {
    let text = fs::read_to_string(path).map_err(|e| format!("reading {}: {e}", path.display()))?;
    parse(&text).map_err(|e| format!("parsing {}: {e}", path.display()).into())
}

#[cfg(test)]
mod tests {
    use super::*;

    const VALID: &str = r#"
        (
            session: "myproject",
            environment: {"RUST_LOG": "info", "PROJECT_ENV": "dev"},
            before: "clear",
            windows: [
                (name: "code", focus: true, dir: "./", commands: ["hx"]),
                (name: "agents", commands: ["eza"]),
                (
                    name: "srv",
                    commands: ["cargo watch -x check"],
                    panes: [(commands: ["tail -f log"])],
                ),
            ],
        )
    "#;

    #[test]
    fn parses_valid_workspace() {
        let ws = parse(VALID).expect("valid workspace must parse");
        assert_eq!(ws.session, "myproject");
        assert_eq!(ws.before.as_deref(), Some("clear"));
        assert_eq!(
            ws.environment.get("RUST_LOG").map(String::as_str),
            Some("info")
        );
        assert_eq!(ws.windows.len(), 3);

        assert_eq!(ws.windows[0].name, "code");
        assert_eq!(ws.windows[0].focus, Some(true));
        assert_eq!(ws.windows[0].dir.as_deref(), Some("./"));
        assert_eq!(ws.windows[0].commands, ["hx"]);

        assert_eq!(ws.windows[1].focus, None);
        assert!(ws.windows[1].panes.is_none());

        let panes = ws.windows[2].panes.as_ref().expect("panes");
        assert_eq!(panes.len(), 1);
        assert_eq!(panes[0].commands, ["tail -f log"]);
    }

    #[test]
    fn environment_defaults_to_empty() {
        let ws = parse(r#"(session: "x", windows: [(name: "a", commands: ["b"])])"#)
            .expect("environment is optional");
        assert!(ws.environment.is_empty());
        assert_eq!(ws.before, None);
    }

    #[test]
    fn rejects_unknown_fields() {
        let err = parse(r#"(session: "x", windows: [(name: "a", commands: ["b"])], nope: 1)"#)
            .expect_err("unknown top-level field");
        assert!(err.to_string().contains("nope"), "got: {err}");

        let err = parse(r#"(session: "x", windows: [(name: "a", commands: ["b"], bogus: 2)])"#)
            .expect_err("unknown window field");
        assert!(err.to_string().contains("bogus"), "got: {err}");
    }

    #[test]
    fn rejects_missing_required_fields() {
        assert!(parse(r#"(windows: [(name: "a", commands: ["b"])])"#).is_err());
        assert!(parse(r#"(session: "x")"#).is_err());
        assert!(parse(r#"(session: "x", windows: [(commands: ["b"])])"#).is_err());
        assert!(parse(r#"(session: "x", windows: [(name: "a")])"#).is_err());
    }
}
