namespace Utils {

	public async void loading () {
		const string animation[] = {
			"⠋ Loading .  ",
			"⠙ Loading .. ",
			"⠹ Loading ...",
			"⠸ Loading .. ",
			"⠼ Loading ...",
			"⠴ Loading .. ",
			"⠦ Loading .  ",
			"⠧ Loading .. ",
			"⠇ Loading .  ",
			"⠏ Loading .. "
		};
		int i = 0;
		while (true) {
			Timeout.add(300, loading.callback);
			yield;
			print("%s\r", animation[i]);
			++i;
			if (i == animation.length)
				i = 0;
		}
	}

	public async int run_proc (string []av) {
		string []av_cmd = av[2:];
		try {
			var proc = new Subprocess.newv(av_cmd, STDERR_SILENCE | STDOUT_SILENCE | INHERIT_FDS);
			yield proc.wait_async();
			return proc.get_status();
		} catch (Error e) {
			printerr(e.message);
		}
		return -1;
	}


	/**
	 * Strip the string and return a new string
	 *
	 * @param str the string to strip
	 * @param character the character to strip
	 * @return the new string
	 */
	public string strip (string str, string character = "\f\r\n\t\v [(\'\")]") {
		int end = str.length;
		int start = 0;
		unichar t;

		while (str.get_next_char (ref start, out t)){
			if (character.index_of_char (t) == -1) {
				str.get_prev_char (ref start, out t);
				break;
			}
		}
		while (str.get_prev_char (ref end, out t)){
			if (character.index_of_char (t) == -1) {
				str.get_next_char(ref end, out t);
				break;
			}
		}
		return str[start:end];
	}

	/**
	 * Teste stdin request
	 *
	 * @param str the message to print
	 * @return true if the user choose true (value by default is define by @default_value)
	 */
	bool stdin_bool_choose (string str = "", bool default_value = false) {
		print(str);
		var result = (stdin.read_line()?._strip() ?? "").ascii_down();
		if (default_value == false) {
			if ("y" in result || "o" in result || result == "1")
				return true;
			return false;
		}
		if ("n" in result || result == "0")
			return false;
		return true;
	}

	/**
	 * Run a command and return the status
	 *
	 * @param av the command to run
	 * @param envp the environment to use
	 * @return the status of the command
	 */
	int run (string[] av, string[] envp = {}, bool silent = false) {
		SpawnFlags flags = 0;
		string PWD = Environment.get_current_dir();
		string []_envp;

		flags = SpawnFlags.SEARCH_PATH + SpawnFlags.CHILD_INHERITS_STDIN;
		if (silent)
			flags += SpawnFlags.STDOUT_TO_DEV_NULL + SpawnFlags.STDERR_TO_DEV_NULL;
		if (envp.length == 0)
			_envp = Environ.get();
		else
			_envp = envp;
		try {
			int status;
			Process.spawn_sync(PWD, av, _envp, flags, null, null, null, out status);
			return status;
		} catch (Error e) {
			error(e.message);
		}
	}

	/**
	 * Take a SupraList[] and sort it by version
	 *
	 * @param lst the SupraList[] to sort
	 * @return the sorted SupraList[]
	 */
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

	/**
	 * Like max_version but with SupraList instead of string
	 *
	 * @param s1 the first SupraList
	 * @param s2 the second SupraList
	 * @return the SupraList with the max version
	 */
	public unowned SupraList max_version_supralist(SupraList s1, SupraList s2) {
		if (Utils.compare_versions (s1.version, s2.version))
			return s1;
		return s2;
	}


	/**
	 * Get a line from stdin and downcase it and strip space
	 *
	 * @param msg the message to print
	 * @param down_force if true, force the downcase
	 * @return the line
	 */
	public string get_input(string msg, bool down_force = true) {
		print(msg);
		string? str = stdin.read_line();
		if (str != null) {
			if (down_force)
				str = str.down();
			str._strip();
			return (owned)str;
		}
		return "";
	}

