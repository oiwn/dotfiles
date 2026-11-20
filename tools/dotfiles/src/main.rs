mod init;
mod load;
mod workspace;

use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "dotfiles", version, about = "Personal dotfiles workflow CLI")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Manage rmux workspaces
    Ws {
        #[command(subcommand)]
        command: WsCommand,
    },
}

#[derive(Subcommand)]
enum WsCommand {
    /// Load a workspace: create the session if needed, then attach
    Load {
        /// Workspace file to load (default: ./.ws.ron)
        path: Option<PathBuf>,
        /// Create the session without attaching
        #[arg(short, long)]
        detach: bool,
    },
    /// Scaffold ./.ws.ron from the managed template
    Init {
        /// Session name (default: current directory name)
        name: Option<String>,
    },
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    match Cli::parse().command {
        Command::Ws { command } => match command {
            WsCommand::Load { path, detach } => load::run(path, detach).await?,
            WsCommand::Init { name } => init::run(name)?,
        },
    }
    Ok(())
}
