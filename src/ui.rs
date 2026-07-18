use chrono::{Datelike, Local, NaiveDate};
use ratatui::{
    Frame,
    layout::{Alignment, Constraint, Direction, Layout, Margin, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, BorderType, Borders, Clear, Paragraph, Wrap},
};
use std::collections::HashSet;
use uuid::Uuid;

use crate::{
    app::{ANIMATION_DURATION, App, ListPromptKind, Overlay, PromptKind, ViewMode},
    model::{LongTitleDisplay, Status, Task},
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
// One content row followed by one blank row to separate the header from the list.
const HEADER_HEIGHT: u16 = 2;

pub fn render(frame: &mut Frame, app: &App) {
    let area = frame.area();
    frame.render_widget(Block::new().style(Style::new().bg(BG)), area);

    if area.width < 30 || area.height < 20 {
        render_too_small(frame, area);
        return;
    }

    let layout = Layout::vertical([
        Constraint::Length(HEADER_HEIGHT),
        Constraint::Min(5),
        Constraint::Length(2),
    ])
    .split(area);
    render_header(frame, app, layout[0]);
    match app.view {
        ViewMode::List => render_list(frame, app, layout[1]),
        ViewMode::Focus => render_focus(frame, app, layout[1]),
        ViewMode::Completed => render_completed(frame, app, layout[1]),
    }
    render_footer(frame, app, layout[2]);

    match &app.overlay {
        Overlay::None => {}
        Overlay::Help => render_help(frame, area),
        Overlay::Prompt {
            kind,
            input,
            cursor,
            daily,
        } => render_prompt(frame, *kind, input, *cursor, *daily, area),
        Overlay::ConfirmDelete => render_confirm(frame, area),
        Overlay::ListPrompt {
            kind,
            input,
            cursor,
        } => render_list_prompt(frame, *kind, input, *cursor, area),
        Overlay::ConfirmDeleteList => render_list_confirm(frame, app, area),
        Overlay::Settings { selected } => render_settings(frame, app, *selected, area),
    }
}

/// Returns the task occupying a rendered grid cell.
///
/// This mirrors the view layout and scrolling used by the renderer, giving
/// native front ends a resolution-independent hit-test without pixel guesses.
pub fn task_at(app: &App, area: Rect, column: u16, row: u16) -> Option<Uuid> {
    if area.width < 30
        || area.height < 20
        || column >= area.width
        || row >= area.height
        || app.overlay != Overlay::None
    {
        return None;
    }

    let body = Layout::vertical([
        Constraint::Length(HEADER_HEIGHT),
        Constraint::Min(5),
        Constraint::Length(2),
    ])
    .split(area)[1];
    let outer = body.inner(Margin::new(1, 0));
    let inner = Block::new().borders(Borders::ALL).inner(outer);
    if !inner.contains(ratatui::layout::Position::new(column, row)) {
        return None;
    }
    let visible_row = (row - inner.y) as usize;

    match app.view {
        ViewMode::List => list_task_at(app, inner, visible_row),
        ViewMode::Focus => app
            .current_list()
            .tasks
            .iter()
            .filter(|task| task.status == Status::Doing)
            .flat_map(|task| {
                std::iter::repeat_n(
                    task.id,
                    task_lines(app, task, inner.width.saturating_sub(3) as usize).len(),
                )
            })
            .nth(visible_row),
        ViewMode::Completed => {
            let entries = app.completion_entries();
            let selected_row = entries
                .iter()
                .position(|(task, _)| Some(task.id) == app.selected_task)
                .unwrap_or(0);
            let scroll = selected_row.saturating_sub(inner.height.saturating_sub(1) as usize);
            entries.get(scroll + visible_row).map(|(task, _)| task.id)
        }
    }
}

fn list_task_at(app: &App, inner: Rect, visible_row: usize) -> Option<Uuid> {
    let mut rows = Vec::new();
    for status in Status::LIST_ORDER {
        let tasks: Vec<&Task> = app
            .current_list()
            .tasks
            .iter()
            .filter(|task| task.status == status)
            .collect();
        rows.push(None); // status heading
        if tasks.is_empty() {
            rows.push(None); // empty-state message
        } else {
            for task in tasks {
                rows.extend(std::iter::repeat_n(
                    Some(task.id),
                    task_lines(app, task, inner.width.saturating_sub(3) as usize).len(),
                ));
            }
        }
        rows.push(None); // section spacing
    }

    let selected_line = rows
        .iter()
        .position(|id| *id == app.selected_task)
        .unwrap_or(0);
    let scroll = selected_line.saturating_sub(inner.height.saturating_sub(1) as usize);
    rows.get(scroll + visible_row).copied().flatten()
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let view = match app.view {
        ViewMode::List => "LIST VIEW",
        ViewMode::Focus => "DOING FOCUS",
        ViewMode::Completed => "COMPLETED",
    };
    let title = " FOCUS LIST ";
    let view = format!(" {view} ");
    let spacing = area
        .width
        .saturating_sub((title.chars().count() + view.chars().count()) as u16);
    let title_area = Rect::new(area.x, area.y, area.width, 1);
    frame.render_widget(
        Paragraph::new(Line::from(vec![
            Span::styled(title, Style::new().fg(BG).bg(VIOLET).bold()),
            Span::raw(" ".repeat(spacing as usize)),
            Span::styled(view, Style::new().fg(MUTED).bold()),
        ]))
        .style(Style::new().bg(BG)),
        title_area,
    );
    render_tabs(frame, app, Rect::new(area.x, area.y + 1, area.width, 1));
}

fn render_tabs(frame: &mut Frame, app: &App, area: Rect) {
    let mut spans = Vec::new();
    for (index, label) in tab_layout(app, area.width as usize) {
        let style = match index {
            Some(index) if index == app.current => Style::new().fg(BG).bg(VIOLET).bold(),
            Some(_) => Style::new().fg(MUTED).bg(PANEL),
            None => Style::new().fg(MUTED),
        };
        spans.push(Span::styled(label, style));
    }
    frame.render_widget(
        Paragraph::new(Line::from(spans)).style(Style::new().bg(BG)),
        area,
    );
}

pub fn tab_at(app: &App, width: u16, column: u16, row: u16) -> Option<usize> {
    if row != 1 || column >= width || app.overlay != Overlay::None {
        return None;
    }
    let mut start = 0usize;
    for (index, label) in tab_layout(app, width as usize) {
        let end = start + label.chars().count();
        if (start..end).contains(&(column as usize)) {
            return index;
        }
        start = end;
    }
    None
}

fn tab_layout(app: &App, width: usize) -> Vec<(Option<usize>, String)> {
    let labels: Vec<String> = app
        .lists
        .iter()
        .map(|list| format!(" {} ", list.name))
        .collect();
    let mut start = app.current;
    let mut used = labels[app.current].chars().count().min(width);
    while start > 0 {
        let candidate = labels[start - 1].chars().count();
        let indicator = usize::from(start - 1 > 0);
        if used + candidate + indicator > width {
            break;
        }
        start -= 1;
        used += candidate;
    }
    let left_hidden = start > 0;
    used += usize::from(left_hidden);
    let mut end = app.current + 1;
    while end < labels.len() {
        let candidate = labels[end].chars().count();
        let right_indicator = usize::from(end + 1 < labels.len());
        if used + candidate + right_indicator > width {
            break;
        }
        used += candidate;
        end += 1;
    }
    let right_hidden = end < labels.len();
    let mut visible = Vec::new();
    if left_hidden {
        visible.push((None, "‹".into()));
    }
    for (index, label) in labels.iter().enumerate().take(end).skip(start) {
        let reserved = usize::from(left_hidden) + usize::from(right_hidden);
        let available = width.saturating_sub(reserved);
        let label = truncate(label, available.max(1));
        visible.push((Some(index), label));
    }
    if right_hidden {
        visible.push((None, "›".into()));
    }
    visible
}

#[allow(dead_code)]
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
        let selected_line = tasks
            .iter()
            .take(selected_row)
            .map(|task| task_lines(app, task, inner.width.saturating_sub(2) as usize).len())
            .sum::<usize>();
        let start = selected_line.saturating_sub(available.saturating_sub(1));
        let lines: Vec<Line> = tasks
            .iter()
            .flat_map(|task| task_lines(app, task, inner.width.saturating_sub(2) as usize))
            .skip(start)
            .take(available)
            .collect();
        frame.render_widget(Paragraph::new(lines).style(Style::new().bg(PANEL)), inner);
    }
}

