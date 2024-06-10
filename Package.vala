// Package struct
// can build package
// can extract package

public class Package {
	public string name;
	public string author;
	public string version; 
	public string description;
	public string binary;
	public string dependency;
	public string optional_dependency;
	public string size_tar;
	public string size_installed;
	public string installed_files;
	public string exclude_package; 
	public string output; 
	public string repo; 
	public List<List<string>> parse_dependency;


	public Package() {
		this.parse_dependency = new List<List<string>>();
		this.name = "";
		this.author = "";
		this.version = ""; 
		this.description = "";
		this.dependency = "";
		this.binary = "";
		this.installed_files = "";
		this.optional_dependency = "";
		this.exclude_package = "";
		this.size_tar = "";
		this.size_installed = "";
	}

	// constructor
	public static Package from_input() {
		var self = new Package();
		try {
			self.name = Utils.get_input("Name: ");
			self.name = /\f\r\n\t\v /.replace(self.name, -1, 0, "");
			self.version = Utils.get_input("Version: ");
			self.version = /[^0-9.]/.replace(self.version, -1, 0, "");
			self.version = self.version.replace("-", ".");
			self.author = Utils.get_input("Author: ", false);
			self.description = Utils.get_input("Description: ", false);
			self.dependency = Utils.get_input("Dependency: ");
			self.optional_dependency = Utils.get_input("Optional Dependency: ");
			self.exclude_package = Utils.get_input("Exclude Package: ");
			print("Can be empty if %s is the binary name\n", self.name);
			self.binary = Utils.get_input("Binary: ", false);
			self.size_tar = "";
			self.size_installed = "";
			self.installed_files = "";
		} catch (Error e) {
			printerr(e.message);
		}
		return self;
	}
	
	public static Package from_file(string info_file) {
		var self = new Package();

		string contents;
		unowned string @value;

		try {
			FileUtils.get_contents(info_file, out contents);
			var lines = contents.split("\n");
			
			foreach (unowned var line in lines) {
				if (line == "[FILES]")
					break;
				value = line.offset(line.index_of_char(':') + 1);
				if (line.has_prefix("name")) {
					self.name = value.strip();
					self.name = /\f\r\n\t\v /.replace(self.name, -1, 0, "");
				}
				else if (line.has_prefix("version")) {
					self.version = value.strip();
					self.version = /[^0-9.]/.replace(self.version, -1, 0, "");
				}
				else if (line.has_prefix("author"))
					self.author = value.strip();
				else if (line.has_prefix("description"))
					self.description = value.strip();
				else if (line.has_prefix("binary"))
					self.binary = value.strip();
				else if (line.has_prefix("dependency"))
					self.dependency = value.strip();
				else if (line.has_prefix("optional_dependency"))
					self.optional_dependency = value.strip();
				else if (line.has_prefix("size_tar"))
					self.size_tar = value.strip();
				else if (line.has_prefix("size_installed"))
					self.size_installed = value.strip();
				else if (line.has_prefix("exclude_package"))
					self.exclude_package = value.strip();
			}
			if ("[FILES]" in contents) {
				value = contents.offset(contents.index_of("[FILES]") + 8);
				self.installed_files = value;
			}
			if (self.binary == "")
				self.binary = self.name;

			/* Parse all dependency */

			self.parse_dependency = Utils.parse_dependency(self.dependency);
		} catch (Error e) {
			error(e.message);
		}
		return self;
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
		fs.printf("exclude_package: %s\n", this.exclude_package);
		fs.printf("optional_dependency: %s\n", this.optional_dependency);
		fs.printf("size_tar: %s\n", this.size_tar);
		fs.printf("size_installed: %s\n", this.size_installed);
	}
}
