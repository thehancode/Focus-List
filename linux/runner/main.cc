#include "my_application.h"

int main(int argc, char** argv) {
  // Native Wayland intentionally gives the compositor sole control of window
  // placement. Prefer X11 (XWayland in a Wayland session) so Focus List can
  // restore its user-selected position. Keep an explicit caller override for
  // environments without XWayland or users who prefer native Wayland.
  g_setenv("GDK_BACKEND", "x11", FALSE);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