fn render_list(frame: &mut Frame, app: &App, area: Rect) {
    let outer = area.inner(Margin::new(1, 0));
    let block = Block::new()
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
                    .flat_map(|task| task_lines(app, task, inner.width.saturating_sub(3) as usize)),
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

fn render_focus(frame: &mut Frame, app: &App, area: Rect) {
    let outer = area.inner(Margin::new(1, 0));
    let block = Block::new()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(CYAN))
        .style(Style::new().bg(PANEL));
    let inner = block.inner(outer);
    frame.render_widget(block, outer);
    let tasks: Vec<&Task> = app
        .current_list()
        .tasks
        .iter()
        .filter(|task| task.status == Status::Doing)
        .collect();
    let lines: Vec<Line> = if tasks.is_empty() {
        vec![Line::styled(
            "  · no doing tasks ·",
            Style::new().fg(MUTED).italic(),
        )]
    } else {
        tasks
            .into_iter()
            .flat_map(|task| task_lines(app, task, inner.width.saturating_sub(3) as usize))
            .collect()
    };
    frame.render_widget(Paragraph::new(lines).style(Style::new().bg(PANEL)), inner);
}

fn render_completed(frame: &mut Frame, app: &App, area: Rect) {
    let outer = area.inner(Margin::new(1, 0));
    let block = Block::new()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(GREEN))
        .style(Style::new().bg(PANEL));
    let inner = block.inner(outer);
    frame.render_widget(block, outer);

    let entries = app.completion_entries();
    if entries.is_empty() {
        frame.render_widget(
            Paragraph::new("\n  No completed tasks yet — finish one with Space, then F.")
                .style(Style::new().fg(MUTED).italic().bg(PANEL)),
            inner,
        );
        return;
    }

    let lines: Vec<Line> = entries
        .iter()
        .map(|(task, completed_at)| {
            let completed = completed_at.with_timezone(&chrono::Local);
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
    let selected_row = entries
        .iter()
        .position(|(task, _)| Some(task.id) == app.selected_task)
        .unwrap_or(0);
    let scroll = selected_row.saturating_sub(inner.height.saturating_sub(1) as usize) as u16;
    frame.render_widget(
        Paragraph::new(lines)
            .scroll((scroll, 0))
            .style(Style::new().bg(PANEL)),
        inner,
    );
}

fn task_lines<'a>(app: &App, task: &'a Task, width: usize) -> Vec<Line<'a>> {
    let selected = Some(task.id) == app.selected_task;
    let animated = app.animation.as_ref().is_some_and(|animation| {
        animation.task_id == task.id && animation.started.elapsed() <= ANIMATION_DURATION
    });
    let prefix = if selected { " › " } else { " - " };
    let room = width.saturating_sub(prefix.chars().count());
    let titles = match app.config.long_title_display {
        LongTitleDisplay::Marquee => vec![display_task_title(&task.title, room, selected, app)],
        LongTitleDisplay::Wrap => wrap_task_title(&task.title, room),
    };
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
    titles
        .into_iter()
        .enumerate()
        .map(|(index, title)| {
            let line_prefix = if index == 0 { prefix } else { "   " };
            Line::styled(format!("{line_prefix}{title}"), style)
        })
        .collect()
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let top = if let Some(activity) = daily_activity_line(app, area.width as usize) {
        Line::styled(activity, Style::new().fg(GREEN).bold())
    } else if let Some(notice) = &app.notice {
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
        Line::styled(
            " SPACE armed — F advance, ↑↓ reorder ",
            Style::new().fg(AMBER).bold(),
        )
    } else {
        Line::styled("", Style::default())
    };
    let keys = Line::from(vec![
        Span::styled(" tab ", Style::new().fg(VIOLET).bold()),
        Span::styled("lists  ", Style::new().fg(MUTED)),
        Span::styled(" ↑↓ ", Style::new().fg(VIOLET).bold()),
        Span::styled("move  ", Style::new().fg(MUTED)),
        Span::styled("n ", Style::new().fg(VIOLET).bold()),
        Span::styled("new  ", Style::new().fg(MUTED)),
        Span::styled("space f ", Style::new().fg(VIOLET).bold()),
        Span::styled("advance  ", Style::new().fg(MUTED)),
        Span::styled("space ↑↓ ", Style::new().fg(VIOLET).bold()),
        Span::styled("sort  ", Style::new().fg(MUTED)),
        Span::styled("d ", Style::new().fg(VIOLET).bold()),
        Span::styled("duplicate  ", Style::new().fg(MUTED)),
        Span::styled("r ", Style::new().fg(VIOLET).bold()),
        Span::styled("revert  ", Style::new().fg(MUTED)),
        Span::styled("g ", Style::new().fg(VIOLET).bold()),
        Span::styled("settings  ", Style::new().fg(MUTED)),
        Span::styled("c ", Style::new().fg(VIOLET).bold()),
        Span::styled("doing  ", Style::new().fg(MUTED)),
        Span::styled("v ", Style::new().fg(VIOLET).bold()),
        Span::styled("completed  ", Style::new().fg(MUTED)),
        Span::styled("?", Style::new().fg(VIOLET).bold()),
    ]);
    frame.render_widget(
        Paragraph::new(vec![top, keys]).style(Style::new().bg(BG)),
        area,
    );
}

