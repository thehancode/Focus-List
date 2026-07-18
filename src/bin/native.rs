#![cfg_attr(all(windows, not(debug_assertions)), windows_subsystem = "windows")]

use std::{
    sync::Arc,
    time::{Duration, Instant},
};

use anyhow::{Context, Result};
use eframe::egui::{
    self, Align2, Color32, FontData, FontDefinitions, FontFamily, FontId, Pos2, Rect,
    ResizeDirection, Vec2,
};
use ratatui::{
    Terminal,
    backend::TestBackend,
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers},
    style::{Color, Modifier},
};
use tui_kanban::{app::App, model::DEFAULT_NATIVE_FONT_SIZE, tasklists_dir, ui};

const BACKGROUND: Color32 = Color32::from_rgb(13, 15, 24);
const DEFAULT_TEXT: Color32 = Color32::from_rgb(221, 224, 235);
const STARTUP_COLUMNS: f32 = 35.0;
const STARTUP_ROWS: f32 = 100.0;
// These values match the default 16 pt bundled font metrics at 100% display
// scaling, so the native window opens as a 35-column by 100-row grid.
const DEFAULT_CELL_WIDTH: f32 = 8.4;
const DEFAULT_CELL_HEIGHT: f32 = 17.0;
const FRAME_TIME: Duration = Duration::from_millis(33);
const REGULAR_FONT: &str = "ubuntu-mono-nerd-regular";
const BOLD_FONT: &str = "ubuntu-mono-nerd-bold";

fn main() -> Result<()> {
    let mut app = App::load(tasklists_dir()?)?;
    app.disable_terminal_bell();
    let startup_font_scale = app.config.native_font_size as f32 / DEFAULT_NATIVE_FONT_SIZE as f32;
    let startup_cell_width = DEFAULT_CELL_WIDTH * startup_font_scale;
    let startup_cell_height = DEFAULT_CELL_HEIGHT * startup_font_scale;
    let native_app = NativeApp::new(app)?;
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([
                STARTUP_COLUMNS * startup_cell_width,
                STARTUP_ROWS * startup_cell_height,
            ])
            .with_min_inner_size([STARTUP_COLUMNS * startup_cell_width, 255.0])
            .with_decorations(false)
            .with_resizable(true),
        // A previous manual resize would otherwise override the requested
        // startup grid on the next launch.
        persist_window: false,
        ..Default::default()
    };
    eframe::run_native(
        "Focus List",
        options,
        Box::new(move |creation_context| {
            install_fonts(&creation_context.egui_ctx);
            Ok(Box::new(native_app))
        }),
    )
    .context("could not start the native window")?;
    Ok(())
}

struct NativeApp {
    app: App,
    terminal: Terminal<TestBackend>,
    grid: (u16, u16),
    fatal_error: Option<String>,
}

impl NativeApp {
    fn new(app: App) -> Result<Self> {
        Ok(Self {
            app,
            terminal: Terminal::new(TestBackend::new(1, 1))?,
            grid: (1, 1),
            fatal_error: None,
        })
    }

    fn ensure_grid(&mut self, grid: (u16, u16)) -> Result<()> {
        if self.grid != grid {
            self.terminal = Terminal::new(TestBackend::new(grid.0, grid.1))?;
            self.grid = grid;
        }
        Ok(())
    }

    fn handle_input(&mut self, ctx: &egui::Context, now: Instant) {
        let events = ctx.input(|input| input.events.clone());
        for event in events {
            match event {
                egui::Event::Key {
                    key,
                    pressed,
                    repeat,
                    modifiers,
                    ..
                } => {
                    if let Some(mut key) = egui_key(key, modifiers) {
                        key.kind = if pressed {
                            if repeat {
                                ratatui::crossterm::event::KeyEventKind::Repeat
                            } else {
                                ratatui::crossterm::event::KeyEventKind::Press
                            }
                        } else {
                            ratatui::crossterm::event::KeyEventKind::Release
                        };
                        self.app.handle_key(key, now);
                    }
                }
                egui::Event::Text(text) | egui::Event::Paste(text) => {
                    if !ctx.input(|input| input.modifiers.command || input.modifiers.ctrl) {
                        for character in text.chars() {
                            self.app.handle_key(
                                KeyEvent::new(KeyCode::Char(character), KeyModifiers::NONE),
                                now,
                            );
                        }
                    }
                }
                egui::Event::Cut => self.app.handle_key(
                    KeyEvent::new(KeyCode::Char('x'), KeyModifiers::CONTROL),
                    now,
                ),
                _ => {}
            }
        }
    }

