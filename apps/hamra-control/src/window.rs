use crate::catalog::Catalog;
use gtk4::prelude::*;
use libadwaita::prelude::*;
use libadwaita::{self as adw};
use std::path::PathBuf;

pub struct MainWindow {
    window: adw::ApplicationWindow,
    repo: PathBuf,
}

impl MainWindow {
    pub fn new(app: &adw::Application, repo: &PathBuf) -> Self {
        let window = adw::ApplicationWindow::builder()
            .application(app)
            .default_width(900)
            .default_height(680)
            .title("Hamra Control")
            .build();

        let catalog = match Catalog::load(repo) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("hamra-control: {e}");
                let label = gtk4::Label::builder()
                    .label(format!("Failed to load configuration:\n{e}\n\nRun from the Hamra checkout."))
                    .margin_top(48)
                    .margin_bottom(48)
                    .margin_start(48)
                    .margin_end(48)
                    .wrap(true)
                    .build();
                window.set_content(Some(&label));
                return Self { window, repo: repo.clone() };
            }
        };

        let header = adw::HeaderBar::builder().build();

        let view_stack = adw::ViewStack::builder().build();

        let overview_page = Self::build_overview(&catalog);
        view_stack.add_titled(
            &overview_page,
            Some("overview"),
            "Overview",
        );
        view_stack.set_page_icon_name(
            view_stack.page(&overview_page),
            Some("open-menu-symbolic"),
        );

        let apps_page = Self::build_apps(&catalog);
        view_stack.add_titled(&apps_page, Some("apps"), "Apps");
        view_stack.set_page_icon_name(
            view_stack.page(&apps_page),
            Some("application-x-executable-symbolic"),
        );

        let new_page = Self::build_new_machine();
        view_stack.add_titled(&new_page, Some("new"), "New Machine");
        view_stack.set_page_icon_name(
            view_stack.page(&new_page),
            Some("list-add-symbolic"),
        );

        let switcher = adw::AdwViewSwitcher::builder()
            .stack(&view_stack)
            .policy(adw::ViewSwitcherPolicy::Wide)
            .build();

        header.set_title_widget(Some(&switcher));

        let root = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .build();
        root.append(&header);
        root.append(&view_stack);

        window.set_content(Some(&root));

        Self { window, repo: repo.clone() }
    }

    pub fn present(&self) {
        self.window.present();
    }

    fn build_overview(catalog: &Catalog) -> gtk4::Box {
        let page = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(24)
            .margin_top(32)
            .margin_bottom(32)
            .margin_start(32)
            .margin_end(32)
            .build();

        let title = gtk4::Label::builder()
            .label(&catalog.host.hostname)
            .css_classes(["title-1"])
            .build();
        page.append(&title);

        let info_group = adw::PreferencesGroup::builder()
            .title("Machine")
            .build();

        let gpu_row = adw::ActionRow::builder()
            .title("GPU")
            .subtitle(&catalog.host.gpu)
            .build();
        info_group.add(&gpu_row);

        let fw_row = adw::ActionRow::builder()
            .title("Firmware")
            .subtitle(&catalog.host.firmware)
            .build();
        info_group.add(&fw_row);

        let desk_row = adw::ActionRow::builder()
            .title("Desktop")
            .subtitle(&catalog.host.desktop)
            .build();
        info_group.add(&desk_row);

        let theme_row = adw::ActionRow::builder()
            .title("Theme")
            .subtitle(catalog.host.theme.as_deref().unwrap_or("default"))
            .build();
        info_group.add(&theme_row);

        page.append(&info_group);

        let hosts_group = adw::PreferencesGroup::builder()
            .title("Registered hosts")
            .build();
        for host in &catalog.hosts {
            let row = adw::ActionRow::builder().title(host).build();
            hosts_group.add(&row);
        }
        page.append(&hosts_group);

        let action_group = adw::PreferencesGroup::builder().build();
        let rebuild_btn = gtk4::Button::builder()
            .label("Rebuild & Apply")
            .css_classes(["suggested-action"])
            .build();
        let btn_row = adw::ActionRow::builder().build();
        btn_row.add_suffix(&rebuild_btn);
        action_group.add(&btn_row);
        page.append(&action_group);

        page
    }

    fn build_apps(catalog: &Catalog) -> gtk4::Box {
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

        let scroll = gtk4::ScrolledWindow::builder()
            .vexpand(true)
            .build();

        let content = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(12)
            .build();

        for (category, apps) in &catalog.apps.categories {
            let group = adw::PreferencesGroup::builder()
                .title(&category.to_uppercase())
                .build();
            for (app, enabled) in apps {
                let row = adw::ActionRow::builder()
                    .title(app)
                    .build();
                let check = gtk4::CheckButton::builder()
                    .valign(gtk4::Align::Center)
                    .build();
                check.set_active(*enabled);
                row.add_prefix(&check);
                group.add(&row);
            }
            content.append(&group);
        }

        scroll.set_child(Some(&content));
        page.append(&scroll);

        page
    }

    fn build_new_machine() -> gtk4::Box {
        let page = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(24)
            .margin_top(32)
            .margin_bottom(32)
            .margin_start(32)
            .margin_end(32)
            .build();

        let title = gtk4::Label::builder()
            .label("New machine")
            .css_classes(["title-2"])
            .build();
        page.append(&title);

        let subtitle = gtk4::Label::builder()
            .label("The wizard (hamra-init) generates and validates the host.\nThis page integrates it in the future.")
            .wrap(true)
            .css_classes(["dim-label"])
            .xalign(0.0)
            .build();
        page.append(&subtitle);

        let group = adw::PreferencesGroup::builder().build();
        let btn = gtk4::Button::builder()
            .label("Open CLI wizard")
            .css_classes(["suggested-action"])
            .build();
        btn.connect_clicked(|_| {
            let _ = std::process::Command::new("nix")
                .args(["run", ".#hamra-init"])
                .spawn();
        });
        let row = adw::ActionRow::builder().build();
        row.add_suffix(&btn);
        group.add(&row);
        page.append(&group);

        page
    }
}
