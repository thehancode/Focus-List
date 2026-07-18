# Build Prompts

1. Please remove the `c` shortcut for completed view; make `c` do the view cycling that `v` currently does.

2. Please install Cargo and the things needed to rebuild.

3. On startup, open the program in a Ghostty terminal without tmux (zsh starts tmux by default), and copy the current `tasklists` tasks to the startup data location.

4. Make the new-task textbox wrap longer text; add a permanent marquee for truncated task text; add a JSON marquee-speed setting and an in-app configuration menu.

5. Make the marquee apply only to the selected task.

6. Add a setting to toggle long task titles between marquee and wrapped display.

7. Show `-` for unselected tasks where the selected task shows `›`.

8. Make the task editor support free cursor movement similar to nano; fix Shift+Enter/new-line behavior.

9. Add daily tasks: they can be completed once per day, reset to Pending the next day, retain multiple completion records in completed history, and support a Doing-only focus mode.

10. For daily tasks, show a GitHub-style current/previous-month activity view when selecting a task with `o`.

11. Remove the manual `p` focus option and Kanban view; automatically enter Doing view when a task moves from Pending to Doing, return to the list when all Doing tasks are Done, keep completed history out of the cycle, and replace the calendar with a daily-completion strip in the footer.

12. Make `c` cycle between list and Doing focus; make `v` open completed history without being part of the cycle.

13. Remove new-line support from the editor; save with Enter instead of Ctrl+S; use an overlaid block cursor; remove today’s daily completion record if the task returns to Pending.

14. Add `Space` then `↑`/`↓` to move the selected task up or down in its status-group ordering.
