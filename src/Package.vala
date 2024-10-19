// Package struct
// can build package
// can extract package

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


	public void init() {
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
				string content;
				Process.spawn_command_line_sync("uname -s -p", out content);
				if (content == "Linux x86_64")
					this.arch = "amd64-Linux";
				else if (content == "Linux i686")
					this.arch = "i686-Linux";
				else if (content == "Linux armv7l")
					this.arch = "armhf-Linux";
				else if (content == "Linux aarch64")
					this.arch = "arm64-Linux";
				else if (content == "Linux armv6l")
					this.arch = "armel-Linux";
				else if (content == "Linux armv5tel")
					this.arch = "armel-Linux";
				else if (content == "Linux armv5tejl")
					this.arch = "armel-Linux";
				else if (content == "Darwin x86_64")
					this.arch = "amd64-Darwin";
				else if (content == "Darwin i686")
					this.arch = "i686-Darwin";
				else if (content == "Darwin arm64")
					this.arch = "arm64-Darwin";
				else
					this.arch = "any";
			}
			this.size_tar = "";
			this.size_installed = "";
			this.installed_files = "";
		} catch (Error e) {
			printerr(e.message);
		}
	}

	public Package.from_file(string info_file) {
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
			if (this.binary == "")
				this.binary = this.name;
		} catch (Error e) {
			error(e.message);
		}
	}

	public string []get_installed_files() {
		string []sp = this.installed_files?.split("\n");

		if (sp == null || sp.length == 0)
			return {};
		if (sp[sp.length - 1] == "") {
			sp[sp.length -1] = null;
			sp.resize(sp.length - 1);
		}
		return (sp);
	}

	// public func
	public void create_info_file(string info_file) {
		var fs = FileStream.open(info_file, "w");
		if (fs == null)
			error(@"cant open $info_file");
		fs.printf("name: %s\n", this.name);
		fs.printf("version: %s\n", this.version);
		fs.printf("author: %s\n", this.author);
		fs.printf("binary: %s\n", this.binary);
		fs.printf("description: %s\n", this.description);
		fs.printf("dependency: %s\n", this.dependency);
		fs.printf("arch: %s\n", this.arch);
		fs.printf("exclude_package: %s\n", this.exclude_package);
		fs.printf("optional_dependency: %s\n", this.optional_dependency);
		fs.printf("size_tar: %s\n", this.size_tar);
		fs.printf("size_installed: %s\n", this.size_installed);
	}
}
