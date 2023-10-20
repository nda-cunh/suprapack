public string? PREFIX = null;
public string? LOCAL = null;

void build_package(string usr_dir) {
	if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
		print_error(@"$usr_dir is not a dir or doesn't exist");
	var pkg = Package.from_input();
	pkg.create_info_file(@"$usr_dir/info");

	var name_pkg = @"$(pkg.name)-$(pkg.version)";
	string []av = {"tar", "-cf", @"$(name_pkg).suprapack", "-C", usr_dir, "."};
	try {
		var tar = new Subprocess.newv(av, SubprocessFlags.STDERR_SILENCE);
		tar.wait();
	} catch(Error e) {
		print_error(e.message);
	}
	print_info(@"$(name_pkg).suprapack is created\n");
}

[NoReturn]
void cmd_install(string []av) {
	if (av.length == 2)
		print_error("`suprastore install [...]`");	
	install(av[2]);
	Process.exit(0);
}

[NoReturn]
void cmd_build(string []av) {
	if (av.length == 2)
		print_error("`suprastore build [...]`");	
	build_package(av[2]);
	Process.exit(0);
}

[NoReturn]
void cmd_list(string []av) {
	var list = SupraList.get();
	unowned string name;
	unowned string version;
	foreach(var i in list) {
		name = i;
		version = i.offset(i.index_of_char('-') + 1);
		version.data[-1] = '\0'; 
		version.offset(version.last_index_of_char('.')).data[0] = '\0';
		print("%s [%s]\n", name, version);
	}
	Process.exit(0);
}

[NoReturn]
void cmd_help(string []av) {
	print(@"$(BOLD)$(INV)                            Help                            $(NONE)\n");
	print(@"$(BOLD)suprastore$(NONE) help\n");
	print(@"$(BOLD)suprastore$(NONE) install package         Install package from repo\n");
	print(@"$(BOLD)suprastore$(NONE) update package          Update only the package\n");
	print(@"$(BOLD)suprastore$(NONE) update                  Update All\n");
	print(@"$(BOLD)suprastore$(NONE) list                    List all package in repo\n");
	print(@"$(BOLD)suprastore$(NONE) list package            List all files of package\n");
	print(@"\n");
	print(@"$(BOLD)$(COM)[Dev Only]$(NONE)\n");
	print(@"$(BOLD)suprastore$(NONE) build PREFIX  Build a file.suprapack\n");
	print(@"$(BOLD)suprastore$(NONE) your_package.suprapack  Install a file.suprapack\n");
	print(@"$(CYAN)PREFIX is a folder with this directory like: $(NONE)\n");
	print(@"$(CYAN)'bin' 'share' 'lib'$(NONE)\n");
	print(@"$(CYAN)Example: suprapatate/bin/suprapatate `suprastore build suprapatate`$(NONE)\n");
	print(@"$(BOLD)$(INV)                                                            $(NONE)\n");
	Process.exit(0);
}

public class Main {

	public void all_cmd(string []args) {
		if (args.length < 2)
			cmd_help(args);
		
		// 1 argv (suprapack)
		if (FileUtils.test(args[1], FileTest.EXISTS)) {
			install_package(args[1]);
			return ;
		}

		if (args[1].match_string("list", true))
			cmd_list(args);
		if (args[1].match_string("build", true))
			cmd_build(args);
		if (args[1].match_string("help", true))
			cmd_help(args);
		if (args[1].match_string("install", true))
			cmd_install(args);
		print_error("La commande n'existe pas.");
	}


	// INIT
	public Main(string []args) {
		PREFIX = Environment.get_home_dir() + "/.local";
		LOCAL = Environment.get_home_dir() + "/suprastore";
		Intl.setlocale();
		all_cmd(args);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
