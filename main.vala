public string? PREFIX = null;
public string? LOCAL = null;
public string? USERNAME = null;
public string? REPO_LIST = null;

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


		if (av1 == "run")
			return cmd_run(args);
		if (av1 == "list")
			return cmd_list(args);
		if (av1 == "search")
			return cmd_search(args);
		if (av1 == "build")
			return cmd_build(args);
		if (av1 == "help")
			return cmd_help();
		if (av1 == "install")
			return cmd_install(args);
		if (av1 == "uninstall")
			return cmd_uninstall(args);
		if (av1 == "have_update")
			return cmd_have_update(args);
		if (av1 == "update")
			return cmd_update(args);
		if (av1 == "info")
			return cmd_info(args);
		if (av1 == "prepare")
			return cmd_prepare();
		print_error("La commande n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		USERNAME = Environment.get_user_name();
		PREFIX = Environment.get_home_dir() + "/.local";
	 	LOCAL = Environment.get_home_dir() + "/suprapack";
		REPO_LIST = LOCAL + "/repo.list";
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
