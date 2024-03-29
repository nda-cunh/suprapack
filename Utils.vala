public errordomain HttpError {
	ERR
}
namespace Utils {

	async void sleep(uint ms) {
		Timeout.add(ms, sleep.callback);
		yield;
	}


	// Teste stdin request @default is false
	bool stdin_bool_choose (string str = "") {
		print(str);
		var result = stdin.read_line()?.strip() ?? "".ascii_down();
		if ("y" in result || "o" in result || result == "1")
			return true;
		return false;
	}
	
	// Teste stdin request @default is true 
	bool stdin_bool_choose_true (string str = "") {
		print(str);
		var result = stdin.read_line()?.strip() ?? "".ascii_down();
		if ("n" in result || result == "0")
			return false;
		return true;
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
	string get_input(string msg, bool down_force = true) {
		print(msg);
		string? str = stdin.read_line();
		if (str != null) {
			if (down_force)
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

	private bool have_only_zero (string []sp, int index) {
		var regex = /^[0]+$/;
		while (index < sp.length) {
			if (!regex.match (sp[index]))
				return true;
			++index;
		}
		return false;
	}

	/* returns true if V1 is greater than V2 */
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



public void download (string url, string output = "", bool no_print = false) throws Error {
	MatchInfo match_info;
	string name;
	string uri;
	string target;

	if (! /(https?:\/\/)?(?P<name>[^\/]*)(?P<uri>.*)/.match (url, 0, out match_info))
		return;
	name = match_info.fetch_named ("name");
	uri = match_info.fetch_named ("uri");
	uri = uri.replace (" ", "%20");
	if (output == "")
		target = uri[uri.last_index_of_char ('/') + 1:];
	else
		target = output;


	var fs = FileStream.open (target, "w");
	var client = new SocketClient(){tls=true};
	var conn = client.connect_to_host(name, 443);

	var output_stream = new DataOutputStream(conn.get_output_stream());
	var input_stream = new DataInputStream(conn.get_input_stream());


	output_stream.put_string(@"GET $uri HTTP/1.1\r\n");
	output_stream.put_string(@"Host: $name\r\n"); // Ajout de l'en-tête "Host"
	output_stream.put_string("Cache-Control: no-cache\r\n"); // Ignorer le cache
	output_stream.put_string("Connection: close\r\n"); // Ignorer le cache
	output_stream.put_string("\r\n");
	output_stream.flush();

	// Lecture de la réponse
	size_t bytes = 0;
	string line;
	
	string error = input_stream.read_line_utf8();
	error = error.offset(error.index_of_char(' '));
	int err =  int.parse(error);
	if (err != 200) {
		throw new HttpError.ERR(@"$(error) HTTP");
	}

	while ((line = input_stream.read_line_utf8()) != null) {

		/* Header Part */
		if (line.has_prefix("Content-Length: ")) {
			line.scanf("Content-Length: %zu", out bytes);
		}


		void modify_percent_bar (uint8[] buffer, double percent) {
			int calc = (int)((percent * 20) / 100);
			for (int i = 0; i != calc; ++i) {
				buffer[i+1] = '-';
			}
			buffer[21] = ']';
		}

		// print("header\n");
		/* Data Part */
		if (line == "\r") {
			// print("data\n");
			size_t SIZE_BUFFER = 16777216;
			var buffer = new uint8[SIZE_BUFFER];
			const double Mib = 1048576.0;
			double max = bytes;
			double actual = 0;
			string name_file = uri[uri.last_index_of_char ('/') + 1:];
			name_file = name_file.replace ("%20", " ");
			uint8[] progress_bar = "[                    ]".data;
			while (bytes > 0) {
				// print("data2\n");
				if (no_print == false){
					double percent = (100 * actual) / max;
					modify_percent_bar(progress_bar, percent);
					stdout.printf("%-50s %8s\r", name_file, "%.2f Mib / %.2f Mib %s %.1f%%".printf(actual / Mib, max / Mib, (string)progress_bar, percent));
				}
				// stdout.printf("%*.*s]%.2f%%\r".printf(50, 37, (string)progress_bar, percent));
				size_t len = input_stream.read (buffer[0:SIZE_BUFFER - 1]);
				buffer[len] = '\0';
				bytes -= len;
				actual += len;
				fs.write (buffer[0:len], 1);
				// print("here\n");
			}
			if (no_print == false){
				modify_percent_bar(progress_bar, 100);
				// stdout.printf("%-70s %8s  \n", "%s %.2f Mib/%.2f Mib".printf(name_file, actual / Mib, max / Mib), "%s 100%%".printf((string)progress_bar));
					stdout.printf("%-50s %8s\n", name_file, "%.2f Mib / %.2f Mib %s %.1f%%".printf(actual / Mib, max / Mib, (string)progress_bar, 100.0));
			}
			return;
		}
	}
}
}
// 20 -> 100
// ?  -> 27
