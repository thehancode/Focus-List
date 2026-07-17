mod app;
mod model;
mod storage;
mod ui;

use std::{
    env, panic,
    path::PathBuf,
    time::{Duration, Instant},
};

use anyhow::{Context, Result};
use app::App;
use ratatui::{
    DefaultTerminal,
    crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers},
};

fn main() -> Result<()> {
    install_panic_hook();
    let root = tasklists_dir()?;
    let mut app = App::load(root)?;
    ratatui::run(|terminal| run(terminal, &mut app)).context("terminal error")?;
    Ok(())
}

fn tasklists_dir() -> Result<PathBuf> {
    let data_home = env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .or_else(|| env::var_os("HOME").map(|home| PathBuf::from(home).join(".local/share")))
        .context("could not determine the user data directory")?;
    Ok(data_home.join("tui-kanban/tasklists"))
}

fn run(terminal: &mut DefaultTerminal, app: &mut App) -> std::io::Result<()> {
    const FRAME_TIME: Duration = Duration::from_millis(33);
    while !app.should_quit {
        let now = Instant::now();
        app.tick(now);
        terminal.draw(|frame| ui::render(frame, app))?;

        if event::poll(FRAME_TIME)?
            && let Event::Key(key) = event::read()?
            && matches!(key.kind, KeyEventKind::Press | KeyEventKind::Repeat)
        {
            if key.code == KeyCode::Char('c') && key.modifiers.contains(KeyModifiers::CONTROL) {
                app.should_quit = true;
            } else {
                app.handle_key(key, Instant::now());
            }
        }
    }
    Ok(())
}

fn install_panic_hook() {
    let original = panic::take_hook();
    panic::set_hook(Box::new(move |information| {
        ratatui::restore();
        original(information);
    }));
}
