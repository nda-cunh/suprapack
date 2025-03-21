// Package struct
// can build package
// can extract package

/**
 * A Package is a struct that contains all the information about a package.
 * It can be created from a file or from user input.
 * it's like the SupraList package but with more information
 *
 * @name: the name of the package
 * @author: the author of the package
 * @version: the version of the package
 * @description: the description of the package
 * @binary: the binary name of the package (for suprapack run command)
 * @dependency: the dependency of the package
 * @optional_dependency: the optional dependency of the package
 * @size_tar: the size of the tar file
 * @size_installed: the size of the installed package
 * @installed_files: the list of installed files
 * @exclude_package: the list of files to exclude from the package
 * @output: the output of the package
 * @repo: the repository of the package
 * @arch: the architecture of the package
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


	public void init () {
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
				this.arch = Utils.get_arch();
			}
			this.size_tar = "";
			this.size_installed = "";
			this.installed_files = "";
		} catch (Error e) {
			printerr(e.message);
		}
	}

	public Package.from_file (string info_file) {
		string contents;
		unowned string @value;

		init();
		try {
			FileUtils.get_contents(info_file, out contents);
			var lines = contents.split("\n");

			foreach (unowned var line in lines) {
				if (line == "[FILES]")
					break;
				value = line.offset(line.index_of_char(':') + 1);
				if (line.has_prefix("name")) {
					this.name = value.strip();
					this.name = /\f\r\n\t\v /.replace(name, -1, 0, "");
				}
				else if (line.has_prefix("version")) {
					this.version = value.strip();
					this.version = /[^0-9.]/.replace(this.version, -1, 0, "");
				}
				else if (line.has_prefix("arch"))
					this.arch = value.strip();
				else if (line.has_prefix("author"))
					this.author = value.strip();
				else if (line.has_prefix("description"))
					this.description = value.strip();
				else if (line.has_prefix("binary"))
					this.binary = value.strip();
				else if (line.has_prefix("dependency"))
					this.dependency = value.strip();
				else if (line.has_prefix("optional_dependency"))
					this.optional_dependency = value.strip();
				else if (line.has_prefix("size_tar"))
					this.size_tar = value.strip();
				else if (line.has_prefix("size_installed"))
					this.size_installed = value.strip();
				else if (line.has_prefix("exclude_package"))
					this.exclude_package = value.strip();
			}
			if ("[FILES]" in contents) {
				value = contents.offset(contents.index_of("[FILES]") + 8);
				installed_files = value;
			}
			if (this.arch == "") {
				this.arch = Utils.get_arch();
			}
			if (this.binary == "")
				this.binary = this.name;
		} catch (Error e) {
			error("%s (%s)", e.message, info_file);
		}
	}

	/**
	 * return all installed files
	 * ex: suprapack return $prefix/bin/suprapack ...
	 *
	 * @return: the list of installed files
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
			error(@"cant open $info_file");
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
	}
}
