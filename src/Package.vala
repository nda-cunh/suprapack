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
 * A Package is a struct that contains all the information about a package.
 * It can be created from a file or from user input.
 * it's like the SupraList package but with more information
 * A Package have always a info file
 *
 * @param name the name of the package
 * @param author the author of the package
 * @param version the version of the package
 * @param description the description of the package
 * @param binary the binary name of the package (for suprapack run command)
 * @param dependency the dependency of the package
 * @param optional_dependency the optional dependency of the package
 * @param size_tar the size of the tar file
 * @param size_installed the size of the installed package
 * @param installed_files the list of installed files
 * @param exclude_package the list of files to exclude from the package
 * @param output the output of the package
 * @param repo the repository of the package
 * @param arch the architecture of the package
 **/
public struct Package {
	string name;
	string author;
	string version;
	string description;
	string binary;
	string dependency;
	string optional_dependency;
	string size_tar;
	string size_installed;
	string installed_files;
	string exclude_package;
	string output;
	string repo;
	string arch;

	bool is_wanted;

	public void init () {
		this.is_wanted = false;
		this.name = "";
		this.author = "";
		this.version = "";
		this.description = "";
		this.binary = "";
		this.dependency = "";
		this.installed_files = "";
		this.optional_dependency = "";
		this.exclude_package = "";
		this.size_tar = "";
		this.size_installed = "";
		this.arch = "";
	}

	public string[] get_all_dependency () {
		var bs = new StrvBuilder();
		bs.addv (get_dependency ());
		bs.addv (get_optional_dependency ());
		return bs.end();
	}

	public string[] get_dependency () {
		var sp = this.dependency.split(" ");
		return (owned)sp;
	}
	
	public string[] get_optional_dependency () {
		var sp = this.optional_dependency.split(" ");
		return (owned)sp;
	}

	// constructor
	public Package.from_input() {
		try {
			this.name = Utils.get_input("Name: ");
			this.name = /\f\r\n\t\v /.replace(name, -1, 0, "");
			this.name = name.replace("_", "-");
			this.version = Utils.get_input("Version: ");
			this.version = /[^0-9.]/.replace(this.version, -1, 0, "");
			this.version = this.version.replace("-", ".");
			this.author = Utils.get_input("Author: ", false);
			this.description = Utils.get_input("Description: ", false);
			this.dependency = Utils.get_input("Dependency: ");
			this.optional_dependency = Utils.get_input("Optional Dependency: ");
			this.exclude_package = Utils.get_input("Exclude Package: ");
			print("Can be empty if %s is the binary name\n", this.name);
			this.binary = Utils.get_input("Binary: ", false);
			this.arch = Utils.get_input("Arch ((default)auto, any, amd64): ");
			if (this.arch == "" || this.arch == "auto") {
				this.arch = Utils.get_arch_host();
			}
			else {
				this.arch = Utils.get_arch_magik (this.arch);
			}
			this.size_tar = "";
			this.size_installed = "";
			this.installed_files = "";
		} catch (Error e) {
			printerr(e.message);
		}
	}

	private static Package build_from_string (string contents) throws Error {
		Package result = {}; 
		result.init ();
		unowned string @value;

		var lines = contents.split("\n");

		foreach (unowned var line in lines) {
			if (line == "[FILES]")
				break;

			int index = line.index_of_char(':');
			if (index == -1)
				continue;

			value = line.offset(index + 1)._strip();
			char c = line[0];

			switch (c) {
				case 'n':
					if (line.has_prefix("name")) {
						result.name = /\f\r\n\t\v /.replace(value, -1, 0, "");
					}
					break;
				case 'v':
					if (line.has_prefix("version")) {
						result.version = /[^0-9.]/.replace(value, -1, 0, "");
					}
					break;
				case 'a':
					if (line.has_prefix("arch")) {
						result.arch = value;
						if (result.arch == "" || result.arch == "auto") {
							result.arch = Utils.get_arch_host();
						}
					}
					else if (line.has_prefix("author"))
						result.author = value;
					break;
				case 'd':
					if (line.has_prefix("dependency"))
						result.dependency = value;
					else if (line.has_prefix("description"))
						result.description = value;
					break;
				case 's':
					if (line.has_prefix("size_tar"))
						result.size_tar = value;
					else if (line.has_prefix("size_installed"))
						result.size_installed = value;
					break;
				case 'o':
					if (line.has_prefix("optional_dependency"))
						result.optional_dependency = value;
					break;
				case 'e':
					if (line.has_prefix("exclude_package"))
						result.exclude_package = value;
					break;
				case 'b':
					if (line.has_prefix("binary"))
						result.binary = value;
					break;
				case 'w':
					if (line.has_prefix("wanted"))
						result.is_wanted = value == "yes" ? true : false;
					break;
				default:
					break;
			}
		}
		// End of parsing the info file

		if ("[FILES]" in contents) {
			value = contents.offset(contents.index_of("[FILES]") + 8);
			result.installed_files = value;
		}

		if (result.arch == "")
			result.arch = Utils.get_arch_host();

		if (result.binary == "")
			result.binary = result.name;

		return result;
	}

	public static Package from_file (string info_file) throws Error {
		string contents;
		FileUtils.get_contents(info_file, out contents);

		return Package.build_from_string (contents);
	}

	public static Package from_string (string contents) throws Error {
		return Package.build_from_string (contents);
	}

	/**
	 * return all installed files
	 * ex: suprapack return $prefix/bin/suprapack ...
	 *
	 * @return the list of installed files
	 */
	public string []get_installed_files() {
		string []sp = this.installed_files?.split("\n");

		if (sp == null || sp.length == 0)
			return {};
		if (sp[sp.length - 1] == "") {
			sp[sp.length -1] = null;
			sp.resize(sp.length - 1);
		}
		return ((owned)sp);
	}

	// public func
	public void create_info_file(string info_file) {
		var fs = FileStream.open(info_file, "w");
		if (fs == null)
			error("cant open %s", info_file);
		fs.printf("name: %s\n", this.name);
		fs.printf("version: %s\n", this.version);
		fs.printf("arch: %s\n", this.arch);
		fs.printf("author: %s\n", this.author);
		fs.printf("description: %s\n", this.description);
		fs.printf("dependency: %s\n", this.dependency);
		fs.printf("optional_dependency: %s\n", this.optional_dependency);
		fs.printf("exclude_package: %s\n", this.exclude_package);
		fs.printf("binary: %s\n", this.binary);
		fs.printf("size_tar: %s\n", this.size_tar);
		fs.printf("size_installed: %s\n", this.size_installed);
		fs.printf("wanted: %s\n", this.is_wanted ? "yes" : "no");
	}
}
