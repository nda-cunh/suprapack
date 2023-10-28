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


	public Package.from_file(string info_file) {
	}

	public string []get_installed_files() {
		return ({"a", "b", "c"});
	}
	
	// public func 
	public void create_info_file(string info_file) {
	}
}
