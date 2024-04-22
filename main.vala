public string HOME;
public string PWD;
public string USERNAME;
public string? CONFIG = null;
public string CONST_BLANK;

public Config config;

public class Main : Object {
	public bool all_cmd(string []args) throws Error {
		string []cmd = {"suprapack"};

		foreach (var av in args[1:]) {
			if (!av.has_prefix("-")) {
				cmd += av;
				continue;
			}
			if (av.has_prefix ("--prefix")) {
				config.change_prefix(av[9:]);
			}
			if (av.has_prefix ("--refresh")) {
				Sync.refresh_list();
			}
			else if (av.has_prefix ("--force")) {
				config.force = true;
			}
			else if (av.has_prefix ("--yes")) {
				config.allays_yes = true;
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


		string av1 = cmd[1];
		config.cmd = cmd;
		
		if (av1.has_suffix(".suprapack")) {
			prepare_install(cmd[1]);
			install();
			return true;
		}

		if (av1.has_prefix("-Sy")) {
			Sync.refresh_list();
			av1 = "-S" + av1[av1.last_index_of_char('y')+1:];
			print("[%s]\n", av1);
		}

		switch (av1) {

			case "query_get_comp":
				return cmd_query_get_comp(cmd);
			case "sync_get_comp":
				return cmd_sync_get_comp(cmd);
			case "shell":
				return cmd_shell(cmd);
			case "list_files":
			case "-Ql":
				return cmd_list_files(cmd);
			case "loading":
				cmd_loading(cmd);
			case "run":
			case "Qr":
				return cmd_run(cmd);
			case "-Q":
			case "list":
				return cmd_list(cmd);
			case "search":
			case "-Ss":
				return cmd_search(cmd);
			case "-B":
			case "build":
				return cmd_build(cmd);
			case "help":
				return cmd_help();
			case "install":
			case "add":
			case "-S":
				return cmd_install(cmd);
			case "uninstall":
			case "remove":
			case "-r":
				return cmd_uninstall(cmd);
			case "have_update":
				return cmd_have_update(cmd);
			case "update":
			case "-Su":
				return cmd_update(cmd);
			case "info":
			case "-Qi":
				return cmd_info(cmd);
			case "prepare":
			case "-P":
				return cmd_prepare();
			case "config":
				return cmd_config(cmd);
			case "search_supravim_plugin":
				return cmd_search_supravim_plugin(cmd);
			case "-G":
			case "download":
				return cmd_download(cmd);
                        case "update_list":
                        case "refresh":
                                return cmd_refresh();
		}
		print_error(@"La commande \"$(av1)\" n'existe pas.");
	}

	// INIT
	public Main(string []args) {
		HOME = Environment.get_home_dir();
		PWD = Environment.get_current_dir();
		USERNAME = Environment.get_user_name();
		CONST_BLANK = string.nfill(255, ' ');
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
