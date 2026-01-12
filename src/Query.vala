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
 * Like Sync.vala but for local package
 *
 * Query is a namespace that contains functions for package installed
 * All functions for manage a package installed is here
 * like remove, list or get a package installed
 *
 * inspired by pacman -Q
 * @see Package.vala
 * @see Sync.vala
 */
namespace Query{

	/* verify if package is installed in ~/suprastore/name_pkg */
	public bool is_exist (string name_pkg) {
		return FileUtils.test(@"$(config.path_suprapack_cache)/$name_pkg/info", FileTest.EXISTS);
	}


	/**
	 * remove package with all files installed and remove ~/.suprapack/name_pkg
	 *
	 * @param name_pkg: the package name to remove
	 */
	public void uninstall (string name_pkg) {
		int g_last_size = 0;

		if (Query.is_exist(name_pkg) == false)
			error("the package %s doesn't exist", name_pkg);

		var pkg = Query.get_from_pkg (name_pkg);
		var deps = pkg.get_all_dependency ();
		try {
			// remove the required_by of the package
			foreach (unowned var i in deps) {
				Query.remove_package_to_required_by(name_pkg, i);
			}
		}
		catch (Error e) {
			debug (e.message);
		}

		var config_prefix_len = config.prefix.length;
		var bs = new StringBuilder.sized (256);
		const string remove = BOLD + YELLOW + "[Remove]" + NONE + " ";
		var lst = Query.get_from_pkg(name_pkg).get_installed_files();
		for (int i = 0; i != lst.length; ++i) {
			int file_len = lst[i].length;
			int calc = g_last_size - file_len;

			if (calc <= 0)
				calc = 1;
			if (config.simple_print) {
				uint percent = ((i+1) * 100) / lst.length;
				stdout.printf("remove: [%u] %s\n", percent, lst[i]);
			}
			else
				stdout.printf("%s[%u/%u] %s%*c\r", remove, i+1, lst.length, lst[i], calc, ' ');
			g_last_size = file_len;
			if (lst[i].has_prefix(config.prefix)) {
				FileUtils.unlink(lst[i]);
			}
			else{
				bs.len = 0;
				bs.append (config.prefix);
				bs.append (lst[i]);
				FileUtils.unlink(bs.str);
				var end = bs.str.last_index_of_char ('/', config_prefix_len);
				bs.truncate (end);
				if (DirUtils.remove (bs.str) == 0) {
					do {
						end = bs.str.last_index_of_char ('/', 0);
						bs.truncate (end);
					} while (DirUtils.remove (bs.str) == 0);
				}
			}
		}
		ConfigEnv.remove (name_pkg);
		Query.remove_pkg(name_pkg);
		print("\n");
	}
	

	/**
	* return the Package struct from a package-name
	* @param name_pkg: the package name to get
	*/
	public Package get_from_pkg (string name_pkg) throws Error {
		var pkg = Package.from_file(@"$(config.path_suprapack_cache)/$name_pkg/info");
		return pkg;
	}


	/**
	* Add package in required_by ex:  sfml -> openal
	*
	* ex : add_package_to_required_by("sfml", "openal")
	* because sfml need openal to work
	*
	* @param name_pkg: the package name to add
	* @param package_add: the package name to add in required_by
	*/
	public void add_package_to_required_by (string name_pkg, string package_add) throws Error {
		var folder = @"$(config.path_suprapack_cache)/$package_add/";
		var dest = @"$(folder)/required_by";
		var line = name_pkg + "\n";
	
		// Get the contents of the file if it exists or create it
		string contents;
		if (FileUtils.test(dest, FileTest.EXISTS))
			FileUtils.get_contents(dest, out contents);
		else
			contents = "";

		// Check if the line already exists in the file
		if ((line in contents) == false) {
			DirUtils.create_with_parents (folder, 0755);
			FileUtils.set_contents(dest, contents + line);
		}
	}

	public void remove_package_to_required_by (string name_pkg, string package_remove) throws Error {
		var folder = @"$(config.path_suprapack_cache)/$package_remove/";
		var dest = @"$(folder)/required_by";
		string contents;
		if (FileUtils.test(dest, FileTest.EXISTS)) {
			FileUtils.get_contents(dest, out contents);
			contents = contents.replace(name_pkg + "\n", "");
			FileUtils.set_contents(dest, contents);
		}
		else
			debug ("the file %s doesn't exist", dest);
	}


	/**
	 * return all package required by name_pkg
	 * @param name_pkg: the package name to get required_by
	 */
	public string[] get_required_by (string name_pkg) throws Error {

		if (name_pkg == "suprapack")
			return Query.get_all_installed_pkg ();
		string []res = {};
		string contents;
		var required_by = @"$(config.path_suprapack_cache)/$name_pkg/required_by";
		if (FileUtils.test(required_by, FileTest.EXISTS) == false) {
			return res;
		}
		else {
			FileUtils.get_contents(required_by, out contents);
			foreach (unowned var deps in contents.split("\n")) {
				if (deps.strip() == "")
					continue;
				res += deps;
			}
		}
		return res;
	}


	/**
	 * remove only ~/suprapack/PKG info and required_by
	 * and run uninstall script if exist
	 *
	 * @param name_pkg: the package name to remove
	 */
	private void remove_pkg (string name_pkg) {
		var pkg = @"$(config.path_suprapack_cache)/$name_pkg/";
		FileUtils.unlink(pkg + "info");
		var uninstall_dir = @"$pkg/uninstall";
		// If the package need to be removed (suprapack remove command is used)
		if (config.want_remove == true) {
			FileUtils.unlink(pkg + "required_by");
			// Uninstall Script
			if (FileUtils.test(uninstall_dir, FileTest.EXISTS)) {
				const string _remove = BOLD + YELLOW + "[Uninstall script]" + NONE + " ";
				print("%s[%s]\n", _remove, name_pkg);
				Utils.run({uninstall_dir}, Utils.prepare_envp(config.prefix));
				FileUtils.remove(uninstall_dir);
			}
		}
		DirUtils.remove(pkg);
	}


	/**
	 * return all package ever install
	 * @return all package ever install
	 */
	public Package []get_all_package () {
		try {
			Package []result = {};
			var dir = Dir.open(config.path_suprapack_cache);
			unowned string? tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp[0] != '.' && tmp != "pkg" && FileUtils.test(@"$(config.path_suprapack_cache)/$tmp", FileTest.IS_DIR))
					if (Query.is_exist(tmp))
						result += Package.from_file(@"$(config.path_suprapack_cache)/$tmp/info");
			}
			return result;
		} catch(Error e) {
			error(e.message);
		}
	}


	/**
	 * return all package ever install but only the name
	 * @return all package ever install
	 */
	public string []get_all_installed_pkg () {
		try {
			string []result = {};
			var dir = Dir.open(config.path_suprapack_cache);
			unowned string? tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp[0] != '.' && tmp != "pkg" && FileUtils.test(@"$(config.path_suprapack_cache)/$tmp", FileTest.IS_DIR))
					result += tmp;
			}
			return result;
		}
		catch (Error e) {
			error(e.message);
		}
	}
}
