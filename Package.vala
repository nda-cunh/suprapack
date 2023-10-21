// Package struct
// can build package
// can extract package

public struct Package {
	string name;
	string author;
	string version; 
	string description;
	string binary;
	string installed_files;


	// constructor
	public Package.from_input() {
		this.name = get_input("Name: ");
		this.version = get_input("Version: ");
		this.author = get_input("Author: ");
		this.description = get_input("Description: ");
		this.binary = get_input("Binary: ");
	}

	public Package.from_file(string info_file) {
		var fs = FileStream.open(info_file, "r");
		if (fs == null)
			print_error(@"$info_file ne peut pas etre ouvert.");
		string line;
		unowned string @value;
		unowned string start;
		while ((line = fs.read_line()) != null) {
			if (line == "[FILES]")
				break;
			start = line; 
			value = line.offset(line.index_of_char(':') + 2);
			value.data[-2] = '\0';

			if (start == "name")
				this.name = value;
			if (start == "version")
				this.version = value;
			if (start == "author")
				this.author = value;
			if (start == "description")
				this.description = value;
			if (start == "binary")
				this.binary = value;
		}
		if (line == "[FILES]") {
			// read all installed files
			uint8 buffer[8192];
			size_t len = 0;
			this.installed_files = "";
			while ((len = fs.read(buffer)) > 0) {
				buffer[len] = '\0';
				installed_files += (string)buffer;
			}
		}
			this.name = this.name ?? "";
			this.version = this.version ?? "";
			this.author = this.author ?? "";
			this.description = this.description ?? "";
			this.binary = this.binary ?? "";
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
	}
	
	// private func
	private string get_input(string msg) {
		print(msg);
		string? str = stdin.read_line();
		if (str != null)
			str = str.down();
		return str;
	}
}
