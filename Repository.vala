namespace Repository {

	private string []list_file_in_dir(string dir_name) {
		try {
		var dir = Dir.open(dir_name);
		string []result = {};
		unowned string tmp;

		while ((tmp = dir.read_name()) != null) {
			if (tmp.has_suffix(".suprapack"))
				result += tmp; 
		}
		return result;
		} catch (Error e) {
			print_error(e.message);
		}
	}

	// Only for dev.  This function prepare the repository
	public void prepare() {
		var pwd = Environment.get_current_dir();
		var lst = list_file_in_dir(pwd);

		var fs = FileStream.open(@"$pwd/list", "w");
		if (fs == null)
			print_error(@"Cant create $pwd/list");
		foreach (var file in lst) {
			fs.printf("%s\n", file);
		}
	}
}
