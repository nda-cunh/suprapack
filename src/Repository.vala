/*
 * This file is part of SupraPack.
 *
 * SupraPack is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SupraPack is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2025 SupraCorp - Nathan Da Cunha (nda-cunh)
 */

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

	public string extract_info (string file) {
		int status;
		string lore;
		try {
			Process.spawn_command_line_sync(@"tar -xf '$(file)' ./info", null, null, out status);
			if (status != 0)
				throw new ShellError.FAILED ("can't open it");
			var pkg = Package.from_file("./info");
			lore = pkg.description;
		}
		catch (Error e) {
			printerr(e.message);
			return "";
		}
		FileUtils.remove("./info");
		var name = Path.get_basename (file);
		return "%s %s\n".printf(name, lore);
	} 

	// Only for dev.  This function prepare the repository
	public void prepare (string [] args) throws Error {
		if (args.length >= 3) {
			foreach (var file in args[2:]) {
				var ext = extract_info (file);
				print("%s", ext);
			}
		}
		else {
			var pwd = Environment.get_current_dir();
			var lst = list_file_in_dir(pwd);
			lst.sort(strcmp);
			var fs = FileStream.open(@"$pwd/list", "w");
			if (fs == null)
				error("Cant create %s/list", pwd);

			foreach (unowned var file in lst) {
				var desc = extract_info (file);
				fs.puts(desc);
			}
		}
	}
}
