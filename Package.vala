// Package struct
// can build package
// can extract package



public struct Opt_dependency {
	string name;
	string lore;
}

public struct Package {
	string name;
	string author;
	string version; 
	string description;
	string binary;
	string dependency;
	List<Opt_dependency?> *optional_dependency;
	string size_tar;
	string size_installed;
	string installed_files;
	string exclude_package; 
	string output; 
	string repo; 
	List<int> list;

	public void init() {
		this.name = "";
		this.author = "";
		this.version = ""; 
		this.description = "";
		this.binary = "";
		this.dependency = "";
		this.installed_files = "";
		this.optional_dependency = new List<Opt_dependency?>();
		this.exclude_package = "";
		this.size_tar = "";
		this.size_installed = "";
	}

	// constructor
	public Package.from_input() {
		try {
			this.name = Utils.get_input("Name: ");
			this.name = /\f\r\n\t\v /.replace(name, -1, 0, "");
			this.version = Utils.get_input("Version: ");
			this.version = /[^0-9.]/.replace(this.version, -1, 0, "");
			this.version = this.version.replace("-", ".");
			this.author = Utils.get_input("Author: ", false);
			this.description = Utils.get_input("Description: ", false);
			/* Dependency */
			this.dependency = Utils.get_input("Dependency: ");
			/* Optional Dependency */
			// TODO
			var tmp_optional = Utils.get_input("Optional Dependency: ");

			var sp = /'\s*'?/.split(tmp_optional);
			foreach (var i in sp) {
				if (i == "")
					continue;
				this.optional_dependency->append({name: "abc", lore: "abc"});
			}
			/* Exclude Package */
			this.exclude_package = Utils.get_input("Exclude Package: ");
			print("Can be empty if %s is the binary name\n", this.name);
			this.binary = Utils.get_input("Binary: ", false);
			this.size_tar = "";
			this.size_installed = "";
			this.installed_files = "";
		} catch (Error e) {
			printerr(e.message);
		}
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
				if (line.has_prefix("name")) {
					this.name = value.strip();
					this.name = /\f\r\n\t\v /.replace(name, -1, 0, "");
				}
				else if (line.has_prefix("version")) {
					this.version = value.strip();
					this.version = /[^0-9.]/.replace(this.version, -1, 0, "");
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
				{
					var sp = /'\s*'?/.split(line);
					foreach (var i in sp) {
						if (i == "")
							continue;
						var index = i.index_of_char(':');
						var name = i[0:index].strip();
						var lore = i[index+1:].strip();
						this.optional_dependency->append({name: name, lore: lore});
					}
				}
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
			print_error(e.message);
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
			print_error(@"cant open $info_file");
		fs.printf("name: %s\n", this.name);
		fs.printf("version: %s\n", this.version);
		fs.printf("author: %s\n", this.author);
		fs.printf("binary: %s\n", this.binary);
		fs.printf("description: %s\n", this.description);
		fs.printf("dependency: %s\n", this.dependency);
		fs.printf("exclude_package: %s\n", this.exclude_package);
		// fs.printf("optional_dependency: %s\n", this.optional_dependency);
		fs.printf("size_tar: %s\n", this.size_tar);
		fs.printf("size_installed: %s\n", this.size_installed);
	}
}
