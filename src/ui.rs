use ratatui::{
    Frame,
    layout::{Alignment, Constraint, Direction, Layout, Margin, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, BorderType, Borders, Clear, Paragraph, Wrap},
};

use crate::{
    app::{ANIMATION_DURATION, App, Overlay, PromptKind, ViewMode},
    model::{Status, Task},
};

const BG: Color = Color::Rgb(13, 15, 24);
const PANEL: Color = Color::Rgb(22, 25, 38);
const TEXT: Color = Color::Rgb(221, 224, 235);
const MUTED: Color = Color::Rgb(118, 124, 148);
const VIOLET: Color = Color::Rgb(183, 148, 244);
const AMBER: Color = Color::Rgb(249, 191, 96);
const CYAN: Color = Color::Rgb(93, 211, 220);
const GREEN: Color = Color::Rgb(125, 207, 145);
const RED: Color = Color::Rgb(244, 112, 122);

pub fn render(frame: &mut Frame, app: &App) {
    let area = frame.area();
    frame.render_widget(Block::new().style(Style::new().bg(BG)), area);

    if area.width < 50 || area.height < 12 {
        render_too_small(frame, area);
        return;
    }

    let layout = Layout::vertical([
        Constraint::Length(3),
        Constraint::Min(5),
        Constraint::Length(2),
    ])
    .split(area);
    render_header(frame, app, layout[0]);
    match app.view {
        ViewMode::Kanban => render_kanban(frame, app, layout[1]),
        ViewMode::List => render_list(frame, app, layout[1]),
        ViewMode::Completed => render_completed(frame, app, layout[1]),
    }
    render_footer(frame, app, layout[2]);

    match &app.overlay {
        Overlay::None => {}
        Overlay::Help => render_help(frame, area),
        Overlay::Prompt { kind, input } => render_prompt(frame, *kind, input, area),
        Overlay::ConfirmDelete => render_confirm(frame, area),
        Overlay::Settings { selected } => render_settings(frame, app, *selected, area),
    }
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let list = app.current_list();
    let counts = |status| {
        list.tasks
            .iter()
            .filter(|task| task.status == status)
            .count()
    };
    let title = Line::from(vec![
        Span::styled("  KANBAN ", Style::new().fg(BG).bg(VIOLET).bold()),
        Span::styled(format!("  {}  ", list.name), Style::new().fg(TEXT).bold()),
    ]);
    let view = match app.view {
        ViewMode::Kanban => "columns",
        ViewMode::List => "list",
        ViewMode::Completed => "completed",
    };
    let summary = Line::from(vec![
        Span::styled(
            format!("  ● {} ", counts(Status::Doing)),
            Style::new().fg(CYAN),
        ),
        Span::styled(
            format!("◌ {} ", counts(Status::Pending)),
            Style::new().fg(AMBER),
        ),
        Span::styled(
            format!("✓ {}", counts(Status::Done)),
            Style::new().fg(GREEN),
        ),
        Span::styled(format!("   {view} view"), Style::new().fg(MUTED)),
    ]);
    frame.render_widget(
        Paragraph::new(vec![title, summary]).style(Style::new().bg(BG)),
        area,
    );
}

fn render_kanban(frame: &mut Frame, app: &App, area: Rect) {
    let columns = Layout::horizontal([
        Constraint::Ratio(1, 3),
        Constraint::Ratio(1, 3),
        Constraint::Ratio(1, 3),
    ])
    .spacing(1)
    .split(area.inner(Margin::new(1, 0)));

    for (column, status) in columns.iter().zip(Status::ALL) {
        let tasks: Vec<&Task> = app
            .current_list()
            .tasks
            .iter()
            .filter(|task| task.status == status)
            .collect();
        let title = format!(
            " {}  {} ",
            status_icon(status),
            status.label().to_uppercase()
        );
        let block = Block::new()
            .title(Line::styled(
                title,
                Style::new().fg(status_color(status)).bold(),
            ))
            .borders(Borders::ALL)
            .border_type(BorderType::Rounded)
            .border_style(Style::new().fg(status_color(status)))
            .style(Style::new().bg(PANEL));
        let inner = block.inner(*column);
        frame.render_widget(block, *column);

        if tasks.is_empty() {
            frame.render_widget(
                Paragraph::new("  · no tasks ·")
                    .alignment(Alignment::Center)
                    .style(Style::new().fg(MUTED).italic()),
                inner,
            );
            continue;
        }

        let available = inner.height as usize;
        let selected_row = tasks
            .iter()
            .position(|task| Some(task.id) == app.selected_task)
            .unwrap_or(0);
        let start = selected_row.saturating_sub(available.saturating_sub(1));
        let lines: Vec<Line> = tasks
            .iter()
            .skip(start)
            .take(available)
            .map(|task| task_line(app, task, inner.width.saturating_sub(2) as usize))
            .collect();
        frame.render_widget(Paragraph::new(lines).style(Style::new().bg(PANEL)), inner);
    }
}