    fn handle_pointer(&mut self, ctx: &egui::Context, area: Rect) {
        let font_size = self.app.config.native_font_size as f32;
        let geometry = GridGeometry::new(ctx, area, cell_metrics(ctx, font_size));
        let (pointer, pressed) =
            ctx.input(|input| (input.pointer.hover_pos(), input.pointer.primary_pressed()));
        let Some(cell) = pointer.and_then(|position| geometry.cell_at(position)) else {
            return;
        };

        match grid_hit(cell, geometry.size, &self.app) {
            GridHit::Drag => {
                ctx.set_cursor_icon(egui::CursorIcon::Grab);
                if pressed {
                    ctx.send_viewport_cmd(egui::ViewportCommand::StartDrag);
                }
            }
            GridHit::Resize(direction) => {
                ctx.set_cursor_icon(resize_cursor(direction));
                if pressed {
                    ctx.send_viewport_cmd(egui::ViewportCommand::BeginResize(direction));
                }
            }
            GridHit::Task(task_id) => {
                if pressed {
                    self.app.selected_task = Some(task_id);
                }
            }
            GridHit::Tab(index) => {
                ctx.set_cursor_icon(egui::CursorIcon::PointingHand);
                if pressed {
                    self.app.select_list(index);
                }
            }
            GridHit::Content => {}
        }
    }

    fn render(&mut self, ui_context: &egui::Context, ui: &mut egui::Ui, area: Rect) {
        let font_size = self.app.config.native_font_size as f32;
        let metrics = cell_metrics(ui_context, font_size);
        let grid = grid_size(area.size(), metrics);
        if grid.0 == 0 || grid.1 == 0 {
            return;
        }
        if let Err(error) = self.ensure_grid(grid) {
            self.fatal_error = Some(format!("Could not prepare the character grid: {error:#}"));
            return;
        }
        if let Err(error) = self.terminal.draw(|frame| ui::render(frame, &self.app)) {
            self.fatal_error = Some(format!("Could not render the interface: {error:#}"));
            return;
        }

        let geometry = GridGeometry::new(ui_context, area, metrics);
        let origin = geometry.origin;
        let painter = ui.painter_at(area);
        let regular_font = FontId::new(font_size, FontFamily::Name(REGULAR_FONT.into()));
        let bold_font = FontId::new(font_size, FontFamily::Name(BOLD_FONT.into()));
        let buffer = self.terminal.backend().buffer();

        for (index, cell) in buffer.content.iter().enumerate() {
            let x = (index % grid.0 as usize) as f32;
            let y = (index / grid.0 as usize) as f32;
            let rect = Rect::from_min_max(
                Pos2::new(
                    snap_to_pixel(ui_context, origin.x + x * metrics.width),
                    snap_to_pixel(ui_context, origin.y + y * metrics.height),
                ),
                Pos2::new(
                    snap_to_pixel(ui_context, origin.x + (x + 1.0) * metrics.width),
                    snap_to_pixel(ui_context, origin.y + (y + 1.0) * metrics.height),
                ),
            );
            let (foreground, background) = cell_colors(cell.fg, cell.bg, cell.modifier);
            painter.rect_filled(rect, 0.0, background);

            if !cell.modifier.contains(Modifier::HIDDEN) && cell.symbol() != " " {
                let font = if cell.modifier.contains(Modifier::BOLD) {
                    bold_font.clone()
                } else {
                    regular_font.clone()
                };
                painter.text(rect.min, Align2::LEFT_TOP, cell.symbol(), font, foreground);
                if cell.modifier.contains(Modifier::CROSSED_OUT) {
                    painter.line_segment(
                        [
                            Pos2::new(rect.min.x, rect.center().y),
                            Pos2::new(rect.max.x, rect.center().y),
                        ],
                        (1.0, foreground),
                    );
                }
            }
        }

        // Keep terminal-style effects alive. A later phase will schedule only
        // the next required repaint instead of continuously updating while idle.
        ui_context.request_repaint_after(FRAME_TIME);
    }
}

