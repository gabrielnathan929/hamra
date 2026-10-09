use serde::Deserialize;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Debug, Deserialize, Clone)]
pub struct HostInfo {
    pub hostname: String,
    pub gpu: String,
    pub firmware: String,
    pub desktop: String,
    pub theme: Option<String>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AppCatalog {
    pub categories: BTreeMap<String, BTreeMap<String, bool>>,
    pub descriptions: BTreeMap<String, String>,
}

#[derive(Debug)]
pub struct Catalog {
    pub host: HostInfo,
    pub apps: AppCatalog,
    pub hosts: Vec<String>,
    pub repo: PathBuf,
}

fn nix_eval_json(args: &[&str], repo: &Path) -> Result<serde_json::Value, String> {
    let output = Command::new("nix")
        .args(["eval", "--json"])
        .args(args)
        .current_dir(repo)
        .output()
        .map_err(|e| format!("failed to run nix: {e}"))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("nix eval failed: {stderr}"));
    }

    serde_json::from_slice(&output.stdout)
        .map_err(|e| format!("failed to parse JSON: {e}"))
}

impl Catalog {
    pub fn load(repo: &Path) -> Result<Self, String> {
        let hostname = std::fs::read_to_string("/proc/sys/kernel/hostname")
            .unwrap_or_default()
            .trim()
            .to_string();

        let hosts_val = nix_eval_json(
            &["--file", &repo.join("flake/hosts.nix").to_string_lossy(), "--apply", "x: builtins.attrNames x"],
            repo,
        )?;
        let hosts: Vec<String> = serde_json::from_value(hosts_val)
            .unwrap_or_default();

        let sample = hosts.first().cloned().unwrap_or_else(|| "samsung".to_string());

        let host_val = nix_eval_json(
            &[&format!(".#nixosConfigurations.{sample}.config.hamra")],
            repo,
        )?;

        let host = HostInfo {
            hostname: hostname.clone(),
            gpu: host_val
                .pointer("/hardware/gpu")
                .and_then(|v| v.as_str())
                .unwrap_or("unknown")
                .to_string(),
            firmware: host_val
                .pointer("/hardware/firmware")
                .and_then(|v| v.as_str())
                .unwrap_or("uefi")
                .to_string(),
            desktop: host_val
                .pointer("/desktop/default")
                .and_then(|v| v.as_str())
                .unwrap_or("hyprland")
                .to_string(),
            theme: host_val
                .pointer("/theme/name")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string()),
        };

        let apps_val = nix_eval_json(
            &[&format!(
                ".#nixosConfigurations.{sample}.config.hamra.programs.optionals"
            )],
            repo,
        )?;

        let mut categories = BTreeMap::new();
        if let serde_json::Value::Object(map) = &apps_val {
            for (category, apps) in map {
                let mut app_map = BTreeMap::new();
                if let serde_json::Value::Object(apps_map) = apps {
                    for (app, value) in apps_map {
                        app_map.insert(app.clone(), value.as_bool().unwrap_or(false));
                    }
                }
                categories.insert(category.clone(), app_map);
            }
        }

        Ok(Catalog {
            host,
            apps: AppCatalog {
                categories,
                descriptions: BTreeMap::new(),
            },
            hosts,
            repo: repo.to_path_buf(),
        })
    }
}
