// Package struct
// can build package
// can extract package

public struct Package {
	string name;
	string author;
	string version; 
	string icon;
	// constructor
	public Package.from_input() {
		this.name = get_input("Name: ");
		this.version = get_input("Version: ");
		this.author = get_input("Author: ");
		this.icon = get_input("Icon: ");
	}

	public Package.from_file(string info_file) {
		var fs = FileStream.open(info_file, "r");
		if (fs == null)
			print_error(@"$info_file ne peut pas etre ouvert.");
		string line;
		unowned string @value;
		unowned string start;
		while ((line = fs.read_line()) != null) {
			start = line; 
			value = line.offset(line.index_of_char(':') + 2);
			value.data[-2] = '\0';

			if (start == "name")
				this.name = value;
			if (start == "version")
				this.version = value;
			if (start == "author")
				this.author = value;
			if (start == "icon")
				this.icon = value;
		}
	}
	
	// public func 
	public void create_info_file(string info_file) {
		var fs = FileStream.open(info_file, "w");
		if (fs == null)
			print_error(@"cant open $info_file");
		fs.printf("name: %s\n", this.name);
		fs.printf("version: %s\n", this.version);
		fs.printf("author: %s\n", this.author);
		fs.printf("icon: %s\n", this.icon);
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
