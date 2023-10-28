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

	int run_cmd(string []av) {
		try {
			var pid = new Subprocess.newv(av, SubprocessFlags.STDERR_SILENCE | SubprocessFlags.STDOUT_SILENCE);
			pid.wait();
			return pid.get_status();
		} catch (Error e) {
			print_error(e.message);
		}
	}

		int run(string []av, bool silence = false, string []envp = Environ.get()){
		int status;
		SpawnFlags flags;

		if (silence == true)
			flags = SEARCH_PATH_FROM_ENVP | CHILD_INHERITS_STDIN | STDERR_TO_DEV_NULL | STDOUT_TO_DEV_NULL;
		else
			flags = SEARCH_PATH_FROM_ENVP | CHILD_INHERITS_STDIN;
		try {
			Process.spawn_sync("/", av, envp, SpawnFlags.SEARCH_PATH | SpawnFlags.CHILD_INHERITS_STDIN, null, null, null, out status);
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
