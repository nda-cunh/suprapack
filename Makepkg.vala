public class Makepkg : Object {

	private Regex regex_function;
	private Regex regex_attribut;
	private Regex regex_variable;
	private Regex regex_url;

	public string get_function (string contents, string function_name) throws Error {
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
		return "";
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
		print("\n\n\n\n");
		string contents;
		var env = Environ.get ();
		var srcdir = @"$PWD/makepkg/src";
		var pkgdir = @"$PWD/makepkg/pkg";
		DirUtils.create_with_parents (srcdir, 0755);
		DirUtils.create_with_parents (pkgdir, 0755);

		env = Environ.set_variable (env, "srcdir", srcdir, true);
		env = Environ.set_variable (env, "pkgdir", pkgdir, true);

		regex_attribut = new Regex("""^([^\s]+)[=](([(].*?[)])|(.*?$))""", MULTILINE | DOTALL);
		regex_function = new Regex("""^[^\s]*\s*[(]\s*[)]\s*[{]""", MULTILINE | DOTALL | ANCHORED);
		regex_url = /^https?[:][\/][\/]/;
		regex_variable = /[$][{(]?([0-9a-zA-Z_]+)[)}]?/;

		FileUtils.get_contents (pkgbuild, out contents);

		if (regex_attribut.match (contents, 0, out match_info)) {
			do {
				string name = match_info.fetch(1);
				string value = match_info.fetch(2);	

				value = replace_variable_in_string (value);
				value = Utils.strip (value, "()\f\r\n\t\v \'\"");
				print("Name:%s Value: %s\n", name, value);
				set_data<string> (name, value);
				env = Environ.set_variable (env, name, value, true);
				} while (match_info.next ());
		}
	

		foreach (var str in get_data<string>("source")?.replace("\n", " ").split(" "))
		{
			string url;
			string output;
			var tmp = str;

			int index;
			print("%s\n", str);
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

			print("download [%s] to [%s]\n", url, @"$srcdir/$output");
			if (regex_url.match (url)) {
				// print("DOWNLOAD\n");
				Utils.download (url, @"$srcdir/$output", false);
			} else {
				var file_src = @"$PWD/$url";
				try {
					// print("COPY %s\n", url);
					var @in = File.new_for_path (file_src);
					var @out = File.new_for_path (@"$srcdir/$output");
					@in.copy (@out, FileCopyFlags.OVERWRITE);
				} catch (Error e) {
					e.message = "Impossible to move %s  (%s)\n".printf(file_src, e.message);
					throw e;
				}
			}
		}


		var prepare = get_function (contents, "prepare");
		if (prepare != "") {
			print("Prepare()\n");
			Process.spawn_sync (srcdir, {"bash", "-c", prepare}, env, GLib.SpawnFlags.SEARCH_PATH, null, null, null, null);
		}
		var package = get_function (contents, "package");
		if (package != "") {
			print("Package()\n");
			Process.spawn_sync (srcdir, {"bash", "-c", package}, env, GLib.SpawnFlags.SEARCH_PATH, null, null, null, null);
		}
	
		Package pkg = {};
		pkg.name = get_data<string> ("pkgname" ?? "");
		pkg.version= get_data<string> ("pkgver" ?? "");
		pkg.description = get_data<string> ("pkgdesc" ?? "");
		pkg.dependency= get_data<string> ("dependency" ?? ""); //TODO

		pkg.create_info_file (@"$pkgdir/usr/info");
		Process.spawn_command_line_sync (@"suprapack build $pkgdir/usr");
	}

}