impl eframe::App for NativeApp {
    fn ui(&mut self, root_ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        let ctx = root_ui.ctx().clone();
        let now = Instant::now();
        self.app.tick(now);
        self.handle_input(&ctx, now);

        egui::CentralPanel::default()
            .frame(egui::Frame::NONE)
            .show(root_ui, |ui| {
                let area = ui.max_rect();
                ui.painter().rect_filled(area, 0.0, BACKGROUND);
                if let Some(error) = &self.fatal_error {
                    ui.centered_and_justified(|ui| {
                        ui.colored_label(Color32::from_rgb(244, 112, 122), error);
                    });
                } else {
                    self.handle_pointer(&ctx, area);
                    self.render(&ctx, ui, area);
                }
            });

        if self.app.should_quit {
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
        }
    }
}

#[derive(Clone, Copy, Debug)]
struct CellMetrics {
    width: f32,
    height: f32,
}

#[derive(Clone, Copy, Debug)]
struct GridGeometry {
    origin: Pos2,
    metrics: CellMetrics,
    size: (u16, u16),
}

impl GridGeometry {
    fn new(ctx: &egui::Context, area: Rect, metrics: CellMetrics) -> Self {
        let size = grid_size(area.size(), metrics);
        let rendered_size = Vec2::new(
            size.0 as f32 * metrics.width,
            size.1 as f32 * metrics.height,
        );
        let origin = Pos2::new(
            snap_to_pixel(
                ctx,
                area.min.x + (area.width() - rendered_size.x).max(0.0) / 2.0,
            ),
            snap_to_pixel(
                ctx,
                area.min.y + (area.height() - rendered_size.y).max(0.0) / 2.0,
            ),
        );
        Self {
            origin,
            metrics,
            size,
        }
    }

