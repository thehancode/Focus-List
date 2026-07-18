# tui-kanban

A small, colorful terminal task list with a main list, Doing focus, and completed history.

## Run

```sh
cargo run --release
```

The app saves everything immediately in one human-readable JSON file:
`~/.local/share/tui-kanban/tasklists/tasklist.json` (or
`$XDG_DATA_HOME/tui-kanban/tasklists/tasklist.json` when `XDG_DATA_HOME` is set).
Settings are stored beside it in `config/settings.json`; the default is:

```json
{
  "marquee_speed_ms": 180,
  "long_title_display": "marquee"
}
```

## Keys

| Key | Action |
| --- | --- |
| `↑`/`↓`, `j`/`k` | Select task |
| `Space`, then `f` | Pending → Doing → Done → Pending |
| `Space`, then `↑`/`↓` | Move the selected task within its current status group |
| `n`, `e`, `x` | Create, edit, or delete a task |
| `d` | Duplicate the selected task (opens a prefilled new-task prompt) |
| `r` | Revert a completed task to Doing |
| `c` | Toggle Doing-only focus mode |
| `v` | Open or close completed history |
| `s` | Toggle the terminal bell |
| `g` | Open settings (adjust marquee speed and title display) |
| `?` | Show all shortcuts |
| `q`, `Ctrl+C` | Quit |

The terminal bell is enabled by default. Terminals configured to suppress bells will still show the animated status-change feedback.
The selected long task title scrolls continuously in the list by default.
Use Settings to switch long titles to wrapped rows instead. New and edited task titles wrap
in the editor. Use `Enter` to save, and the arrow keys, Home/End, Backspace, and Delete to
edit anywhere in the title.

Press `Tab` while creating or editing a task to toggle its **daily** status. A daily task
resets to Pending on the next local calendar day. Every daily completion is retained in the
completed view. While a daily task is selected, the footer shows its recent history: the
leftmost character is today, followed by yesterday and earlier days.
