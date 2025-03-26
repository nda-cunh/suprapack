public unowned string HOME;
public unowned string PWD;
public unowned string USERNAME;
public Config config;

public class Main : Object {
	public static string? prefix = null;
	public static bool refresh = false;
	public static bool force = false;
	public static bool no_fakeroot = false;
	public static bool yes = false;
	public static bool simple_print = false;
	public static bool supraforce = false;
	public static string? strap = null;
	public static bool build_and_install = false;
	public static string? build_output = null;

	const OptionEntry[] options = {
		{ "prefix", 'p', OptionFlags.NONE, OptionArg.STRING, ref prefix, "", "Path to the folder" },
		{ "refresh", 'r', OptionFlags.NONE, OptionArg.NONE, ref refresh, "refresh the list of packages", null },
		{ "force", 'f', OptionFlags.NONE, OptionArg.NONE, ref force, "force the operation", null },
		{ "yes", 'y', OptionFlags.NONE, OptionArg.NONE, ref yes, "answer yes to all questions", null },
		{ "simple-print", '\0', OptionFlags.NONE, OptionArg.NONE, ref simple_print, "simple print", null },
		{ "supraforce", 's', OptionFlags.NONE, OptionArg.NONE, ref supraforce, "force the operation", null },
		{ "no_fakeroot", '\0', OptionFlags.NONE, OptionArg.NONE, ref no_fakeroot, "don't build package with fakeroot", null },
		{ "strap", '\0', OptionFlags.NONE, OptionArg.STRING, ref strap, "like pacstrap", null },
		{ "install", '\0', OptionFlags.NONE, OptionArg.NONE, ref build_and_install, "build and install the package", null },
		{ "build_output", '\0', OptionFlags.NONE, OptionArg.STRING, ref build_output, "build output", null },
		{ null }
	};
	bool all_cmd(string []commands) throws Error {

		if (commands.length < 2) {
			Cmd.help();
			return true;
		}

		if (commands[1] == "config") {
			config.parse(ref commands);
			return true;
		}

		var opt_context = new OptionContext ();
		opt_context.add_main_entries (options, null);
		opt_context.set_help_enabled(false);
		opt_context.parse(ref commands);


		if (refresh)
			Sync.refresh_list();
		if (prefix != null)
			config.change_prefix(prefix);
		if (strap != null)
			config.change_strap(strap);
		config.force = force;
		config.allays_yes = yes;
		config.supraforce = supraforce;
		config.simple_print = simple_print;
		config.use_fakeroot = !no_fakeroot;
		config.build_and_install = build_and_install;
		config.build_output = build_output ?? ".";


		unowned string av1 = commands[1];
		config.cmd = commands;

		if (av1.has_suffix(".suprapack")) {
			prepare_install(commands[1]);
			install();
			return true;
		}

		switch (av1) {
			case "query_get_comp":
				return Cmd.query_get_comp(commands);
			case "sync_get_comp":
				return Cmd.sync_get_comp(commands);
			case "shell":
				return Cmd.shell(commands);
			case "list_files":
			case "-Ql":
				return Cmd.list_files(commands);
			case "loading":
				Cmd.loading(commands);
			case "run":
			case "Qr":
				return Cmd.run(commands);
			case "-Q":
			case "list":
				return Cmd.list(commands);
			case "search":
			case "-Ss":
				return Cmd.search(commands);
			case "-B":
			case "build":
				return Cmd.build(commands);
			case "help":
				return Cmd.help();
			case "install":
			case "add":
			case "-S":
				return Cmd.install(commands);
			case "uninstall":
			case "remove":
			case "-r":
				return Cmd.uninstall(commands);
			case "have_update":
				return Cmd.have_update(commands);
			case "update":
			case "-Su":
				return Cmd.update(commands);
			case "info":
			case "-Qi":
				return Cmd.info(commands);
			case "prepare":
			case "-P":
				return Cmd.prepare();
			case "search_supravim_plugin":
				return Cmd.search_supravim_plugin(commands);
			case "-G":
			case "download":
				return Cmd.download(commands);
			case "update_list":
			case "refresh":
				return Cmd.refresh();
			case "version":
				return Cmd.version();
		}
		error("La commande \"%s\" n'existe pas.", av1);
	}

	// INIT
	public Main(string []args) {
		if (Environment.get_variable("GIO_MODULE_DIR") == null) {
			if (FileUtils.test("/usr/lib/gio/modules", FileTest.IS_DIR | FileTest.EXISTS))
				Environment.set_variable ("GIO_MODULE_DIR", "/usr/lib/gio/modules", true);
			else if (FileUtils.test("/usr/lib/x86_64-linux-gnu/gio/modules", FileTest.IS_DIR | FileTest.EXISTS))
				Environment.set_variable ("GIO_MODULE_DIR", "/usr/lib/x86_64-linux-gnu/gio/modules", true);
			else {
				if (Environment.get_variable("GIO_MODULE_DIR") == null) {
					warning ("gio module not found");
					warning ("try install glib-networking");
					warning ("set GIO_MODULE_DIR to modules directory");
				}
			}
		}
		// set locale for utf8 support
		Intl.setlocale();
		// warning, error, message function
		init_message();
		// load environment variables
		HOME = Environment.get_variable("HOME");
		PWD = Environment.get_variable("PWD");
		USERNAME = Environment.get_user_name();

		try {
			config = new Config();
			if (all_cmd(args) == true)
				Process.exit(0);
		} catch (Error e) {
			warning(e.message);
		}
		Process.exit(1);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
