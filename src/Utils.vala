public errordomain HttpError {
	ERR,
	CANCEL
}

namespace Utils {

	/**
	 * Sleep for a number of milliseconds (async)
	 *
	 * @param ms the number of milliseconds to sleep
	 */
	public async void sleep(uint ms) {
		Timeout.add(ms, sleep.callback);
		yield;
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
	 * Teste stdin request (the default value is false)
	 *
	 * @param str the message to print
	 * @return true if the user choose true (No value is false)
	 */
	bool stdin_bool_choose (string str = "") {
		print(str);
		var result = (stdin.read_line()?._strip() ?? "").ascii_down();
		if ("y" in result || "o" in result || result == "1")
			return true;
		return false;
	}

	/**
	 * Teste stdin request (the default value is true)
		*
	 * @param str the message to print
	 * @return true if the user choose true (No value is true)
	 */
	bool stdin_bool_choose_true (string str = "") {
		print(str);
		var result = (stdin.read_line()?._strip() ?? "").ascii_down();
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
	int run (string[] av, string[] envp = {}) {
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
			error(e.message);
		}
	}
	
	
	/**
	 * Like run() but with silent output
	 *
	 * @param av the command to run
	 * @return the status of the command
	 */
	int run_silent (string []av) {
		SpawnFlags flags = 0;
		string PWD = Environment.get_current_dir();

		flags = STDOUT_TO_DEV_NULL | STDERR_TO_DEV_NULL | SEARCH_PATH | CHILD_INHERITS_STDIN;
		try {
			int status;
			Process.spawn_sync(PWD, av, Environ.get(), flags, null, null, null, out status);
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
	 * Create a buffer (string) with the progress of the download
	 *
	 * @param buffer the buffer to modify with the progress bar
	 * @param percent the percent of the download (0-100)
	 */
	private void modify_percent_bar (uint8[] buffer, double percent) {
		int calc = (int)(percent * 20 / 100);
		for (int i = 0; i < 20; i++) {
			if (i < calc) {
				buffer[i+1] = '-';
			} else {
				buffer[i+1] = ' ';
			}
		}
		buffer[21] = ']';
		buffer[22] = '\0';
	}

	/**
	 * Print the download progress
	 *
	 * @param name_file the name of the file
	 * @param actual the actual size of the file
	 * @param max the max size of the file
	 */
	void print_download(string name_file, double actual, double max) {
		const double MIB = 1048576.0;
		double percent = (100 * actual) / max;
		if (config.simple_print) {
			print ("download: [%u]\n", (uint)percent);
			return ;
		}
		uint8[] progress_bar = "[                    ] \0".data;

		if (max <= 0.0) {
			stdout.printf("%-50s %8s\r", name_file, "%.2f Mib / ??? Mib     ".printf(actual / MIB));
			return;
		}
		if (actual > max)
			actual = max;

		modify_percent_bar(progress_bar, percent);
		var part2 = "%.2f Mib / %.2f Mib %s %.1f%%".printf((actual / MIB), (max / MIB), ((string)progress_bar), percent);
		stdout.printf("%-27s %70s\r", name_file, part2);
		if (percent == 100.0)
			print("\r\n");
	}

	/**
	 * Download a file from the internet
	 * @param url the url of the file
	 * @param output the output file
	 * @param no_print if true, don't print the download progress
	 * @param rec if true, retry the download ( set only by download function d'ont use it ) 
	 * @param cancel a cancellable object
	 */
	public void download (string url, string? output = null, bool no_print = false, bool rec = false, Cancellable? cancel = null) throws Error {
		var loop = new MainLoop ();

		var s = new Unix.SignalSource(2);
		s.set_callback( () => {
			print("\n");
			warning("Cancel by Ctrl + C (SIGINT) signal");
			cancel.cancel ();
			return false;
		});
		s.attach(GLib.MainContext.default());

		_download.begin(url, output, no_print, rec, cancel, () => {
			if (cancel.is_cancelled ())
				FileUtils.remove (output);
			loop.quit ();
		});
		loop.run ();
		s.destroy ();
		if (cancel.is_cancelled ())
			throw new HttpError.CANCEL("the download is cancel");
	}

	public async void _download (string url, string? output = null, bool no_print = false, bool rec = false, Cancellable? cancel = null) throws Error {
		const size_t SIZE_BUFFER = 16777216;
		unowned string	host;
		unowned string	query;
		unowned string	path;
		int				port;

		/* Parse Url */
		Uri uri = Uri.parse (url, UriFlags.SCHEME_NORMALIZE | UriFlags.ENCODED);
		host = uri.get_host ();
		query = uri.get_query ();
		path = uri.get_path ();
		port = uri.get_port ();


		string target;
		if (output == null && rec == false)
			target = path[path.last_index_of_char('/') + 1:];
		else
			target = (!)output;


		/* Open Connection-Files */

		var fs = FileStream.open (target, "w");
		if (fs == null)
			throw new HttpError.ERR ("Impossible to create target_file: (%s) file", target);
		var client = new SocketClient(){tls=true};
		var conn = yield client.connect_to_host_async (host, (uint16)port, cancel);

		var output_stream = new DataOutputStream(conn.get_output_stream());
		var input_stream = new DataInputStream(conn.get_input_stream());
		debug("download", "Host [%s] PATH [%s] PORT [%d]", host, path, port);


		/* Send GET request with headers */

		{
			string request = @"$path$(query != null ? "?"+query : "")";
			output_stream.put_string(@"GET $request HTTP/1.1\r\n");
			output_stream.put_string(@"Host: $host\r\n"); // Ajout de l'en-tête "Host"
			output_stream.put_string("Cache-Control: no-cache\r\n"); // Ignorer le cache
			output_stream.put_string("Accept-Encoding: identity\r\n"); // Ignorer le cache
			output_stream.put_string("Connection: close\r\n"); // Ignorer le cache
			output_stream.put_string("\r\n");
			output_stream.flush();
		}


		/* ERROR HTTP check 404, 400, 502 ...  */
		{
			string error = input_stream.read_line_utf8(null, cancel);
			error = error.offset(error.index_of_char(' '));
			int err =  int.parse(error);
			if (err != 200) {
				if (err != 302)
					throw new HttpError.ERR(@"$(error) HTTP".replace("\r", ""));
			}
		}

		string name_file;
		name_file = Uri.unescape_string(target[target.last_index_of_char ('/') + 1:]);
		name_file = name_file.to_ascii ();
		if (name_file.length >= 25)
			name_file = name_file[0:25] + "..";

		/* Get All bytes Data */
		string line;
		size_t bytes = 0;
		while ((line = input_stream.read_line_utf8(null, cancel)) != null) {
			/* Header Part */
			{
				uint8 buffer [2048];
				debug("download", "HEADER: [%s]", line);
				if (line.has_prefix("Content-Length: "))
					line.scanf("Content-Length: %zu", out bytes);
				else if (line.has_prefix ("Transfer-Encoding:")) {
					line.scanf("Transfer-Encoding: %s", out buffer);
					if (((string)buffer).ascii_down () == "chunked") {
						debug("download", "Retry chunked not supported");
						download(url, output, no_print, true);
						return;
					}
				}
				else if (line.has_prefix("Location: ")) {
					line.scanf("Location: %s", out buffer);
					debug("download", "redirect to %s", (string)buffer);
					download((string)buffer, output, no_print, true);
					return;
				}
			}

			/* Data Part */
			if (line == "\r") {
				var buffer = new uint8[SIZE_BUFFER];
				double totalBytes = bytes;
				double actual = 0;
				size_t len = 0;
				do {
					if (no_print == false)
						print_download (name_file, actual, totalBytes);
					try {
						len = yield input_stream.read_async (buffer[0:SIZE_BUFFER - 1], Priority.HIGH, cancel);

						if (len > 0) {
							buffer[len] = '\0';
							bytes -= len;
							actual += len;
							fs.write (buffer[0:len], 1);
						}
					}
					catch (Error e) {
						if (bytes == 0)
							break;
						throw e;
					}
				} while (len > 0);
				return;
			}
		}
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