fn daily_activity_line(app: &App, width: usize) -> Option<String> {
    let task = app.selected()?;
    if !task.daily {
        return None;
    }
    let completed: std::collections::HashSet<_> = task
        .completion_history
        .iter()
        .map(|time| time.with_timezone(&chrono::Local).date_naive())
        .collect();
    let visible_days = width.saturating_sub(10).max(1);
    let today = chrono::Local::now().date_naive();
    let cells: String = (0..visible_days)
        .map(|offset| {
            if completed.contains(&(today - chrono::Duration::days(offset as i64))) {
                '■'
            } else {
                '·'
            }
        })
        .collect();
    Some(format!(" Daily: {cells}"))
}

fn render_help(frame: &mut Frame, area: Rect) {
    let popup = centered(area, 64, 76, 48, 18);
    frame.render_widget(Clear, popup);
    let block = modal_block(" HELP ");
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    let text = Text::from(vec![
        help_line("↑/↓ or j/k", "Move between tasks"),
        help_line("Space then f", "Advance task status"),
        help_line("Space then ↑/↓", "Move selected task within its status"),
        help_line("n / e / x", "New, edit, delete task"),
        help_line("Tab / Shift+Tab", "Switch task lists"),
        help_line("Ctrl+n", "Create a task list"),
        help_line("F2 / Ctrl+r", "Rename current task list"),
        help_line("Ctrl+x", "Delete current task list"),
        help_line("d", "Duplicate selected task"),
        help_line("r", "Revert completed task to Doing"),
        help_line("c", "Toggle Doing focus when work exists"),
        help_line("v", "Open or close completed history"),
        help_line("g", "Open settings"),
        help_line("s", "Toggle transition sound"),
        help_line("q", "Quit"),
        Line::raw(""),
        Line::styled(" Press Esc, ? or q to close", Style::new().fg(MUTED)),
    ]);
    frame.render_widget(Paragraph::new(text).wrap(Wrap { trim: true }), inner);
}