	/**
	 * Get the size of a folder
	 *
	 * @param folder_name the folder path name
	 * @return the size of the folder
	 */
	public int64 size_folder (string folder_name) {
		File file = File.new_for_commandline_arg (folder_name);
		return size_folder_it(file);
	}

	/**
	 * Get the size of a folder (recursive)
	 *
	 * @param file the folder file
	 * @return the size of the folder
	 */
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


	/**
	 * Compare two versions
	 *
	 * @param v1 the first version
	 * @param v2 the second version
	 * @return true if v1 is greater than v2
	 */
	public bool compare_versions (string v1, string v2) {
		if (v1 == v2)
			return false;
		var s1 = v1.split(".");
		var s2 = v2.split(".");

		int i = 0;
		while (i < s1.length && i < s2.length) {
			int a = int.parse(s1[i]);
			int b = int.parse(s2[i]);
			if (a > b)
				return true;
			else if (a < b)
				return false;
			++i;
		}
		if (i < s1.length)
			return have_only_zero (s1, i);
		return false;
	}

	/**
	 * Check if the array have only zero
	 *
	 * @param sp the array to check
	 * @param index the index to start
	 * @return true if the array have only zero
	 */
	private bool have_only_zero (string []sp, int index) {
		var regex = /^[0]+$/;
		while (index < sp.length) {
			if (!regex.match (sp[index]))
				return true;
			++index;
		}
		return false;
	}

	/**
	 * Prepare the environment for the command
	 *
	 * Add the SRCDIR, PKGDIR, PREFIX, srcdir, pkgdir, prefix and PATH
	 * @param dir the directory to use
	 * @return the environment
	 */
	public string []prepare_envp(string dir) {
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", config.prefix, true);
		envp = Environ.set_variable(envp, "PREFIX", config.strap, true);
		envp = Environ.set_variable(envp, "srcdir", dir, true);
		envp = Environ.set_variable(envp, "pkgdir", config.prefix, true);
		envp = Environ.set_variable(envp, "prefix", config.strap, true);
		envp = Environ.set_variable(envp, "PATH", @"$(config.prefix)/bin:" + Environ.get_variable(envp, "PATH"), true);
		return envp;
	}

	/**
	 * Get the architecture of the system
	 *
	 * like x86-Linux, amd64-Linux, i686-Linux, i386-Darwin, amd64-Darwin, arm64-Darwin
	 * @return the architecture
	 */
	public unowned string get_arch () {
		utsname name;
		utsname.uname(out name);

		// Linux
		if (name.sysname == "Linux") {
			if (name.machine == "x86_64")
				return "amd64-Linux";
			if (name.machine == "x86")
				return "x86-Linux";
			if (name.machine == "i686")
				return "i686-Linux";
		}
		// Apple Darwin
		if (name.sysname == "Darwin") {
			if (name.machine == "arm")
				return "arm64-Darwin";
			if (name.machine == "i386")
				return "i386-Darwin";
			if (name.machine == "x86_64")
				return "amd64-Darwin";
		}
		return "any";
	}


	/**
	 * Convert a byte to a human readable string
	 * example : 1024 -> 1 Ko  or  10240245 -> 9.76 Mo
	 *
	 * @param b the byte to convert
	 * @return the human readable string
	 */
	public unowned string convertBytePrint(uint64 b, uint8* resultat) {
		double ko = b / 1024.0;
		double mo = ko / 1024.0;
		double go = mo / 1024.0;

		if (ko < 1000) {
			sprintf(resultat, "%.2f Ko", ko);
		} else if (mo < 1000) {
			sprintf(resultat, "%.2f Mo", mo);
		} else {
			sprintf(resultat, "%.2f Go", go);
		}
		return (string)resultat;
	}

	[CCode (cheader_filename = "stdio.h", cname="sprintf")]
	[PrintfFormat]
	internal extern int sprintf(uint8* str, string format, ...);
}
