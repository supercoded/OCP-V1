/**
 * my_application.cc — Linux desktop entry point for OCP-V1 Flutter app.
 *
 * On desktop, this launches the bridge_server.js as a child process
 * before the Flutter app starts. The Flutter app then connects to it
 * via WebSocketPlatformService.
 *
 * The bridge server provides access to Meshtastic, RTL-SDR, RuView,
 * and map tile services through the existing Node.js packages.
 */

#include <flutter_linux/flutter_linux.h>
#include <glib.h>
#include <signal.h>
#include <sys/types.h>
#include <unistd.h>

// Global bridge server PID for cleanup
static GPid bridge_pid = 0;

/**
 * Launch the Node.js bridge server as a child process.
 *
 * Searches for bridge_server.js relative to the executable and in known
 * development paths.  Falls back gracefully if not found (the Flutter app
 * will try to reconnect via WebSocketPlatformService).
 */
static gboolean launch_bridge_server() {
  const gchar* home = g_get_home_dir();
  gchar* bridge_paths[] = {
      // Development: relative to build output
      g_build_filename(home, ".openclaw", "workspace", "OCP-V1",
                       "apps", "ocp_app", "bridge", "bridge_server.js", NULL),
      // Alternative development path
      g_build_filename("..", "bridge", "bridge_server.js", NULL),
      NULL,
  };

  for (int i = 0; bridge_paths[i] != NULL; i++) {
    if (g_file_test(bridge_paths[i], G_FILE_TEST_EXISTS)) {
      gchar* argv[] = {"node", (gchar*)bridge_paths[i], NULL};
      GError* error = NULL;

      gboolean launched = g_spawn_async(
          NULL,          // working directory
          argv,          // arguments
          NULL,          // environment
          G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL,
          NULL,          // child setup
          NULL,          // user data
          &bridge_pid,   // PID
          &error);

      if (launched) {
        g_print("OCP-V1: Bridge server launched (PID %d)\n", (int)bridge_pid);
        // Give it a moment to start
        g_usleep(500000); // 500ms
        g_free(bridge_paths[i]);
        return TRUE;
      } else {
        g_printerr("OCP-V1: Failed to launch bridge server: %s\n",
                   error ? error->message : "unknown");
        if (error) g_error_free(error);
      }
    }
    g_free(bridge_paths[i]);
  }

  g_print("OCP-V1: Bridge server not found — WebSocket connection will be retried\n");
  return FALSE;
}

/**
 * Terminate the bridge server on shutdown.
 */
static void terminate_bridge_server() {
  if (bridge_pid > 0) {
    kill(bridge_pid, SIGTERM);
    g_print("OCP-V1: Bridge server terminated (PID %d)\n", (int)bridge_pid);
    bridge_pid = 0;
  }
}

/**
 * Application shutdown callback.
 */
static void on_application_shutdown(GtkApplication* app, gpointer user_data) {
  terminate_bridge_server();
}

/**
 * Main entry point for the Linux desktop application.
 *
 * Initializes GTK, launches the bridge server, and hands off to
 * Flutter's desktop embedding.
 */
int main(int argc, char** argv) {
  // Launch the bridge server before starting Flutter
  launch_bridge_server();

  // Set up GTK application
  GtkApplication* app = gtk_application_new(
      "com.ocp.ocp_v1", G_APPLICATION_FLAGS_NONE);

  g_signal_connect(app, "shutdown", G_CALLBACK(on_application_shutdown), NULL);

  // The Flutter desktop embedding will handle the rest.
  // In a full Flutter desktop project, this would call
  // flutter_plugins_gemini_application_run() or similar.
  // For now, we rely on the Flutter tooling to generate the actual
  // runner — this file serves as a reference for the bridge launch logic.

  int status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);

  return status;
}