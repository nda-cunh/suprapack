public string HOME;
public string USERNAME;
public string? CONFIG = null;

public Config config;

void load_env() throws Error{
	var env = Environ.get();
	var prefix = Environ.get_variable(env, "PREFIX");
	if (prefix != null)
		config.change_prefix(prefix);
}


public class Main : Object {
	public bool all_cmd(string []args) throws Error {
		string []cmd = {"suprapack"};

		// Load Environment variable
		load_env();

		foreach (var av in args[1:]) {
			if (!av.has_prefix("-")) {
				cmd += av;
				continue;
			}
			if (av.has_prefix ("--prefix")) {
				config.change_prefix(av[9:]);
			}
			else if (av.has_prefix ("--force")) {
				config.force = true;
			}
			else if (av.has_prefix ("--supraforce")) {
				config.supraforce = true;
			}
			else
				cmd += av;
		}
		
		if (cmd.length < 2) {
			cmd_help();
			return true;
		}


		string av1 = cmd[1].down();
		config.cmd = cmd;
		
		if (av1.has_suffix(".suprapack")) {
			install_suprapackage(cmd[1]);
			return true;
		}

		switch (av1) {
			case "query_get_comp":
				return cmd_query_get_comp(cmd);
			case "sync_get_comp":
				return cmd_sync_get_comp(cmd);
			case "shell":
				return cmd_shell(cmd);
			case "list_files":
			case "-ql":
				return cmd_list_files(cmd);
			case "loading":
				cmd_loading(cmd);
			case "run":
				return cmd_run(cmd);
			case "-q":
			case "list":
				return cmd_list(cmd);
			case "search":
			case "-ss":
				return cmd_search(cmd);
			case "build":
				return cmd_build(cmd);
			case "help":
				return cmd_help();
			case "install":
			case "add":
			case "-s":
				return cmd_install(cmd);
			case "uninstall":
			case "remove":
			case "-r":
				return cmd_uninstall(cmd);
			case "have_update":
				return cmd_have_update(cmd);
			case "update":
			case "-syu":
				return cmd_update(cmd);
			case "info":
			case "-qi":
				return cmd_info(cmd);
			case "prepare":
				return cmd_prepare();
			case "config":
				return cmd_config(cmd);
			case "-g":
			case "download":
				return cmd_download(cmd);
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