fn render_list(frame: &mut Frame, app: &App, area: Rect) {
    let outer = area.inner(Margin::new(1, 0));
    let block = Block::new()
        .title(Line::styled(" FOCUS LIST ", Style::new().fg(VIOLET).bold()))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(VIOLET))
        .style(Style::new().bg(PANEL));
    let inner = block.inner(outer);
    frame.render_widget(block, outer);

    let mut lines = Vec::new();
    for status in Status::LIST_ORDER {
        let tasks: Vec<&Task> = app
            .current_list()
            .tasks
            .iter()
            .filter(|task| task.status == status)
            .collect();
        lines.push(Line::from(vec![
            Span::styled(
                format!(
                    " {} {} ",
                    status_icon(status),
                    status.label().to_uppercase()
                ),
                Style::new().fg(status_color(status)).bold(),
            ),
            Span::styled(format!("({})", tasks.len()), Style::new().fg(MUTED)),
        ]));
        if tasks.is_empty() {
            lines.push(Line::styled("    · empty", Style::new().fg(MUTED).italic()));
        } else {
            lines.extend(
                tasks
                    .into_iter()
                    .map(|task| task_line(app, task, inner.width.saturating_sub(3) as usize)),
            );
        }
        lines.push(Line::raw(""));
    }

    let selected_line = lines
        .iter()
        .position(|line| line.spans.iter().any(|span| span.style.bg == Some(VIOLET)))
        .unwrap_or(0);
    let scroll = selected_line.saturating_sub(inner.height.saturating_sub(1) as usize) as u16;
    frame.render_widget(
        Paragraph::new(lines)
            .scroll((scroll, 0))
            .style(Style::new().bg(PANEL)),
        inner,
    );
}

fn render_completed(frame: &mut Frame, app: &App, area: Rect) {
    let outer = area.inner(Margin::new(1, 0));
    let block = Block::new()
        .title(Line::styled(
            " COMPLETED · NEWEST FIRST ",
            Style::new().fg(GREEN).bold(),
        ))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(GREEN))
        .style(Style::new().bg(PANEL));
    let inner = block.inner(outer);
    frame.render_widget(block, outer);

    let tasks = app.completed_tasks();
    if tasks.is_empty() {
        frame.render_widget(
            Paragraph::new("\n  No completed tasks yet — finish one with Space, then F.")
                .style(Style::new().fg(MUTED).italic().bg(PANEL)),
            inner,
        );
        return;
    }

    let lines: Vec<Line> = tasks
        .iter()
        .map(|task| {
            let completed = task
                .completed_at
                .unwrap_or(task.updated_at)
                .with_timezone(&chrono::Local);
            let stamp = completed.format("%Y-%m-%d  %H:%M");
            let selected = Some(task.id) == app.selected_task;
            let title_width = inner.width.saturating_sub(22) as usize;
            let selected_bg = if selected { VIOLET } else { PANEL };
            let title_style = if selected {
                Style::new().fg(BG).bg(VIOLET).bold()
            } else {
                Style::new().fg(MUTED).add_modifier(Modifier::CROSSED_OUT)
            };
            Line::from(vec![
                Span::styled(" ✓  ", Style::new().fg(GREEN).bg(selected_bg).bold()),
                Span::styled(
                    format!(
                        "{:<width$}",
                        display_task_title(&task.title, title_width, selected, app),
                        width = title_width
                    ),
                    title_style,
                ),
                Span::styled(
                    format!("  {stamp}"),
                    if selected {
                        Style::new().fg(BG).bg(VIOLET)
                    } else {
                        Style::new().fg(MUTED)
                    },
                ),
            ])
        })
        .collect();
    let selected_row = tasks
        .iter()
        .position(|task| Some(task.id) == app.selected_task)
        .unwrap_or(0);
    let scroll = selected_row.saturating_sub(inner.height.saturating_sub(1) as usize) as u16;
    frame.render_widget(
        Paragraph::new(lines)
            .scroll((scroll, 0))
            .style(Style::new().bg(PANEL)),
        inner,
    );
}

