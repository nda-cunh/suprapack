namespace Utils {

	async void sleep(uint ms) {
		Timeout.add(ms, sleep.callback);
		yield;
	}


	// Teste stdin request @default is false
	bool stdin_bool_choose (string str = "") {
		print(str);
		var result = stdin.read_line().strip().ascii_down();
		if ("y" in result || "o" in result || result == "1")
			return true;
		return false;
	}

	void create_pixmaps_link() {
		string HOME = Environment.get_home_dir ();
		print("Create pixmaps link\n");
		var pixmaps_path = @"$HOME/.local/share/pixmaps";
		var icons_path = @"$HOME/.icons";

		if (FileUtils.test(icons_path, FileTest.IS_SYMLINK)) {
			if (!FileUtils.test(pixmaps_path, FileTest.EXISTS)) {
				DirUtils.remove(pixmaps_path);
				FileUtils.remove(pixmaps_path);
				create_pixmaps_link();
			}
			return ;
		}
		else {
			DirUtils.create_with_parents(@"$HOME/.local/share/", 0755);
			if (FileUtils.symlink(pixmaps_path, icons_path) != 0) {
				if (FileUtils.test (pixmaps_path, FileTest.EXISTS))
					print_error(@"Impossible link to .icons please remove $pixmaps_path");
				if ( FileUtils.test (icons_path, FileTest.EXISTS))
					print_error(@"Impossible link to .icons please remove $icons_path");

			}
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

	SupraList[] sort_supralist_version(SupraList []lst) {
		var list = lst.copy();

		for (int j = 0; j < list.length; j++) {
			for (int i = 0; i < list.length - 1; i++) {
				var tmp = max_version_supralist(list[i], list[i + 1]);
				if (tmp == list[i]) {
					list[i] = list[i + 1];
					list[i + 1] = tmp;
				}
			}
		}
		return list;
	}

	unowned SupraList max_version_supralist(SupraList s1, SupraList s2) {
		var res = Utils.max_version(s1.version, s2.version);
		if (res == s1.version)
			return s1;
		return s2;
	}

	// return max version
	unowned string max_version(string v1, string v2) {
		var reg = /[^0-9]+/;
		var sp1 = reg.split(v1);
		var sp2 = reg.split(v2);
		for (var i = 0; i != sp1.length && i != sp2.length; ++i) {
			int i1 = int.parse(sp1[i]);
			int i2 = int.parse(sp2[i]);
			if (i1 == i2)
				continue;
			if (i1 > i2)
				return v1;
			else
				return v2;
		}
		return v1;
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
	public int64 size_folder (string folder_name) {
		File file = File.new_for_commandline_arg (folder_name);
		return size_folder_it(file);
	}

	private int64 size_folder_it (File file) {
		int64 result = 0;
		try {
			FileEnumerator enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
			FileInfo info = null;
			while (((info = enumerator.next_file ()) != null)) {
				if (info.get_file_type () == FileType.DIRECTORY) {
					var thread = new Thread<long>(null, () => {
							File subdir = file.resolve_relative_path(info.get_name());
							var subdir_size = size_folder_it(subdir);
							return (long)subdir_size;
						});
					result += (int64)thread.join();
				} else {
					result += info.get_size ();
				}
			}
		} catch(Error e) { }
		return result;
	}

}