fn render_prompt(
    frame: &mut Frame,
    kind: PromptKind,
    input: &str,
    cursor: usize,
    daily: bool,
    area: Rect,
) {
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
        Paragraph::new(format!(" {}", input_with_cursor(input, cursor)))
            .wrap(Wrap { trim: false })
            .style(Style::new().fg(TEXT).bg(BG)),
        layout[0],
    );
    frame.render_widget(
        Paragraph::new(format!(
            " Enter save   Tab daily: {}   Esc cancel",
            if daily { "yes" } else { "no" }
        ))
        .wrap(Wrap { trim: true })
        .style(Style::new().fg(MUTED)),
        layout[1],
    );
}

fn render_list_prompt(
    frame: &mut Frame,
    kind: ListPromptKind,
    input: &str,
    cursor: usize,
    area: Rect,
) {
    let title = match kind {
        ListPromptKind::Add => " NEW LIST ",
        ListPromptKind::Rename => " RENAME LIST ",
    };
    let popup = centered(area, 58, 30, 36, 7);
    frame.render_widget(Clear, popup);
    let block = modal_block(title);
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    frame.render_widget(
        Paragraph::new(format!(
            " {}\n\n Enter save   Esc cancel",
            input_with_cursor(input, cursor)
        ))
        .style(Style::new().fg(TEXT).bg(BG)),
        inner,
    );
}

