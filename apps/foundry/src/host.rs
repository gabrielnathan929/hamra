use serde::Deserialize;
use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::path::Path;
use std::process::Command;

#[derive(Debug, Deserialize, Clone)]
pub struct HostState {
    pub hostname: String,
    pub gpu: String,
    pub firmware: String,
    pub desktop: String,
    pub keymap: Option<String>,
    pub xkb_variant: Option<String>,
    pub overrides: BTreeMap<String, bool>,
    pub profile: String,
}

impl HostState {
    pub fn load(repo: &Path, hostname: &str) -> Result<Self, String> {
        let val = nix_eval_json(
            &[&format!(".#nixosConfigurations.{hostname}.config.hamra")],
            repo,
        )?;

        let gpu = val.pointer("/hardware/gpu").and_then(|v| v.as_str()).unwrap_or("intel");
        let firmware = val.pointer("/hardware/firmware").and_then(|v| v.as_str()).unwrap_or("uefi");
        let desktop = val.pointer("/desktop/default").and_then(|v| v.as_str()).unwrap_or("hyprland");
        let keymap = val.pointer("/keyboard/keymap").and_then(|v| v.as_str()).map(String::from);
        let xkb_variant = val.pointer("/keyboard/xkbVariant").and_then(|v| v.as_str()).map(String::from);

        let overrides = read_overrides(repo, hostname)?;

        let profile = find_profile(repo)?;

        Ok(HostState {
            hostname: hostname.to_string(),
            gpu: gpu.to_string(),
            firmware: firmware.to_string(),
            desktop: desktop.to_string(),
            keymap,
            xkb_variant,
            overrides,
            profile,
        })
    }

    pub fn set_toggle(&mut self, path: &str, value: bool) {
        self.overrides.insert(path.to_string(), value);
    }

    pub fn remove_override(&mut self, path: &str) {
        self.overrides.remove(path);
    }

    pub fn generate_nix(&self) -> String {
        let mut out = String::new();
        writeln!(out, "_: {{").unwrap();
        writeln!(out, "  imports = [").unwrap();
        writeln!(out, "    ../../modules/nixos/core").unwrap();
        writeln!(out, "    ../../modules/nixos/desktops").unwrap();
        writeln!(out, "    ../../modules/nixos/programs").unwrap();
        writeln!(out, "    ../common").unwrap();
        writeln!(out, "    ../profiles/{}", self.profile).unwrap();
        writeln!(out, "    ./hardware-configuration.nix").unwrap();
        writeln!(out, "  ];").unwrap();
        writeln!(out).unwrap();
        writeln!(out, "  hamra = {{").unwrap();
        writeln!(out, "    networking.hostname = \"{}\";", self.hostname).unwrap();
        writeln!(out).unwrap();
        writeln!(out, "    hardware = {{").unwrap();
        writeln!(out, "      gpu = \"{}\";", self.gpu).unwrap();
        writeln!(out, "      firmware = \"{}\";", self.firmware).unwrap();
        writeln!(out, "    }};").unwrap();

        if let Some(kb) = &self.keymap {
            writeln!(out).unwrap();
            writeln!(out, "    keyboard = {{").unwrap();
            writeln!(out, "      keymap = \"{}\";", kb).unwrap();
            if let Some(v) = &self.xkb_variant {
                if !v.is_empty() {
                    writeln!(out, "      xkbVariant = \"{}\";", v).unwrap();
                }
            }
            writeln!(out, "    }};").unwrap();
        }

        writeln!(out).unwrap();
        writeln!(out, "    desktop.default = \"{}\";", self.desktop).unwrap();

        if !self.overrides.is_empty() {
            let by_category = group_by_category(&self.overrides);
            for (category, apps) in &by_category {
                writeln!(out).unwrap();
                writeln!(out, "    programs.optionals.{} = {{", category).unwrap();
                for (app, value) in apps {
                    let val = if *value { "true" } else { "false" };
                    if app.contains('-') {
                        writeln!(out, "      \"{}\" = {};", app, val).unwrap();
                    } else {
                        writeln!(out, "      {} = {};", app, val).unwrap();
                    }
                }
                writeln!(out, "    }};").unwrap();
            }
        }

        writeln!(out, "  }};").unwrap();
        writeln!(out, "}}").unwrap();
        out
    }

    pub fn save(&self, repo: &Path) -> Result<(), String> {
        let host_dir = repo.join("hosts").join(&self.hostname);
        let cfg_path = host_dir.join("configuration.nix");
        let tmp_path = host_dir.join(".configuration.nix.tmp");

        std::fs::write(&tmp_path, self.generate_nix())
            .map_err(|e| format!("failed to write temp file: {e}"))?;
        std::fs::rename(&tmp_path, &cfg_path)
            .map_err(|e| format!("failed to rename: {e}"))?;
        Ok(())
    }
}

fn group_by_category(overrides: &BTreeMap<String, bool>) -> BTreeMap<String, Vec<(String, bool)>> {
    let mut by_cat: BTreeMap<String, Vec<(String, bool)>> = BTreeMap::new();
    for (path, value) in overrides {
        let (cat, app) = match path.split_once('.') {
            Some((c, a)) => (c.to_string(), a.to_string()),
            None => continue,
        };
        by_cat.entry(cat).or_default().push((app, *value));
    }
    for apps in by_cat.values_mut() {
        apps.sort_by(|a, b| a.0.cmp(&b.0));
    }
    by_cat
}

fn read_overrides(repo: &Path, hostname: &str) -> Result<BTreeMap<String, bool>, String> {
    let cfg = std::fs::read_to_string(
        repo.join("hosts").join(hostname).join("configuration.nix"),
    )
    .map_err(|e| format!("cannot read host file: {e}"))?;

    let mut overrides = BTreeMap::new();
    for line in cfg.lines() {
        let trimmed = line.trim();
        if let Some(rest) = trimmed.strip_prefix("programs.optionals.") {
            let rest = rest.strip_suffix(';').unwrap_or(rest);
            let parts: Vec<&str> = rest.splitn(2, '.').collect();
            if parts.len() == 2 {
                let cat = parts[0];
                let rest = parts[1];
                let (app, value) = if rest.contains("= true") {
                    (rest.strip_suffix("= true").unwrap_or(rest).trim(), true)
                } else if rest.contains("= false") {
                    (rest.strip_suffix("= false").unwrap_or(rest).trim(), false)
                } else {
                    continue;
                };
                let app = app.replace('"', "");
                overrides.insert(format!("{}.{}", cat, app), value);
            }
        }
    }
    Ok(overrides)
}

fn find_profile(repo: &Path) -> Result<String, String> {
    let profiles_dir = repo.join("hosts/profiles");
    let entries = std::fs::read_dir(&profiles_dir)
        .map_err(|e| format!("cannot read profiles dir: {e}"))?;
    for entry in entries {
        let entry = entry.map_err(|e| e.to_string())?;
        if entry.file_type().map(|t| t.is_dir()).unwrap_or(false) {
            return Ok(entry.file_name().to_string_lossy().to_string());
        }
    }
    Err("no profile found".to_string())
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
        return Err(format!("nix eval: {stderr}"));
    }
    serde_json::from_slice(&output.stdout)
        .map_err(|e| format!("JSON parse: {e}"))
}
