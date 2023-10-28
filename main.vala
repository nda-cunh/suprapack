public string? PREFIX = null;
public string? LOCAL = null;
public string? USERNAME = null;

public class Main {

	public bool all_cmd(string []args) {
		string av1 = args[1].down();
		if (av1 == "run")
			return cmd_run(args);
		print_error("La commande n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		USERNAME = Environment.get_user_name();
		PREFIX = Environment.get_home_dir() + "/.local";
	 	LOCAL = Environment.get_home_dir() + "/suprapack";
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
