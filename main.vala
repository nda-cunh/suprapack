public string HOME;
public string USERNAME;
public string? CONFIG = null;

public Config config;

public class Main {
	public bool all_cmd(string []args) throws Error {
		if (args.length < 2) {
			cmd_help();
			return true;
		}

		// foreach (var av in args[1:]) {
			// if (!av.has_prefix("-"))
				// continue;
			// switch (av) {
				// default:
					// print("%s is not know\n", av);
					// break;
// 
			// }
		// }

		string av1 = args[1].down();
		
		if (av1.has_suffix(".suprapack")) {
			install_suprapackage(args[1]);
			return true;
		}

		switch (av1) {
			case "query_get_comp":
				return cmd_query_get_comp(args);
			case "sync_get_comp":
				return cmd_sync_get_comp(args);
			case "list_files":
			case "-ql":
				return cmd_list_files(args);
			case "loading":
				cmd_loading(args);
			case "run":
				return cmd_run(args);
			case "-q":
			case "list":
				return cmd_list(args);
			case "search":
			case "-ss":
				return cmd_search(args);
			case "build":
				return cmd_build(args);
			case "help":
				return cmd_help();
			case "install":
			case "add":
			case "-s":
				return cmd_install(args);
			case "uninstall":
			case "remove":
			case "-r":
				return cmd_uninstall(args);
			case "have_update":
				return cmd_have_update(args);
			case "update":
			case "-syu":
				return cmd_update(args);
			case "info":
			case "-qi":
				return cmd_info(args);
			case "prepare":
				return cmd_prepare();
			case "config":
				return cmd_config(args);
			case "-g":
			case "download":
				return cmd_download(args);
		}
		print_error(@"La commande \"$(av1)\" n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		HOME = Environment.get_home_dir();
		USERNAME = Environment.get_user_name();
		Intl.setlocale();
		try {
			config = new Config();
			if (all_cmd(args) == true)
				Process.exit(0);
		} catch (Error e) {
			printerror(e.message);
		}
		Process.exit(1);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
