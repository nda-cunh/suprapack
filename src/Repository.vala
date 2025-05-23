/**
 * Only used by `suprapack prepare`
 *
 * This file is used to prepare the repository.  It will list all the
 * suprapack files in the current directory and write them in a file
 * named `list` in the current directory.
 */
namespace Repository {

	private SList<string> list_file_in_dir (string dir_name) {
		try {
			var result = new SList<string>();
			var dir = Dir.open(dir_name);
			unowned string tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp.has_suffix(".suprapack"))
					result.append(tmp);
			}
			return result;
		} catch (Error e) {
			error(e.message);
		}
	}

	// Only for dev.  This function prepare the repository
	public void prepare () {
		var pwd = Environment.get_current_dir();
		var lst = list_file_in_dir(pwd);
		lst.sort(strcmp);
		var fs = FileStream.open(@"$pwd/list", "w");
		if (fs == null)
			error("Cant create %s/list", pwd);
		foreach (unowned var file in lst) {
			string lore = "";
			try {
				int status;
				Process.spawn_command_line_sync(@"tar -xf '$(file)' ./info", null, null, out status);
				if (status != 0)
					throw new ShellError.FAILED ("can't open it");
				var pkg = Package.from_file("./info");
				lore = pkg.description;
			}
			catch (Error e) {
				printerr(e.message);
			}
			fs.printf("%s %s\n", file, lore);
		}
		FileUtils.remove("./info");
	}
}
