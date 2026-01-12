namespace ConfigEnv {
/**
  * return all contents of all $prefix/.suprapack/package_name/env files
  **/
public string[] get_all_options() {
	string contents = get ();
	var result = new GenericArray<string> ();

	var lines = contents.split ("\n");
	foreach (unowned var line in lines) {
		if (line == "")
			continue;
		try {
			string env_contents;
			var env_file = Path.build_filename (global::config.prefix, ".suprapack", line, "env");
			if (FileUtils.test (env_file, FileTest.EXISTS)) {
				FileUtils.get_contents (env_file, out env_contents);
				var env_lines = env_contents.split ("\n");
				foreach (unowned var env_line in env_lines) {
					if (env_line == "")
						continue;
					result.add (env_line);
				}
			}
		}
		catch (Error e) {
		}
	}
	return (owned)result.data;
}
/**
  * return all contents of all $prefix/.suprapack/package_name/env files
  * parsed with @var@ and @prefix@
  * each option is 2 elements in the array: name and value
  **/
public string[] get_all_options_parsed() {
	var new_value = new StringBuilder();
	var result = new StrvBuilder ();
	var content = ConfigEnv.get_all_options ();
	unowned string prefix = global::config.prefix;
	uint8 name_buffer[256];
	uint8 value_buffer[256];

	foreach (unowned var opt in content) {
		opt.scanf ("%255[^ =] = %255[^\n]", name_buffer, value_buffer);
		unowned string name = (string)name_buffer;
		unowned string value = (string)value_buffer;

		result.add (name);
		// the value is special
		if (name[0] == '@') {
			name = name.offset (1);
		}

		// parse value
		new_value.truncate(0);
		new_value.append(value);
		new_value.replace ("@var@", name);
		new_value.replace ("@prefix@", prefix);
		result.add (new_value.str);
	}
	return result.end ();
}

private string get () {
	var file = Path.build_filename (global::config.prefix, ".suprapack", ".env");
	string contents;
	if (FileUtils.test (file, FileTest.EXISTS))
		FileUtils.get_contents (file, out contents);
	else
		contents = "";
	return contents;
}

// create the file in .suprapack/.env
// it contains all package name who contains an env file
public void add (string package_name) {
	var file = Path.build_filename (global::config.prefix, ".suprapack", ".env");
	// add the package name to the file if not exist
	string contents;
	if (FileUtils.test (file, FileTest.EXISTS)) {
		FileUtils.get_contents (file, out contents);
		var lines = contents.split ("\n");
		if (package_name in lines)
			return;
		contents += package_name + "\n";
	}
	else {
		contents = package_name + "\n";
	}
	config.need_generate_profile = true;
	FileUtils.set_contents (file, contents);
} 

public void remove (string package_name) {
	var file = Path.build_filename (global::config.prefix, ".suprapack", ".env");
	string contents;
	// remove the package name to the file if exist
	try {
		if (FileUtils.test (file, FileTest.EXISTS)) {
			FileUtils.get_contents (file, out contents);
			var lines = contents.split ("\n");
			var list = new GenericArray<string> ();
			list.data = lines;
			for (int i = 0; i < list.data.length; i++) {
				if (list.data[i] == package_name) {
					list.remove_index (i);
					break;
				}
			}
			string []new_lines = {};
			foreach (unowned var line in list.data) {
				if (line != "")
					new_lines += line;
			}
			contents = string.joinv ("\n", new_lines);
			if (contents != "")
				contents += "\n";
			FileUtils.set_contents (file, contents);
		}
		config.need_generate_profile = true;
	}
	catch (Error e) {
		warning ("Error removing package from .env: %s", e.message);
	}
}

}