fn task_line<'a>(app: &App, task: &'a Task, width: usize) -> Line<'a> {
    let selected = Some(task.id) == app.selected_task;
    let animated = app.animation.as_ref().is_some_and(|animation| {
        animation.task_id == task.id && animation.started.elapsed() <= ANIMATION_DURATION
    });
    let prefix = if selected { " › " } else { "   " };
    let room = width.saturating_sub(prefix.chars().count());
    let title = display_task_title(&task.title, room, selected, app);
    let mut style = Style::new().fg(if task.status == Status::Done {
        MUTED
    } else {
        TEXT
    });
    if task.status == Status::Done {
        style = style.add_modifier(Modifier::CROSSED_OUT);
    }
    if selected {
        style = style.fg(BG).bg(VIOLET).bold();
    }
    if animated {
        let animation = app.animation.as_ref().expect("checked above");
        let progress = (animation.started.elapsed().as_secs_f32()
            / ANIMATION_DURATION.as_secs_f32())
        .clamp(0.0, 1.0);
        let pulse = 1.0 - (progress * 2.0 - 1.0).abs();
        style = style
            .fg(BG)
            .bg(blend(VIOLET, status_color(task.status), pulse))
            .bold();
    }
    Line::styled(format!("{prefix}{title}"), style)
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let top = if let Some(notice) = &app.notice {
        Line::styled(
            format!(
                " {} ",
                truncate(&notice.text, area.width.saturating_sub(2) as usize)
            ),
            Style::new()
                .fg(if notice.error { RED } else { GREEN })
                .bold(),
        )
    } else if let Some(animation) = &app.animation {
        let elapsed = animation.started.elapsed().as_millis();
        let sparkle = match (elapsed / 55) % 4 {
            0 => "✦",
            1 => "✧",
            2 => "·",
            _ => "✧",
        };
        Line::styled(
            format!(
                " {sparkle} {}  →  {} {sparkle}",
                animation.from.label(),
                animation.to.label()
            ),
            Style::new().fg(status_color(animation.to)).bold(),
        )
    } else if app.chord_started.is_some() {
        Line::styled(" SPACE armed — press F ", Style::new().fg(AMBER).bold())
    } else {
        Line::styled("", Style::default())
    };
    let keys = Line::from(vec![
        Span::styled(" ↑↓ ", Style::new().fg(VIOLET).bold()),
        Span::styled("move  ", Style::new().fg(MUTED)),
        Span::styled("n ", Style::new().fg(VIOLET).bold()),
        Span::styled("new  ", Style::new().fg(MUTED)),
        Span::styled("space f ", Style::new().fg(VIOLET).bold()),
        Span::styled("advance  ", Style::new().fg(MUTED)),
        Span::styled("d ", Style::new().fg(VIOLET).bold()),
        Span::styled("duplicate  ", Style::new().fg(MUTED)),
        Span::styled("r ", Style::new().fg(VIOLET).bold()),
        Span::styled("revert  ", Style::new().fg(MUTED)),
        Span::styled("g ", Style::new().fg(VIOLET).bold()),
        Span::styled("settings  ", Style::new().fg(MUTED)),
        Span::styled("?", Style::new().fg(VIOLET).bold()),
    ]);
    frame.render_widget(
        Paragraph::new(vec![top, keys]).style(Style::new().bg(BG)),
        area,
    );
}

fn render_help(frame: &mut Frame, area: Rect) {
    let popup = centered(area, 64, 76, 48, 18);
    frame.render_widget(Clear, popup);
    let block = modal_block(" HELP ");
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    let text = Text::from(vec![
        help_line("↑/↓ or j/k", "Move between tasks"),
        help_line("←/→ or h/l", "Move between columns"),
        help_line("Space then f", "Advance task status"),
        help_line("n / e / x", "New, edit, delete task"),
        help_line("d", "Duplicate selected task"),
        help_line("r", "Revert completed task to Doing"),
        help_line("c", "Cycle columns, list, completed"),
        help_line("g", "Open settings"),
        help_line("s", "Toggle transition sound"),
        help_line("q", "Quit"),
        Line::raw(""),
        Line::styled(" Press Esc, ? or q to close", Style::new().fg(MUTED)),
    ]);
    frame.render_widget(Paragraph::new(text).wrap(Wrap { trim: true }), inner);
}

