//! `ws load` — create the session from a workspace file via `rmux-sdk`,
//! then hand the terminal over with `exec rmux attach`.

use std::error::Error;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

use rmux_sdk::{
    EnsureSession, Pane, Rmux, SessionName, SplitDirection, TerminalLoadState, Window, WindowRef,
};

use crate::workspace::{self, Workspace};

pub async fn run(path: Option<PathBuf>, detach: bool) -> Result<(), Box<dyn Error>> {
    let path = path.unwrap_or_else(|| PathBuf::from(".ws.ron"));
    let ws = workspace::load(&path)?;

    let name = SessionName::new(ws.session.clone())?;
    let rmux = Rmux::builder().connect_or_start().await?;

    if !rmux.has_session(name.clone()).await? {
        build(&rmux, &ws).await?;
    }

    if detach {
        println!("session '{}' ready (detached)", ws.session);
        return Ok(());
    }

    // Final attach: replace this process with rmux so it inherits the real
    // TTY directly — no pipes, so the tmuxp-style hang cannot happen.
    let err = Command::new("rmux")
        .arg("attach")
        .arg("-t")
        .arg(&ws.session)
        .exec();
    Err(format!("exec rmux attach: {err}").into())
}

async fn build(rmux: &Rmux, ws: &Workspace) -> Result<(), Box<dyn Error>> {
    let name = SessionName::new(ws.session.clone())?;
    let first = ws
        .windows
        .first()
        .ok_or_else(|| format!("workspace '{}' has no windows", ws.session))?;

    // The session's initial window IS config window 0.
    let mut ensure = EnsureSession::try_named(ws.session.clone())?
        .create_or_reuse()
        .detached(true)
        .window_name(first.name.clone())
        .environment(env_pairs(ws));
    if let Some(dir) = &first.dir {
        ensure = ensure.working_directory(resolve_dir(dir).display().to_string());
    }
    let session = rmux.ensure_session(ensure).await?;

    // Window/pane indexes depend on the daemon's base-index (this setup uses
    // 1), so never assume: discover the initial pane — the session has
    // exactly one right after creation.
    let discovered = rmux.find_panes().session(&ws.session).all().await?;
    let initial = discovered
        .first()
        .ok_or_else(|| format!("session '{}' has no panes", ws.session))?;
    let initial_window_index = initial.window_index;
    send_commands(&initial.pane, ws.before.as_deref(), &first.commands).await?;
    for pane_cfg in first.panes.iter().flatten() {
        let pane = initial.pane.split(SplitDirection::Right).await?;
        send_commands(&pane, ws.before.as_deref(), &pane_cfg.commands).await?;
    }

    // Remaining windows are created detached so selection stays put until the
    // explicit focus selection below. Each builder returns the real handle;
    // panes are addressed through it, not through index math.
    let mut created: Vec<Window> = Vec::new();
    for window_cfg in ws.windows.iter().skip(1) {
        let mut builder = session
            .new_window_with()
            .name(window_cfg.name.clone())
            .detached(true);
        if let Some(dir) = &window_cfg.dir {
            builder = builder.cwd(resolve_dir(dir));
        }
        for (key, value) in &ws.environment {
            builder = builder.env(key, value);
        }
        let window = builder.await?;

        let pane_target = window
            .panes()
            .await?
            .first()
            .map(|pane| pane.target.clone())
            .ok_or_else(|| format!("window '{}' has no panes", window_cfg.name))?;
        let pane = rmux.pane(pane_target).await?;
        send_commands(&pane, ws.before.as_deref(), &window_cfg.commands).await?;
        for pane_cfg in window_cfg.panes.iter().flatten() {
            let extra = pane.split(SplitDirection::Right).await?;
            send_commands(&extra, ws.before.as_deref(), &pane_cfg.commands).await?;
        }
        created.push(window);
    }

    let focus_idx = ws
        .windows
        .iter()
        .position(|w| w.focus.unwrap_or(false))
        .unwrap_or(0);
    let focus_window = if focus_idx == 0 {
        rmux.window(WindowRef::new(name.clone(), initial_window_index))
            .await?
    } else if let Some(window) = created.get(focus_idx - 1) {
        window.clone()
    } else {
        rmux.window(WindowRef::new(name, initial_window_index))
            .await?
    };
    focus_window.select().await?;

    Ok(())
}

async fn send_commands(
    pane: &Pane,
    before: Option<&str>,
    commands: &[String],
) -> Result<(), Box<dyn Error>> {
    // Gate on the pane going quiet (shell booted): sends raced against
    // shell startup are otherwise swallowed — seen on the initial pane.
    if let Err(err) = pane
        .wait_for_load_state(TerminalLoadState::Quiet)
        .timeout(Duration::from_secs(5))
        .await
    {
        eprintln!("warn: pane did not settle within 5s ({err}); sending anyway");
    }
    if let Some(before) = before {
        pane.send_text(format!("{before}\n")).await?;
    }
    for command in commands {
        pane.send_text(format!("{command}\n")).await?;
    }
    Ok(())
}

/// `environment` entries as `KEY=value` strings for the SDK builders.
fn env_pairs(ws: &Workspace) -> Vec<String> {
    ws.environment
        .iter()
        .map(|(key, value)| format!("{key}={value}"))
        .collect()
}

/// Relative workspace dirs resolve against the current directory,
/// matching tmuxp `start-directory` semantics.
fn resolve_dir(dir: &str) -> PathBuf {
    let path = Path::new(dir);
    if path.is_absolute() {
        path.to_path_buf()
    } else {
        PathBuf::from(".").join(path)
    }
}
