public string? PREFIX = null;
public string? LOCAL = null;
public string? USERNAME = null;
public string? REPO_LIST = null;
public string? CONFIG = null;

public class Main {

	public bool all_cmd(string []args) {
		if (args.length < 2) {
			cmd_help();
			return true;
		}
		
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
		}
		print_error(@"La commande \"$(av1)\" n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		USERNAME = Environment.get_user_name();
		PREFIX = Environment.get_home_dir() + "/.local";
	 	LOCAL = Environment.get_home_dir() + "/.suprapack";
		REPO_LIST = LOCAL + "/repo.list";
		CONFIG = LOCAL + "/user.conf";
		DirUtils.create(LOCAL, 0755);
		Intl.setlocale();
		if (all_cmd(args) == true)
			Process.exit(0);
		Process.exit(1);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