fn render_prompt(frame: &mut Frame, kind: PromptKind, input: &str, area: Rect) {
    let title = match kind {
        PromptKind::AddTask => " NEW TASK ",
        PromptKind::EditTask => " EDIT TASK ",
    };
    let popup = centered(area, 62, 50, 36, 10);
    frame.render_widget(Clear, popup);
    let block = modal_block(title);
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    let layout = Layout::vertical([Constraint::Min(3), Constraint::Length(2)]).split(inner);
    frame.render_widget(
        Paragraph::new(format!(" {input}_"))
            .wrap(Wrap { trim: false })
            .style(Style::new().fg(TEXT).bg(BG)),
        layout[0],
    );
    frame.render_widget(
        Paragraph::new(" Enter save   Shift+Enter new line   Esc cancel")
            .wrap(Wrap { trim: true })
            .style(Style::new().fg(MUTED)),
        layout[1],
    );
}

fn render_settings(frame: &mut Frame, app: &App, selected: usize, area: Rect) {
    let popup = centered(area, 56, 32, 44, 8);
    frame.render_widget(Clear, popup);
    let block = modal_block(" SETTINGS ");
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    let selected_style = Style::new().fg(BG).bg(VIOLET).bold();
    let normal_style = Style::new().fg(TEXT);
    let value_style = if selected == 0 { selected_style } else { normal_style };
    let text = Text::from(vec![
        Line::styled(" Use ←/→ or h/l to adjust values", Style::new().fg(MUTED)),
        Line::raw(""),
        Line::from(vec![
            Span::styled(" Marquee speed ", value_style),
            Span::styled(
                format!("{} ms", app.config.marquee_speed_ms),
                value_style,
            ),
        ]),
        Line::raw(""),
        Line::styled(" Lower is faster. Range: 50–1000 ms", Style::new().fg(MUTED)),
        Line::styled(" Esc or g close", Style::new().fg(MUTED)),
    ]);
    frame.render_widget(Paragraph::new(text).style(Style::new().bg(PANEL)), inner);
}

fn render_confirm(frame: &mut Frame, area: Rect) {
    let popup = centered(area, 50, 20, 32, 6);
    frame.render_widget(Clear, popup);
    let block = Block::new()
        .title(Line::styled(" DELETE TASK? ", Style::new().fg(RED).bold()))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(RED))
        .style(Style::new().bg(PANEL));
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    frame.render_widget(
        Paragraph::new(" This cannot be undone.\n\n y delete    n / Esc cancel")
            .style(Style::new().fg(TEXT)),
        inner,
    );
}

fn render_too_small(frame: &mut Frame, area: Rect) {
    frame.render_widget(
        Paragraph::new("KANBAN\n\nTerminal too small\nResize to at least 50 × 12")
            .alignment(Alignment::Center)
            .style(Style::new().fg(VIOLET).bg(BG).bold()),
        area,
    );
}

fn modal_block<'a>(title: &'a str) -> Block<'a> {
    Block::new()
        .title(Line::styled(title, Style::new().fg(VIOLET).bold()))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(VIOLET))
        .style(Style::new().bg(PANEL))
}

fn help_line<'a>(key: &'a str, description: &'a str) -> Line<'a> {
    Line::from(vec![
        Span::styled(format!(" {key:<18}"), Style::new().fg(VIOLET).bold()),
        Span::styled(description, Style::new().fg(TEXT)),
    ])
}

fn centered(area: Rect, percent_x: u16, percent_y: u16, min_width: u16, min_height: u16) -> Rect {
    let width = (area.width * percent_x / 100)
        .max(min_width)
        .min(area.width);
    let height = (area.height * percent_y / 100)
        .max(min_height)
        .min(area.height);
    let vertical = Layout::vertical([
        Constraint::Length(area.height.saturating_sub(height) / 2),
        Constraint::Length(height),
        Constraint::Min(0),
    ])
    .split(area);
    Layout::new(
        Direction::Horizontal,
        [
            Constraint::Length(area.width.saturating_sub(width) / 2),
            Constraint::Length(width),
            Constraint::Min(0),
        ],
    )
    .split(vertical[1])[1]
}

