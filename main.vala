public string? PREFIX = null;
public string? LOCAL = null;
public string? USERNAME = null;

public class Main {

	public void all_cmd(string []args) {
		if (args.length < 2)
			cmd_help(args);
		
		// 1 argv (suprapack)
		if (FileUtils.test(args[1], FileTest.EXISTS)) {
			install_package(args[1]);
			return ;
		}

		if (args[1].match_string("list", true))
			cmd_list(args);
		if (args[1].match_string("search", true))
			cmd_search(args);
		if (args[1].match_string("build", true))
			cmd_build(args);
		if (args[1].match_string("help", true))
			cmd_help(args);
		if (args[1].match_string("install", true))
			cmd_install(args);
		if (args[1].match_string("uninstall", true))
			cmd_uninstall(args);
		if (args[1].match_string("update", true))
			cmd_update(args);
		print_error("La commande n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		USERNAME = Environment.get_user_name();
		PREFIX = Environment.get_home_dir() + "/.local";
	 	LOCAL = Environment.get_home_dir() + "/suprastore";
		Intl.setlocale();
		all_cmd(args);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
