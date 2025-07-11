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
				this.arch = Utils.get_arch();
			}
			this.size_tar = "";
			this.size_installed = "";
			this.installed_files = "";
		} catch (Error e) {
			printerr(e.message);
		}
	}

	public Package.from_file (string info_file) throws Error {
		string contents;
		unowned string @value;

		init();
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
			else if (line.has_prefix("arch")) {
				this.arch = value.strip();
				if (this.arch == "" || this.arch == "auto") {
					this.arch = Utils.get_arch();
				}
			}
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
			else if (line.has_prefix("wanted"))
				this.is_wanted = value.strip() == "yes" ? true : false;
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
