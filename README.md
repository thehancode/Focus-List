# tui-kanban

A small, colorful terminal task list with Kanban columns, a focus-list view, and a completed-history view.

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
  "marquee_speed_ms": 180
}
```

## Keys

| Key | Action |
| --- | --- |
| `↑`/`↓`, `j`/`k` | Select task |
| `←`/`→`, `h`/`l` | Move between Kanban columns |
| `Space`, then `f` | Pending → Doing → Done → Pending |
| `n`, `e`, `x` | Create, edit, or delete a task |
| `d` | Duplicate the selected task (opens a prefilled new-task prompt) |
| `r` | Revert a completed task to Doing |
| `c` | Cycle Kanban, focus-list, and completed-history views |
| `s` | Toggle the terminal bell |
| `g` | Open settings (adjust marquee speed) |
| `?` | Show all shortcuts |
| `q`, `Ctrl+C` | Quit |

The terminal bell is enabled by default. Terminals configured to suppress bells will still show the animated status-change feedback.
The selected long task title scrolls continuously in the list and Kanban views. New and
edited task titles wrap in the editor; use `Shift+Enter` to insert a manual line break.
