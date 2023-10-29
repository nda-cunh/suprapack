namespace Utils {

	void create_pixmaps_link() {
		string HOME = Environment.get_home_dir ();
		try {
			var pixmaps = @"$HOME/.local/share/pixmaps";
			if (FileUtils.test(pixmaps, FileTest.IS_SYMLINK)) {
				return ;
			}
			else if (FileUtils.test(pixmaps, FileTest.EXISTS)) {
				FileUtils.remove(pixmaps);
				var file = File.new_for_path(pixmaps);
				file.make_symbolic_link(@"$HOME/.icons");
			}
			else {
				DirUtils.create_with_parents(@"$HOME/.local/share/", 0755);
				var file = File.new_for_path(pixmaps);
				file.make_symbolic_link(@"$HOME/.icons");
			}
		}
		catch (Error e) {
			printerr(e.message);
		}
	}

	int run_silent(string []av) {
		SpawnFlags flags = 0;
		string PWD = Environment.get_current_dir();

		flags = STDOUT_TO_DEV_NULL | STDERR_TO_DEV_NULL | SEARCH_PATH | CHILD_INHERITS_STDIN;
		try {
			int status;
			Process.spawn_sync(PWD, av, Environ.get(), flags, null, null, null, out status);
			return status;
		} catch (Error e) {
			print_error(e.message);
		}
	}

	int run(string[] av, string[] envp = {}){
		string PWD = Environment.get_current_dir();
		string []_envp;

		if (envp.length == 0)
			_envp = Environ.get();
		else
			_envp = envp;
		try {
			int status;
			Process.spawn_sync(PWD, av, _envp, SpawnFlags.SEARCH_PATH | SpawnFlags.CHILD_INHERITS_STDIN, null, null, null, out status);
			return status;
		} catch (Error e) {
			print_error(e.message);
		}
	}

	



	// return a stdin line with downcase and strip space
	string get_input(string msg) {
		print(msg);
		string? str = stdin.read_line();
		if (str != null) {
			str = str.down();
			str = str.strip();
			return str;
		}
		return "";
	}
}
