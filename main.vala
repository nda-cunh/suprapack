public unowned string HOME;
public unowned string PWD;
public unowned string USERNAME;
public string? CONFIG = null;
public string CONST_BLANK;

public Config config;

public class Main : Object {
	public static string? prefix = null;
	public static bool refresh = false;
	public static bool force = false;
	public static bool yes = false;
	public static bool supraforce = false;
	public static string? strap = null;

	const OptionEntry[] options = {
		{ "prefix", 'p', OptionFlags.NONE, OptionArg.STRING, ref prefix, "", "Path to the folder" },
		{ "refresh", 'r', OptionFlags.NONE, OptionArg.NONE, ref refresh, "refresh the list of packages", null },
		{ "force", 'f', OptionFlags.NONE, OptionArg.NONE, ref force, "force the operation", null },
		{ "yes", 'y', OptionFlags.NONE, OptionArg.NONE, ref yes, "answer yes to all questions", null },
		{ "supraforce", 's', OptionFlags.NONE, OptionArg.NONE, ref supraforce, "force the operation", null },
		{ "strap", '\0', OptionFlags.NONE, OptionArg.STRING, ref strap, "like pacstrap", null },
		{ null }
	};
	public bool all_cmd(string []args) throws Error {

		var opt_context = new OptionContext ("- Suprapack -");
		opt_context.add_main_entries (options, null);
		opt_context.set_help_enabled(false);
		opt_context.parse(ref args);


		string []commands = {"suprapack"};
		foreach (unowned var arg in args[1:]) {
			if (arg[0] != '-')
				commands += arg;
		}

		if (refresh)
			Sync.refresh_list();
		if (prefix != null)
			config.change_prefix(prefix);
		if (strap != null)
			config.change_strap(strap);
		config.force = force;
		config.allays_yes = yes;
		config.supraforce = supraforce;

		if (commands.length < 2) {
			cmd_help();
			return true;
		}


		unowned string av1 = commands[1];
		config.cmd = commands;
		
		if (av1.has_suffix(".suprapack")) {
			prepare_install(commands[1]);
			install();
			return true;
		}

		switch (av1) {
			case "query_get_comp":
				return cmd_query_get_comp(commands);
			case "sync_get_comp":
				return cmd_sync_get_comp(commands);
			case "shell":
				return cmd_shell(commands);
			case "list_files":
			case "-Ql":
				return cmd_list_files(commands);
			case "loading":
				cmd_loading(commands);
			case "run":
			case "Qr":
				return cmd_run(commands);
			case "-Q":
			case "list":
				return cmd_list(commands);
			case "search":
			case "-Ss":
				return cmd_search(commands);
			case "-B":
			case "build":
				return cmd_build(commands);
			case "help":
				return cmd_help();
			case "install":
			case "add":
			case "-S":
				return cmd_install(commands);
			case "uninstall":
			case "remove":
			case "-r":
				return cmd_uninstall(commands);
			case "have_update":
				return cmd_have_update(commands);
			case "update":
			case "-Su":
				return cmd_update(commands);
			case "info":
			case "-Qi":
				return cmd_info(commands);
			case "prepare":
			case "-P":
				return cmd_prepare();
			case "config":
				return cmd_config(commands);
			case "search_supravim_plugin":
				return cmd_search_supravim_plugin(commands);
			case "-G":
			case "download":
				return cmd_download(commands);
			case "update_list":
			case "refresh":
				return cmd_refresh();
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
					warning ("gio module not found\n");
					warning ("try install glib-networking\n");
					warning ("set GIO_MODULE_DIR to modules directory\n");
				}
			}
		}
		init_message();
		HOME = Environment.get_variable("HOME");
		PWD = Environment.get_variable("PWD");
		USERNAME = Environment.get_user_name();
		CONST_BLANK = string.nfill(255, ' ');
		Intl.setlocale();
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