fn render_settings(frame: &mut Frame, app: &App, selected: usize, area: Rect) {
    let popup = centered(area, 56, 38, 44, 10);
    frame.render_widget(Clear, popup);
    let block = modal_block(" SETTINGS ");
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    let selected_style = Style::new().fg(BG).bg(VIOLET).bold();
    let normal_style = Style::new().fg(TEXT);
    let speed_style = if selected == 0 {
        selected_style
    } else {
        normal_style
    };
    let display_style = if selected == 1 {
        selected_style
    } else {
        normal_style
    };
    let font_size_style = if selected == 2 {
        selected_style
    } else {
        normal_style
    };
    let text = Text::from(vec![
        Line::styled(" Use ←/→ or h/l to adjust values", Style::new().fg(MUTED)),
        Line::raw(""),
        Line::from(vec![
            Span::styled(" Marquee speed ", speed_style),
            Span::styled(format!("{} ms", app.config.marquee_speed_ms), speed_style),
        ]),
        Line::from(vec![
            Span::styled(" Long titles  ", display_style),
            Span::styled(app.config.long_title_display.label(), display_style),
        ]),
        Line::from(vec![
            Span::styled(" Native font  ", font_size_style),
            Span::styled(
                format!("{} pt", app.config.native_font_size),
                font_size_style,
            ),
        ]),
        Line::raw(""),
        Line::styled(
            " Lower speed is faster. Font size affects the native app.",
            Style::new().fg(MUTED),
        ),
        Line::styled(" Esc or g close", Style::new().fg(MUTED)),
    ]);
    frame.render_widget(Paragraph::new(text).style(Style::new().bg(PANEL)), inner);
}

#[allow(dead_code)]
fn render_activity(frame: &mut Frame, app: &App, task_id: uuid::Uuid, area: Rect) {
    let Some(task) = app
        .current_list()
        .tasks
        .iter()
        .find(|task| task.id == task_id)
    else {
        return;
    };
    let popup = centered(area, 78, 66, 64, 18);
    frame.render_widget(Clear, popup);
    let block = modal_block(" DAILY ACTIVITY ");
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    let today = Local::now().date_naive();
    let (previous_year, previous_month) = if today.month() == 1 {
        (today.year() - 1, 12)
    } else {
        (today.year(), today.month() - 1)
    };
    let months = Layout::horizontal([Constraint::Ratio(1, 2), Constraint::Ratio(1, 2)])
        .spacing(2)
        .split(inner);
    render_month_activity(frame, task, previous_year, previous_month, months[0]);
    render_month_activity(frame, task, today.year(), today.month(), months[1]);
    frame.render_widget(
        Paragraph::new(" Esc or o close   ■ completed daily task   · no completion")
            .style(Style::new().fg(MUTED).bg(PANEL)),
        Rect::new(inner.x, inner.bottom().saturating_sub(1), inner.width, 1),
    );
}

#[allow(dead_code)]
fn render_month_activity(frame: &mut Frame, task: &Task, year: i32, month: u32, area: Rect) {
    let completed: HashSet<NaiveDate> = task
        .completion_history
        .iter()
        .map(|time| time.with_timezone(&Local).date_naive())
        .collect();
    let Some(first) = NaiveDate::from_ymd_opt(year, month, 1) else {
        return;
    };
    let next_month = if month == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1)
    } else {
        NaiveDate::from_ymd_opt(year, month + 1, 1)
    }
    .expect("valid next month");
    let days = (next_month - first).num_days() as u32;
    let mut lines = vec![
        Line::styled(
            first.format(" %B %Y").to_string(),
            Style::new().fg(VIOLET).bold(),
        ),
        Line::styled(" S  M  T  W  T  F  S", Style::new().fg(MUTED)),
    ];
    let mut cells = vec![None; first.weekday().num_days_from_sunday() as usize];
    for day in 1..=days {
        cells.push(NaiveDate::from_ymd_opt(year, month, day));
    }
    while !cells.len().is_multiple_of(7) {
        cells.push(None);
    }
    for week in cells.chunks(7) {
        let spans: Vec<Span> = week
            .iter()
            .map(|date| match date {
                Some(date) if completed.contains(date) => {
                    Span::styled(" ■ ", Style::new().fg(GREEN).bold())
                }
                Some(_) => Span::styled(" · ", Style::new().fg(MUTED)),
                None => Span::raw("   "),
            })
            .collect();
        lines.push(Line::from(spans));
    }
    frame.render_widget(Paragraph::new(lines).style(Style::new().bg(PANEL)), area);
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

fn render_list_confirm(frame: &mut Frame, app: &App, area: Rect) {
    let popup = centered(area, 54, 22, 36, 7);
    frame.render_widget(Clear, popup);
    let block = Block::new()
        .title(Line::styled(" DELETE LIST? ", Style::new().fg(RED).bold()))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::new().fg(RED))
        .style(Style::new().bg(PANEL));
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    frame.render_widget(
        Paragraph::new(format!(
            " Delete {:?} and all its tasks?\n This cannot be undone.\n\n y delete    n / Esc cancel",
            app.current_list().name
        ))
        .style(Style::new().fg(TEXT)),
        inner,
    );
}

