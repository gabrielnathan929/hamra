mod catalog;
mod window;

use gtk4::prelude::*;
use libadwaita::prelude::*;

const APP_ID: &str = "dev.hamra.control";

fn main() {
    let app = libadwaita::Application::builder()
        .application_id(APP_ID)
        .build();

    app.connect_activate(|app| {
        let repo = std::env::var("HAMRA_REPO")
            .unwrap_or_else(|_| {
                std::env::current_dir()
                    .map(|p| p.to_string_lossy().to_string())
                    .unwrap_or_default()
            });

        let repo = std::path::PathBuf::from(repo);
        if !repo.join("flake.nix").exists() {
            eprintln!("hamra-control: flake.nix not found in {repo:?}");
            eprintln!("Run from the Hamra checkout or set HAMRA_REPO.");
            std::process::exit(1);
        }

        let win = window::MainWindow::new(app, &repo);
        win.present();
    });

    app.run();
}
