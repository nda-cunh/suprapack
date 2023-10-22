public string? PREFIX = null;
public string? LOCAL = null;
public string? USERNAME = null;

public class Main {

	public bool all_cmd(string []args) {
		if (args.length < 2) {
			cmd_help(args);
			return true;
		}
		
		// 1 argv (suprapack)
		if (FileUtils.test(args[1], FileTest.EXISTS)) {
			install_suprapackage(args[1]);
			return true;
		}

		if (args[1].match_string("run", true))
			return cmd_run(args);
		if (args[1].match_string("list", true))
			return cmd_list(args);
		if (args[1].match_string("search", true))
			return cmd_search(args);
		if (args[1].match_string("build", true))
			return cmd_build(args);
		if (args[1].match_string("help", true))
			return cmd_help(args);
		if (args[1].match_string("install", true))
			return cmd_install(args);
		if (args[1].match_string("uninstall", true))
			return cmd_uninstall(args);
		if (args[1].match_string("update", true))
			return cmd_update(args);
		print_error("La commande n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		USERNAME = Environment.get_user_name();
		PREFIX = Environment.get_home_dir() + "/.local";
	 	LOCAL = Environment.get_home_dir() + "/suprastore";
		Intl.setlocale();
		if (all_cmd(args) == true)
			Process.exit(0);
		Process.exit(1);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