fn render_too_small(frame: &mut Frame, area: Rect) {
    frame.render_widget(
        Paragraph::new("FOCUS LIST\n\nTerminal too small\nResize to at least 30 × 20")
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

fn wrap_task_title(value: &str, width: usize) -> Vec<String> {
    if width == 0 {
        return vec![String::new()];
    }
    value
        .replace('\r', "")
        .split('\n')
        .flat_map(|line| {
            let characters: Vec<char> = line.chars().collect();
            if characters.is_empty() {
                vec![String::new()]
            } else {
                characters
                    .chunks(width)
                    .map(|chunk| chunk.iter().collect())
                    .collect()
            }
        })
        .collect()
}

fn input_with_cursor(input: &str, cursor: usize) -> String {
    let mut rendered = String::with_capacity(input.len() + 3);
    rendered.push_str(&input[..cursor]);
    if let Some(character) = input[cursor..].chars().next() {
        rendered.push('█');
        rendered.push_str(&input[cursor + character.len_utf8()..]);
    } else {
        rendered.push('█');
    }
    rendered
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
    fn task_hit_testing_tracks_rows_and_wrapping() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        app.config.long_title_display = LongTitleDisplay::Wrap;
        let task = crate::model::Task::new("A title long enough to wrap across several rows");
        let task_id = task.id;
        app.current_list_mut().tasks.push(task);

        let area = Rect::new(0, 0, 30, 20);
        // The empty Doing section occupies rows 3..5, the Pending heading is
        // row 6, and this task begins on row 7. Continuations are clickable.
        assert_eq!(task_at(&app, area, 4, 7), Some(task_id));
        assert_eq!(task_at(&app, area, 4, 8), Some(task_id));
        assert_eq!(task_at(&app, area, 4, 6), None);

        app.overlay = Overlay::Help;
        assert_eq!(task_at(&app, area, 4, 7), None);
    }

    #[test]
    fn both_views_render() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        let mut task = crate::model::Task::new("Visible task");
        task.status = Status::Done;
        task.completed_at = Some(task.updated_at);
        app.current_list_mut().tasks.push(task);
        let mut doing = crate::model::Task::new("Visible task");
        doing.status = Status::Doing;
        app.current_list_mut().tasks.push(doing);
        for view in [ViewMode::List, ViewMode::Focus, ViewMode::Completed] {
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
    fn tab_bar_keeps_the_active_list_visible_when_it_overflows() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        for name in ["Personal", "Work", "Planning", "Archive"] {
            app.lists.push(crate::model::TaskList::named(name));
        }
        app.current = app.lists.len() - 1;
        let backend = TestBackend::new(18, 1);
        let mut terminal = Terminal::new(backend).unwrap();
        terminal
            .draw(|frame| render_tabs(frame, &app, frame.area()))
            .unwrap();
        let rendered = terminal
            .backend()
            .buffer()
            .content
            .iter()
            .map(|cell| cell.symbol())
            .collect::<String>();
        assert!(rendered.contains("Archive"));
        assert!(rendered.contains('‹'));
    }

    #[test]
    fn visible_tabs_can_be_hit_tested() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        app.lists.push(crate::model::TaskList::named("Work"));

        assert_eq!(tab_at(&app, 40, 1, 1), Some(0));
        assert_eq!(tab_at(&app, 40, 8, 1), Some(1));
        assert_eq!(tab_at(&app, 40, 8, 0), None);
        app.overlay = Overlay::Help;
        assert_eq!(tab_at(&app, 40, 1, 1), None);
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

    #[test]
    fn wrapped_titles_preserve_manual_lines() {
        assert_eq!(wrap_task_title("abcde\nf", 3), vec!["abc", "de", "f"]);
    }

    #[test]
    fn selected_daily_task_shows_recent_activity_in_footer() {
        let directory = tempdir().unwrap();
        let mut app = App::load(directory.path().to_path_buf()).unwrap();
        let mut task = crate::model::Task::new("Daily");
        task.daily = true;
        task.completion_history.push(chrono::Utc::now());
        app.selected_task = Some(task.id);
        app.current_list_mut().tasks.push(task);
        assert!(daily_activity_line(&app, 40).is_some_and(|line| line.contains('■')));
    }
}