fn truncate(value: &str, width: usize) -> String {
    if value.chars().count() <= width {
        return value.to_owned();
    }
    if width <= 1 {
        return "…".chars().take(width).collect();
    }
    format!("{}…", value.chars().take(width - 1).collect::<String>())
}

fn marquee(value: &str, width: usize, app: &App) -> String {
    let title = value.replace(['\n', '\r'], " ");
    let characters: Vec<char> = title.chars().collect();
    if characters.len() <= width {
        return title;
    }
    if width == 0 {
        return String::new();
    }

    let mut looped = characters;
    looped.extend("   •   ".chars());
    let offset = (app.started.elapsed().as_millis() / app.config.marquee_speed_ms as u128) as usize
        % looped.len();
    looped
        .iter()
        .copied()
        .cycle()
        .skip(offset)
        .take(width)
        .collect()
}

fn display_task_title(value: &str, width: usize, selected: bool, app: &App) -> String {
    if selected {
        marquee(value, width, app)
    } else {
        truncate(&value.replace(['\n', '\r'], " "), width)
    }
}

fn status_color(status: Status) -> Color {
    match status {
        Status::Pending => AMBER,
        Status::Doing => CYAN,
        Status::Done => GREEN,
    }
}

fn status_icon(status: Status) -> &'static str {
    match status {
        Status::Pending => "◌",
        Status::Doing => "●",
        Status::Done => "✓",
    }
}

fn blend(from: Color, to: Color, amount: f32) -> Color {
    let (Color::Rgb(from_r, from_g, from_b), Color::Rgb(to_r, to_g, to_b)) = (from, to) else {
        return to;
    };
    let channel =
        |start: u8, end: u8| (start as f32 + (end as f32 - start as f32) * amount).round() as u8;
    Color::Rgb(
        channel(from_r, to_r),
        channel(from_g, to_g),
        channel(from_b, to_b),
    )
}

#[cfg(test)]
mod tests {
    use ratatui::{Terminal, backend::TestBackend};
    use tempfile::tempdir;

    use super::*;

    #[test]
    fn both_views_render() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        let mut task = crate::model::Task::new("Visible task");
        task.status = Status::Done;
        task.completed_at = Some(task.updated_at);
        app.current_list_mut().tasks.push(task);
        for view in [ViewMode::Kanban, ViewMode::List, ViewMode::Completed] {
            app.view = view;
            let backend = TestBackend::new(100, 28);
            let mut terminal = Terminal::new(backend).unwrap();
            terminal.draw(|frame| render(frame, &app)).unwrap();
            let rendered = terminal
                .backend()
                .buffer()
                .content
                .iter()
                .map(|cell| cell.symbol())
                .collect::<String>();
            assert!(rendered.contains("Visible task"));
        }
    }

    #[test]
    fn small_terminal_has_fallback() {
        let directory = tempdir().unwrap();
        let app = App::load(directory.path().to_path_buf()).unwrap();
        let backend = TestBackend::new(40, 10);
        let mut terminal = Terminal::new(backend).unwrap();
        terminal.draw(|frame| render(frame, &app)).unwrap();
        let rendered = terminal
            .backend()
            .buffer()
            .content
            .iter()
            .map(|cell| cell.symbol())
            .collect::<String>();
        assert!(rendered.contains("Terminal too small"));
    }

    #[test]
    fn marquee_scrolls_titles_that_do_not_fit() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        app.started = std::time::Instant::now() - std::time::Duration::from_millis(180);
        let rendered = marquee("A task title that is too long", 8, &app);
        assert_eq!(rendered.chars().count(), 8);
        assert_ne!(rendered, "A task t");
    }

    #[test]
    fn unselected_long_titles_do_not_scroll() {
        let directory = tempdir().unwrap();
        let app = App::load(directory.path().to_path_buf()).unwrap();
        assert_eq!(
            display_task_title("A task title that is too long", 8, false, &app),
            "A task …"
        );
    }
}
