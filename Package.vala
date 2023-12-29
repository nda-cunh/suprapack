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
	string installed_files;


	private void init() {
		this.name = "";
		this.author = "";
		this.version = ""; 
		this.description = "";
		this.binary = "";
		this.dependency = "";
		this.installed_files = "";
	}

	// constructor
	public Package.from_input() {
		this.name = Utils.get_input("Name: ");
		this.version = Utils.get_input("Version: ");
		this.version = this.version.replace("-", ".");
		this.author = Utils.get_input("Author: ");
		this.description = Utils.get_input("Description: ");
		this.dependency = Utils.get_input("Dependency: ");
		print("Can be empty if %s is the binary name\n", this.name);
		this.binary = Utils.get_input("Binary: ");
		this.installed_files = "";
	}
	
	public Package.from_file(string info_file) {
		string contents;
		size_t len;
		unowned string @value;

		init();
		try {
			FileUtils.get_contents(info_file, out contents, out len);
			var lines = contents.split("\n");
			
			foreach (var line in lines) {
				if (line == "[FILES]")
					break;
				value = line.offset(line.index_of_char(':') + 1);
				if (line.has_prefix("name"))
					this.name = value.strip();
				if (line.has_prefix("version"))
					this.version = value.strip();
				if (line.has_prefix("author"))
					this.author = value.strip();
				if (line.has_prefix("description"))
					this.description = value.strip();
				if (line.has_prefix("binary"))
					this.binary = value.strip();
				if (line.has_prefix("dependency"))
					this.dependency = value.strip();
			}
			if ("[FILES]" in contents) {
				value = contents.offset(contents.index_of("[FILES]") + 8);
				installed_files = value;
			}
			if (this.binary == "")
				this.binary = this.name;
		} catch (Error e) {
			print_error(e.message);
		}
	}

	public string []get_installed_files() {
		var sp = this.installed_files.split("\n");
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
			print_error(@"cant open $info_file");
		fs.printf("name: %s\n", this.name);
		fs.printf("version: %s\n", this.version);
		fs.printf("author: %s\n", this.author);
		fs.printf("binary: %s\n", this.binary);
		fs.printf("description: %s\n", this.description);
		fs.printf("dependency: %s\n", this.dependency);
	}
}
