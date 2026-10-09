use crate::catalog::Catalog;
use crate::host::HostState;
use gtk4::prelude::*;
use libadwaita::prelude::*;
use libadwaita::{self as adw};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

pub struct MainWindow {
    window: adw::ApplicationWindow,
}

impl MainWindow {
    pub fn new(app: &adw::Application, repo: &PathBuf) -> Self {
        let window = adw::ApplicationWindow::builder()
            .application(app)
            .default_width(900)
            .default_height(680)
            .title("Foundry")
            .build();

        let catalog = match Catalog::load(repo) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("foundry: {e}");
                let label = gtk4::Label::builder()
                    .label(format!("Failed to load configuration:\n{e}\n\nRun from the Hamra checkout."))
                    .margin_top(48)
                    .margin_bottom(48)
                    .margin_start(48)
                    .margin_end(48)
                    .wrap(true)
                    .build();
                window.set_content(Some(&label));
                return Self { window };
            }
        };

        let hostname = std::fs::read_to_string("/proc/sys/kernel/hostname")
            .unwrap_or_default()
            .trim()
            .to_string();

        let host_state = Rc::new(RefCell::new(
            HostState::load(repo, &hostname).unwrap_or_else(|e| {
                eprintln!("foundry: cannot load host state: {e}");
                HostState::load(repo, &catalog.hosts.first().cloned().unwrap_or_default())
                    .unwrap_or_else(|_| HostState::fallback(&hostname))
            })
        ));

        let overlay = adw::ToastOverlay::builder().build();

        let header = adw::HeaderBar::builder().build();
        let view_stack = adw::ViewStack::builder().build();

        let overview_page = Self::build_overview(&catalog, &host_state);
        view_stack.add_titled(&overview_page, Some("overview"), "Overview");

        let apps_page = Self::build_apps(repo, &catalog, &host_state, &overlay);
        view_stack.add_titled(&apps_page, Some("apps"), "Apps");

        let switcher = adw::ViewSwitcher::builder()
            .stack(&view_stack)
            .policy(adw::ViewSwitcherPolicy::Wide)
            .build();
        header.set_title_widget(Some(&switcher));

        let root = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .build();
        root.append(&header);

        let stack_box = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .vexpand(true)
            .build();
        stack_box.append(&view_stack);
        overlay.set_child(Some(&stack_box));
        root.append(&overlay);

        window.set_content(Some(&root));

        Self { window }
    }

    pub fn present(&self) {
        self.window.present();
    }

    fn build_overview(catalog: &Catalog, host_state: &Rc<RefCell<HostState>>) -> gtk4::Box {
        let page = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(24)
            .margin_top(32)
            .margin_bottom(32)
            .margin_start(32)
            .margin_end(32)
            .build();

        let hs = host_state.borrow();
        let title = gtk4::Label::builder()
            .label(&hs.hostname)
            .css_classes(["title-1"])
            .build();
        page.append(&title);

        let info_group = adw::PreferencesGroup::builder().title("Machine").build();

        for (label, value) in [
            ("GPU", &hs.gpu),
            ("Firmware", &hs.firmware),
            ("Desktop", &hs.desktop),
        ] {
            let row = adw::ActionRow::builder().title(label).subtitle(value).build();
            info_group.add(&row);
        }
        page.append(&info_group);

        let hosts_group = adw::PreferencesGroup::builder()
            .title("Registered hosts")
            .build();
        for h in &catalog.hosts {
            let row = adw::ActionRow::builder().title(h).build();
            hosts_group.add(&row);
        }
        page.append(&hosts_group);
        drop(hs);

        page
    }

    fn build_apps(
        repo: &PathBuf,
        catalog: &Catalog,
        host_state: &Rc<RefCell<HostState>>,
        overlay: &adw::ToastOverlay,
    ) -> gtk4::Box {
        let page = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(12)
            .margin_top(24)
            .margin_bottom(24)
            .margin_start(24)
            .margin_end(24)
            .build();

        let search = gtk4::SearchBar::builder().build();
        let search_entry = gtk4::SearchEntry::builder()
            .placeholder_text("Search apps…")
            .build();
        search.set_child(Some(&search_entry));
        page.append(&search);

        let scroll = gtk4::ScrolledWindow::builder().vexpand(true).build();
        let content = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(12)
            .build();

        let search_text = std::rc::Rc::new(std::cell::RefCell::new(String::new()));
        let all_rows: Rc<RefCell<Vec<(gtk4::Box, String)>>> = Rc::new(RefCell::new(Vec::new()));

        for (category, apps) in &catalog.apps.categories {
            let group = adw::PreferencesGroup::builder()
                .title(&category.to_uppercase())
                .build();

            for (app, enabled) in apps {
                let row_box = gtk4::Box::builder()
                    .orientation(gtk4::Orientation::Horizontal)
                    .spacing(12)
                    .build();

                let label = gtk4::Label::builder()
                    .label(app)
                    .hexpand(true)
                    .xalign(0.0)
                    .build();
                row_box.append(&label);

                let switch = gtk4::Switch::builder()
                    .valign(gtk4::Align::Center)
                    .build();
                switch.set_active(*enabled);

                let hs = host_state.borrow();
                let override_key = format!("{}.{}", category, app);
                let has_override = hs.overrides.contains_key(&override_key);
                drop(hs);

                if has_override {
                    switch.add_css_class("foundry-override");
                }

                let hs_clone = host_state.clone();
                let repo_clone = repo.clone();
                let overlay_clone = overlay.clone();
                let app_name = app.clone();
                let cat_name = category.clone();

                switch.connect_active_notify(move |sw| {
                    let active = sw.is_active();
                    let mut hs = hs_clone.borrow_mut();
                    hs.set_toggle(&format!("{}.{}", cat_name, app_name), active);

                    if let Err(e) = hs.save(&repo_clone) {
                        eprintln!("foundry: save failed: {e}");
                        sw.set_active(!active);
                        return;
                    }

                    if active {
                        sw.remove_css_class("foundry-override");
                    } else {
                        sw.add_css_class("foundry-override");
                    }

                    let toast = adw::Toast::builder()
                        .title(if active {
                            format!("{} enabled", app_name)
                        } else {
                            format!("{} disabled", app_name)
                        })
                        .timeout(2)
                        .build();
                    overlay_clone.add_toast(toast);
                });

                row_box.append(&switch);

                let app_lower = app.to_lowercase();
                let cat_lower = category.to_lowercase();
                let search_key = format!("{} {}", cat_lower, app_lower);
                all_rows.borrow_mut().push((row_box.clone(), search_key));

                group.add(&row_box);
            }
            content.append(&group);
        }

        let entry_clone = search_entry.clone();
        let rows_clone = all_rows.clone();
        search_entry.connect_changed(move |entry| {
            let query = entry.text().to_lowercase();
            *search_text.borrow_mut() = query;
            for (row, key) in rows_clone.borrow().iter() {
                row.set_visible(key.contains(&*search_text.borrow()));
            }
        });
        let _ = entry_clone;

        scroll.set_child(Some(&content));
        page.append(&scroll);

        page
    }
}
