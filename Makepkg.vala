public class Makepkg : Object {

	private Regex regex_function;
	private Regex regex_attribut;
	private Regex regex_variable;
	private Regex regex_url;
	private Regex regex_git_url;

	public string? get_function (string contents, string function_name) throws Error {
		unowned string tmp = contents;
		while (tmp != null) {
			var index = tmp.index_of (function_name);
			if (index == -1)
				break;
			tmp = tmp.offset(index);
			if (regex_function.match(tmp)) {
				unowned string begin = tmp.offset(tmp.index_of_char ('{'));
				int end = 0;

				int count = 1;
				while (begin[end] != '\0') {
					if (begin[end] == '{')
						count++;
					else if (begin[end] == '}')
						count--;
					if (count == 1)
						break;
					++end;
				}

				return begin[1:end];
			}
			tmp = tmp.offset(1);
		}
		return null;
	}


	string replace_variable_in_string (string str) throws Error { 
		MatchInfo match_info;
		var builder = new StringBuilder.sized(str.length*2);

		if (regex_variable.match(str, 0, out match_info)) {
			int start = 0;
			int end = 0;
			do {
				var last_start = end;
				var tmp = match_info.fetch(1);
				match_info.fetch_pos(0, out start, out end);
				builder.append_len(str.offset(last_start), start - last_start);
				builder.append(get_data<string> (tmp));

			} while (match_info.next());
			builder.append(str[end:]);
		}
		else
			return str;
		return builder.str;
	}


	public Makepkg (string pkgbuild) throws Error{
		MatchInfo match_info;
		string contents;
		var env = Environ.get ();
		var srcdir = @"$PWD/src";
		var pkgdir = @"$PWD/pkg";

		Process.spawn_command_line_sync (@"rm -rf $(pkgdir)");
		DirUtils.create_with_parents (srcdir, 0755);
		DirUtils.create_with_parents (pkgdir + "/usr", 0755);

		env = Environ.set_variable (env, "srcdir", srcdir, true);
		env = Environ.set_variable (env, "pkgdir", pkgdir, true);
		env = Environ.set_variable (env, "prefix", config.prefix, true);

		regex_attribut = new Regex("""^([^\s]+?)[=](([(].*?[)])|(.*?$))""", MULTILINE | DOTALL); 
		regex_function = new Regex("""^(.+?)[(].*?[)].*?[{]""", MULTILINE);
		regex_url = /^https?[:][\/][\/]/;
		regex_git_url = /^git[+](?P<name_url>(https?[:][\/][\/][^\s#]*))([#]branch[=](?P<branch>([^\s]*)))?/;
		regex_variable = /[$][{(]?([0-9a-zA-Z_]+)[)}]?/;



		/* Get all the PKGBUILD and set it in contents-string */
		FileUtils.get_contents (pkgbuild, out contents);

	
		/* Get All Attributs  (name=value) or (name=(value1 value2)) */
		string []attributs = {};
		if (regex_attribut.match (contents, 0, out match_info)) {
			do {
				string name = match_info.fetch(1);
				string value = match_info.fetch(2);	

				attributs += name;
				value = Utils.strip (value, "()\f\r\n\t\v \'\"");
				env = Environ.set_variable (env, name, value, true);
				set_data<string> (name, value);
			} while (match_info.next ());
		}

		/* Execute All Attributs function (name () { shell-script }) */
		if (regex_function.match(contents, 0, out match_info)) {
			do {
				var function_name = match_info.fetch(1);
				if (function_name != "package" && function_name != "prepare") {
					var pkgver = get_function (contents, function_name);
					if (pkgver != null) {
						string output;
						int wait_status;
						Process.spawn_sync (srcdir, {"bash", "-c", pkgver}, env, SEARCH_PATH, null, out output, null, out wait_status);
						set_data<string>(function_name, output);
						env = Environ.set_variable (env, function_name, output, true);
						if (wait_status != 0)
							throw new ShellError.FAILED("function -> %s send error", function_name);
					}
				}

			} while (match_info.next ());
		}

		/* Replace all ${VARIABLE} in attributs */
		foreach (var attr in attributs) {
			string value = get_data<string> (attr);
			value = replace_variable_in_string (value);
			set_data<string> (attr, value);
			env = Environ.set_variable (env, attr, value, true);
			debug("Attributs: [%s]->[%s]", attr, value);
		}



		/* Make Dependency */
		{
			string makedependency = get_data("makedepends");
			string []dependency = {};
			foreach (var i in makedependency?.replace("\n", " ")?.split(" ")) {
				dependency += Utils.strip (i, "\f\r\n\t\v\"\'[()] ");
			}
			foreach (var i in dependency) {
				if (Query.is_exist (i) == false) {
					print_info(@"$i is not installed cancelling...");
					foreach (var pkg in dependency) {
						if (!(Query.is_exist (pkg)))
							prepare_install (pkg);
					}
					install ();
					break;
				}
			}
				
		}




		print("\n");
		print_info ("Downloading all sources", "Source", "\033[36;1m");
		/* Parse Source('item1' 'item2') */
		foreach (var str in get_data<string>("source")?.replace("\n", " ")?.split(" "))
		{
			string url;
			string output;
			var tmp = str;

			int index;
			if ((index = tmp.index_of ("::")) > 0) {
				output = tmp[0:index];
				url = tmp[index+2:];
			}
			else {
				var begin = tmp.last_index_of_char('/');
				if (begin == -1)
					output = tmp;
				else
					output = tmp[begin:];
				url = tmp;
			}

			url = Utils.strip (url, "\'\"() \f\r\n\t\v");
			output = Utils.strip (output, "\'\"() \f\r\n\t\v");
	
			output = @"$srcdir/$output";
			print(output);
			debug("Source: %s", url);
			/* Download with git binary */
			if (regex_git_url.match (url, 0, out match_info)) {
				if (FileUtils.test (output, FileTest.EXISTS)) {
					print("%s ever install skip\n", output);
					continue;
				}
				debug("Git %s to -> %s", url, output);
				string url_name = match_info.fetch_named("name_url");
				string branch = match_info.fetch_named("branch") ?? "";
					
				string []argv_exec = {"git", "clone", "--depth", "1", url_name, output};
				if (branch != "") {
					debug("Git branch found %s", branch);
					argv_exec += "-b";
					argv_exec += branch;
				}


				int wait_status;
				Process.spawn_sync (srcdir,
						argv_exec,
						null,
						SEARCH_PATH,
						null,
						null,
						null,
						out wait_status);
				if (wait_status != 0)
					throw new ShellError.FAILED("impossible to git clone");
			}
			/* Download with HTTP 1.x */
			else if (regex_url.match (url)) {
				if (FileUtils.test (output, FileTest.EXISTS)) {
					print("%s ever install skip\n", output);
					continue;
				}
				debug("Download %s to -> %s", url, output);
				Utils.download (url, output, false);
			}
			/* Simple copy */
			else {
				print("%s\n", output);
				var file_src = @"$PWD/$url";
				debug("Copy %s to -> %s", file_src, output);
				try {
					var @in = File.new_for_path (file_src);
					var @out = File.new_for_path (output);
					@in.copy (@out, FileCopyFlags.OVERWRITE);
				} catch (Error e) {
					e.message = "Impossible to move %s  (%s)\n".printf(file_src, e.message);
					throw e;
				}
			}
		}


		/* Run Prepare and Package function  */

		print("\n");
		var prepare = get_function (contents, "prepare");
		if (prepare != null) {
			int wait_status;
			print_info ("running prepare script", "Prepare", "\033[36;1m");
			Process.spawn_sync (srcdir, {"bash", "-c", prepare}, env, GLib.SpawnFlags.SEARCH_PATH, null, null, null, out wait_status);
			if (wait_status != 0)
				throw new ErrorSP.CANCEL("prepare() send [%d] error code", wait_status);
		}
		var package = get_function (contents, "package");
		if (package != null) {
			int wait_status;
			print_info ("running package script", "Package", "\033[36;1m");
			Process.spawn_sync (srcdir, {"bash", "-c", package}, env, GLib.SpawnFlags.SEARCH_PATH, null, null, null, out wait_status);
			if (wait_status != 0)
				throw new ErrorSP.CANCEL("prepare() send [%d] error code", wait_status);
		}



		/* Create Package info */
		Package pkg = {};
		with (pkg) {
			init();
			name = get_data("pkgname") ?? "";
			version= get_data("pkgver") ?? "";
			description = get_data("pkgdesc") ?? "";
			author = get_data("pkgauthor") ?? "";
			
			string dependencies = get_data("depends");
			foreach (var i in dependencies?.replace("\n", " ")?.split(" ")) {
				dependency += Utils.strip (i, "\'\"()\f\r\t\v ") + " ";
			}

			string excludes = get_data("conflicts");
			foreach (var i in excludes?.replace("\n", " ")?.split(" ")) {
				exclude_package	 += Utils.strip (i, "\'\"()\f\r\t\v ") + " ";
			}
			create_info_file (@"$pkgdir/usr/info");
		}



		/* build the usr folder created in pkgdir/usr */
		Build.create_package (@"$pkgdir/usr");
	}

}