    fn cell_at(self, position: Pos2) -> Option<(u16, u16)> {
        let relative = position - self.origin;
        if relative.x < 0.0 || relative.y < 0.0 {
            return None;
        }
        let column = (relative.x / self.metrics.width).floor() as u16;
        let row = (relative.y / self.metrics.height).floor() as u16;
        (column < self.size.0 && row < self.size.1).then_some((column, row))
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum GridHit {
    Drag,
    Resize(ResizeDirection),
    Task(uuid::Uuid),
    Tab(usize),
    Content,
}

fn grid_hit(cell: (u16, u16), size: (u16, u16), app: &App) -> GridHit {
    if let Some(hit) = chrome_hit(cell, size) {
        return hit;
    }

    if let Some(index) = ui::tab_at(app, size.0, cell.0, cell.1) {
        return GridHit::Tab(index);
    }

    ui::task_at(
        app,
        ratatui::layout::Rect::new(0, 0, size.0, size.1),
        cell.0,
        cell.1,
    )
    .map(GridHit::Task)
    .unwrap_or(GridHit::Content)
}

fn chrome_hit(cell: (u16, u16), size: (u16, u16)) -> Option<GridHit> {
    let (column, row) = cell;
    if size.0 == 0 || size.1 == 0 {
        return None;
    }

    // The top character row replaces the missing native title bar.
    if row == 0 {
        return Some(GridHit::Drag);
    }
    let last_column = size.0 - 1;
    let last_row = size.1 - 1;
    let resize = match (column, row) {
        (0, y) if y == last_row => Some(ResizeDirection::SouthWest),
        (x, y) if x == last_column && y == last_row => Some(ResizeDirection::SouthEast),
        (_, y) if y == last_row => Some(ResizeDirection::South),
        (0, _) => Some(ResizeDirection::West),
        (x, _) if x == last_column => Some(ResizeDirection::East),
        _ => None,
    };
    resize.map(GridHit::Resize)
}

fn resize_cursor(direction: ResizeDirection) -> egui::CursorIcon {
    match direction {
        ResizeDirection::North | ResizeDirection::South => egui::CursorIcon::ResizeVertical,
        ResizeDirection::East | ResizeDirection::West => egui::CursorIcon::ResizeHorizontal,
        ResizeDirection::NorthEast | ResizeDirection::SouthWest => egui::CursorIcon::ResizeNeSw,
        ResizeDirection::NorthWest | ResizeDirection::SouthEast => egui::CursorIcon::ResizeNwSe,
    }
}

fn install_fonts(ctx: &egui::Context) {
    ctx.set_fonts(font_definitions());
}

fn font_definitions() -> FontDefinitions {
    let mut fonts = FontDefinitions::default();
    let fallback_fonts = fonts
        .families
        .get(&FontFamily::Monospace)
        .cloned()
        .unwrap_or_default();
    fonts.font_data.insert(
        REGULAR_FONT.into(),
        Arc::new(FontData::from_static(include_bytes!(
            "../../assets/fonts/UbuntuMonoNerdFontMono-Regular.ttf"
        ))),
    );
    fonts.font_data.insert(
        BOLD_FONT.into(),
        Arc::new(FontData::from_static(include_bytes!(
            "../../assets/fonts/UbuntuMonoNerdFontMono-Bold.ttf"
        ))),
    );
    fonts
        .families
        .entry(FontFamily::Monospace)
        .or_default()
        .insert(0, REGULAR_FONT.into());
    fonts.families.insert(
        FontFamily::Name(REGULAR_FONT.into()),
        std::iter::once(REGULAR_FONT.into())
            .chain(fallback_fonts.iter().cloned())
            .collect(),
    );
    fonts.families.insert(
        FontFamily::Name(BOLD_FONT.into()),
        std::iter::once(BOLD_FONT.into())
            .chain(fallback_fonts)
            .collect(),
    );
    fonts
}

fn cell_metrics(ctx: &egui::Context, font_size: f32) -> CellMetrics {
    let font = FontId::new(font_size, FontFamily::Name(REGULAR_FONT.into()));
    let (width, height) =
        ctx.fonts_mut(|fonts| (fonts.glyph_width(&font, 'W'), fonts.row_height(&font)));
    CellMetrics {
        width: width.max(1.0),
        height: height.max(1.0),
    }
}

fn snap_to_pixel(ctx: &egui::Context, value: f32) -> f32 {
    let scale = ctx.pixels_per_point();
    (value * scale).round() / scale
}

fn grid_size(size: Vec2, metrics: CellMetrics) -> (u16, u16) {
    let columns = (size.x / metrics.width).floor().clamp(0.0, u16::MAX as f32) as u16;
    let rows = (size.y / metrics.height)
        .floor()
        .clamp(0.0, u16::MAX as f32) as u16;
    (columns, rows)
}

fn egui_key(key: egui::Key, modifiers: egui::Modifiers) -> Option<KeyEvent> {
    let code = match key {
        egui::Key::ArrowUp => KeyCode::Up,
        egui::Key::ArrowDown => KeyCode::Down,
        egui::Key::ArrowLeft => KeyCode::Left,
        egui::Key::ArrowRight => KeyCode::Right,
        egui::Key::Home => KeyCode::Home,
        egui::Key::End => KeyCode::End,
        egui::Key::Escape => KeyCode::Esc,
        egui::Key::Tab => KeyCode::Tab,
        egui::Key::F2 => KeyCode::F(2),
        egui::Key::Enter => KeyCode::Enter,
        egui::Key::Backspace => KeyCode::Backspace,
        egui::Key::Delete => KeyCode::Delete,
        egui::Key::Space => KeyCode::Char(' '),
        egui::Key::C if modifiers.ctrl || modifiers.command => KeyCode::Char('c'),
        egui::Key::N if modifiers.ctrl || modifiers.command => KeyCode::Char('n'),
        egui::Key::R if modifiers.ctrl || modifiers.command => KeyCode::Char('r'),
        egui::Key::X if modifiers.ctrl || modifiers.command => KeyCode::Char('x'),
        _ => return None,
    };
    let mut modifier = KeyModifiers::NONE;
    if modifiers.ctrl || modifiers.command {
        modifier.insert(KeyModifiers::CONTROL);
    }
    if modifiers.shift {
        modifier.insert(KeyModifiers::SHIFT);
    }
    if modifiers.alt {
        modifier.insert(KeyModifiers::ALT);
    }
    Some(KeyEvent::new(code, modifier))
}

fn cell_colors(foreground: Color, background: Color, modifiers: Modifier) -> (Color32, Color32) {
    let mut foreground = color_to_egui(foreground, DEFAULT_TEXT);
    let mut background = color_to_egui(background, BACKGROUND);
    if modifiers.contains(Modifier::REVERSED) {
        std::mem::swap(&mut foreground, &mut background);
    }
    if modifiers.contains(Modifier::DIM) {
        foreground =
            Color32::from_rgba_unmultiplied(foreground.r(), foreground.g(), foreground.b(), 160);
    }
    (foreground, background)
}

fn color_to_egui(color: Color, reset: Color32) -> Color32 {
    match color {
        Color::Reset => reset,
        Color::Black => Color32::from_rgb(0, 0, 0),
        Color::Red => Color32::from_rgb(205, 49, 49),
        Color::Green => Color32::from_rgb(13, 188, 121),
        Color::Yellow => Color32::from_rgb(229, 229, 16),
        Color::Blue => Color32::from_rgb(36, 114, 200),
        Color::Magenta => Color32::from_rgb(188, 63, 188),
        Color::Cyan => Color32::from_rgb(17, 168, 205),
        Color::Gray => Color32::from_rgb(229, 229, 229),
        Color::DarkGray => Color32::from_rgb(102, 102, 102),
        Color::LightRed => Color32::from_rgb(241, 76, 76),
        Color::LightGreen => Color32::from_rgb(35, 209, 139),
        Color::LightYellow => Color32::from_rgb(245, 245, 67),
        Color::LightBlue => Color32::from_rgb(59, 142, 234),
        Color::LightMagenta => Color32::from_rgb(214, 112, 214),
        Color::LightCyan => Color32::from_rgb(41, 184, 219),
        Color::White => Color32::from_rgb(255, 255, 255),
        Color::Rgb(red, green, blue) => Color32::from_rgb(red, green, blue),
        Color::Indexed(index) => indexed_color(index),
    }
}

fn indexed_color(index: u8) -> Color32 {
    const ANSI: [(u8, u8, u8); 16] = [
        (0, 0, 0),
        (205, 49, 49),
        (13, 188, 121),
        (229, 229, 16),
        (36, 114, 200),
        (188, 63, 188),
        (17, 168, 205),
        (229, 229, 229),
        (102, 102, 102),
        (241, 76, 76),
        (35, 209, 139),
        (245, 245, 67),
        (59, 142, 234),
        (214, 112, 214),
        (41, 184, 219),
        (255, 255, 255),
    ];
    match index {
        0..=15 => {
            let (red, green, blue) = ANSI[index as usize];
            Color32::from_rgb(red, green, blue)
        }
        16..=231 => {
            let value = index - 16;
            let red = value / 36;
            let green = (value % 36) / 6;
            let blue = value % 6;
            let level = |component: u8| {
                if component == 0 {
                    0
                } else {
                    55 + component * 40
                }
            };
            Color32::from_rgb(level(red), level(green), level(blue))
        }
        232..=255 => {
            let level = 8 + (index - 232) * 10;
            Color32::from_gray(level)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn grid_size_is_bounded_and_handles_tiny_windows() {
        let metrics = CellMetrics {
            width: 8.4,
            height: 17.0,
        };
        assert_eq!(grid_size(Vec2::ZERO, metrics), (0, 0));
        assert_eq!(
            grid_size(Vec2::new(metrics.width - 0.1, metrics.height), metrics),
            (0, 1)
        );
        assert_eq!(
            grid_size(
                Vec2::new(metrics.width * 80.0, metrics.height * 24.0),
                metrics
            ),
            (80, 24)
        );
        assert_eq!(
            grid_size(Vec2::new(f32::INFINITY, f32::INFINITY), metrics),
            (u16::MAX, u16::MAX)
        );
    }

    #[test]
    fn pointer_coordinates_map_to_cells_at_any_cell_size() {
        for metrics in [
            CellMetrics {
                width: 8.4,
                height: 17.0,
            },
            CellMetrics {
                width: 13.125,
                height: 26.5,
            },
        ] {
            let geometry = GridGeometry {
                origin: Pos2::new(3.0, 5.0),
                metrics,
                size: (80, 24),
            };
            assert_eq!(geometry.cell_at(geometry.origin), Some((0, 0)));
            assert_eq!(
                geometry.cell_at(
                    geometry.origin + Vec2::new(metrics.width * 17.5, metrics.height * 9.25)
                ),
                Some((17, 9))
            );
            assert_eq!(geometry.cell_at(geometry.origin - Vec2::splat(0.1)), None);
        }
    }

    #[test]
    fn top_grid_border_drags_and_other_edges_resize() {
        let size = (80, 24);
        assert_eq!(chrome_hit((40, 0), size), Some(GridHit::Drag));
        assert_eq!(chrome_hit((0, 0), size), Some(GridHit::Drag));
        assert_eq!(
            chrome_hit((0, 12), size),
            Some(GridHit::Resize(ResizeDirection::West))
        );
        assert_eq!(
            chrome_hit((79, 23), size),
            Some(GridHit::Resize(ResizeDirection::SouthEast))
        );
        assert_eq!(chrome_hit((40, 12), size), None);
    }

    #[test]
    fn custom_fonts_keep_bundled_symbol_fallbacks() {
        let fonts = font_definitions();
        for primary in [REGULAR_FONT, BOLD_FONT] {
            let family = fonts
                .families
                .get(&FontFamily::Name(primary.into()))
                .unwrap();
            assert_eq!(family.first().map(String::as_str), Some(primary));
            assert!(family.iter().any(|font| font == "Ubuntu-Light"));
            assert!(family.iter().any(|font| font == "NotoEmoji-Regular"));
            assert!(family.iter().any(|font| font == "Hack"));
        }
    }

    #[test]
    fn colors_cover_reset_rgb_and_indexed_values() {
        assert_eq!(color_to_egui(Color::Reset, BACKGROUND), BACKGROUND);
        assert_eq!(
            color_to_egui(Color::Rgb(1, 2, 3), BACKGROUND),
            Color32::from_rgb(1, 2, 3)
        );
        assert_eq!(indexed_color(16), Color32::BLACK);
        assert_eq!(indexed_color(255), Color32::from_gray(238));
    }

    #[test]
    fn control_c_is_translated_without_printable_key_duplication() {
        let key = egui_key(egui::Key::C, egui::Modifiers::CTRL).unwrap();
        assert_eq!(key.code, KeyCode::Char('c'));
        assert!(key.modifiers.contains(KeyModifiers::CONTROL));
        assert!(egui_key(egui::Key::C, egui::Modifiers::NONE).is_none());
    }

    #[test]
    fn list_shortcuts_preserve_modifiers() {
        for (source, expected) in [
            (egui::Key::N, KeyCode::Char('n')),
            (egui::Key::R, KeyCode::Char('r')),
            (egui::Key::X, KeyCode::Char('x')),
        ] {
            let key = egui_key(source, egui::Modifiers::CTRL).unwrap();
            assert_eq!(key.code, expected);
            assert!(key.modifiers.contains(KeyModifiers::CONTROL));
        }
        let tab = egui_key(egui::Key::Tab, egui::Modifiers::SHIFT).unwrap();
        assert_eq!(tab.code, KeyCode::Tab);
        assert!(tab.modifiers.contains(KeyModifiers::SHIFT));
        assert_eq!(
            egui_key(egui::Key::F2, egui::Modifiers::NONE).unwrap().code,
            KeyCode::F(2)
        );
    }

    #[test]
    fn tab_rows_hit_the_corresponding_list() {
        let directory = tempfile::tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        app.lists.push(tui_kanban::model::TaskList::named("Work"));

        assert_eq!(grid_hit((1, 1), (80, 24), &app), GridHit::Tab(0));
        assert_eq!(grid_hit((8, 1), (80, 24), &app), GridHit::Tab(1));
    }
}
