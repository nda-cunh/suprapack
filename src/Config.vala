/**
 * This class contains all the configuration of the package manager
 * It's used to store the configuration of the user and the package
 **/
public class Config : Object {

	public Config () throws Error {
		// If the user is a root user, we need to change the prefix to /usr
		if (SupraUnix.is_root ())
			this.change_prefix ("/usr");
		else
			this.change_prefix (@"$HOME/.local");
		this.load_config();
		var prefix_tmp = Environ.get_variable(Environ.get(), "PREFIX");
		if (prefix_tmp != null)
			this.change_prefix(prefix_tmp);
		queue_pkg = new PackageSet();
		create_source_profile();
	}

	void create_source_profile () throws Error {
		var profile = @"$HOME/.suprapack_profile";
		if (FileUtils.test(profile, FileTest.EXISTS) == false) {
var str = """# Prefix:%1$s
export PATH=$PATH:%1$s/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%1$s/lib
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:%1$s/share/pkgconfig:%1$s/lib/pkgconfig
export XDG_DATA_DIRS=$XDG_DATA_DIRS:%1$s/share
export XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:%1$s/etc
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:%1$s/lib"
export LIBRARY_PATH="$LIBRARY_PATH:%1$s/lib"
export C_INCLUDE_PATH="$C_INCLUDE_PATH:%1$s/include"
export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:%1$s/include"
export GSETTINGS_SCHEMA_DIR=%1$s/share/glib-2.0/schemas/
export PYTHONPATH="$PYTHONPATH:%1$s/lib/python3/dist-packages"
export DOTNET_ROOT=%1$s/share/dotnet
export fpath=(%1$s/bin $fpath)
""".printf(this.prefix);
			FileUtils.set_contents(profile, str);
		}

	}

	public void change_strap (string prefix_strap) {
		this.strap = prefix_strap;
	}

	public void change_prefix (string prefix) throws Error {
		string contents;
		var new_prefix = prefix;
		var new_suprapack_cache = prefix + "/.suprapack";
		var new_config = new_suprapack_cache + "/user.conf";
		var new_repo_list = new_suprapack_cache + "/repo.list";

		DirUtils.create_with_parents(new_prefix, 0755);
		DirUtils.create_with_parents(new_suprapack_cache, 0755);
		if (FileUtils.test (new_suprapack_cache, FileTest.EXISTS) == false) {
			DirUtils.create(new_suprapack_cache, 0755);
		}
		if (FileUtils.test (new_config, FileTest.EXISTS) == false) {
			FileUtils.set_contents (new_config, "is_cached:false");
		}
		if (FileUtils.test (new_repo_list, FileTest.EXISTS) == false) {
			if (FileUtils.test(this.repo_list, FileTest.EXISTS)) {
				info("[Repo] Copy all %s content in new prefix", this.prefix);
				FileUtils.get_contents (this.repo_list, out contents);
				FileUtils.set_contents (new_repo_list, contents);
			}
			else
				FileUtils.set_contents (new_repo_list, "");
		}

		this.prefix = (owned)new_prefix;
		this.path_suprapack_cache = (owned)new_suprapack_cache;
		this.config = (owned)new_config;
		this.repo_list = (owned)new_repo_list;
		this.strap = this.prefix;
	}

	private void load_config () throws Error{
		string contents;
		FileUtils.get_contents (this.config, out contents);

		var lines = contents.split("\n");
		var reg = /^([^:]+)[:]([^\s]+)$/;
		foreach (unowned var line in lines) {
			if (!reg.match(line))
				continue;
			if (line.has_prefix ("is_cached")) {
				is_cached = bool.parse(line[line.index_of_char(':') + 1:]);
			}
			else if (line.has_prefix ("show_script")) {
				show_script = bool.parse(line[line.index_of_char(':') + 1:]);
			}
			else if (line.has_prefix ("prefix")) {
				this.change_prefix(line[line.index_of_char(':') + 1:].replace("~", HOME));
			}
		}

	}


	private inline string parse_bool (string str) {
		string tmp;
		bool res;
		tmp = str._strip ().ascii_down ();
		if (bool.try_parse (tmp, out res) == false)
			warning ("Error: %s is not a boolean", str);
		return res.to_string ();
	}

	/**
	 * Parse the command line arguments (ARGV)
	 *
	 * @param argv: the command line arguments
	 * @return: true if the arguments are valid, false otherwise
	 **/
	public void parse (ref unowned string []argv) throws Error {
		string? _prefix_ = null;
		string? _show_script_ = null;
		string? _is_cached_ = null;

		OptionEntry options[4];
		options[0] = { "prefix", 'p', OptionFlags.NONE, OptionArg.STRING, ref _prefix_, "Path to the folder", "PATH"};
		options[1] = { "is_cached", 'c', OptionFlags.NONE, OptionArg.STRING, ref _is_cached_, "Keep the package in the cache", "bool"};
		options[2] = { "show_script", 's', OptionFlags.NONE, OptionArg.STRING, ref _show_script_, "Show the script before installing", "bool"};
		options[3] = {null};

		var opt_context = new OptionContext ("Config");
		opt_context.add_main_entries (options, null);
		opt_context.set_summary ("Set the configuration of the package manager");
		opt_context.set_help_enabled(true);

		if (argv.length == 2)  {
			opt_context.parse(ref argv);
			print (opt_context.get_help (true, null));
			return ;
		}

		// Parse the command line
		opt_context.parse(ref argv);

		if (_prefix_ != null)
			this.add ("prefix", _prefix_);
		if (_is_cached_ != null)
			this.add("is_cached", parse_bool (_is_cached_));
		if (_show_script_ != null)
			this.add("show_script", parse_bool (_show_script_));
		string contents;
		FileUtils.get_contents (this.config, out contents);
		print ("[NewFile]:\n  %s\n", contents.replace("\n", "\n  "));
	}

	/**
	 * Add a new config to the config file
	 * @param key: the key to add
	 * @param value: the value to add
	 */


	private void add (string key, string value) throws Error {
		var new_contents = new StringBuilder();
		string contents;
		FileUtils.get_contents (this.config, out contents);

		foreach (unowned var line in contents.split("\n")) {
			if (!line.has_prefix (key)) {
				new_contents.append(line);
				new_contents.append_c ('\n');
			}
		}
		new_contents.append_printf ("%s:%s", key, value);
		FileUtils.set_contents(this.config, new_contents.str);
	}

	/**
	 * Check if the architecture is the same as the current architecture
	 *
	 * @param arch: the architecture to check
	 * @return: true if the architecture is the same, false otherwise
	 */
	public static bool is_my_arch (string arch) throws Error {
		unowned string arch_actual = Utils.get_arch ();
		if ("any" in arch)
			return true;
		if (arch == arch_actual)
			return true;
		return false;
	}



	/***************************************
	 * Variables used by the package manager
	 ****************************************/

	public PackageSet queue_pkg;
	public unowned string[] cmd;
	public bool want_remove 	{get; set; default=false;}

	// If the user want to show the script before installing (pre_install and post_install)
	public bool show_script 	{get; private set; default=false;}
	// If suprapack need keep the package in the cache ($HOME/.local/.suprapack/pkg)
	public bool is_cached		{get; private set; default=false;}
	// The path of the repolist ($HOME/.local/.suprapack/repo.list)
	public string repo_list 	{get; private set;}
	// The path of the config ($HOME/.local/.suprapack/user.conf)
	public string config		{get; private set;}
	// The path of the cache ($HOME/.local/.suprapack/)
	public string path_suprapack_cache			{get; private set;}


	/*********************************
	 * Options from the command line
	 **********************************/

	// The prefix where the package will be installed
	public string prefix		{get; private set; default=@"$HOME/.local";}
	// The strap is the prefix where the package will be installed like pacstrap
	public string strap			{get; private set;}
	// Force the installation of the package with all dependencies
	public bool force			{get; set; default=false;}
	// Force the installation of the package without check an update
	public bool supraforce		{get; set; default=false;}
	// Used by other program, it print 0,1,2,3,4,5 instead % for download and install
	public bool simple_print	{get; set; default=false;}
	// if the user want to use fakeroot when building the package
	public bool use_fakeroot	{get; set; default=true;}
	// if the user want to answer yes to all the question
	public bool allays_yes		{get;set;default=false;}
	// if the package need to be install after the build
	public bool build_and_install {get; set; default=false;}
	// where the package will be moved after the build
	public string? build_output 		{get; set;default=null;}
	/**
	 * Pour chaque paquetage demandé, le supprime avec toutes ses dépendances, à condition que ces dépendances (A) ne soient pas nécessaires à un autre paquetage installé et (B) qu'elles n'aient pas été installées explicitement par l'utilisateur. Pour se passer de la condition (B), appeler l'option deux fois sur la même ligne de commande.
	 **/
	public bool is_recursive_uninstall {get; set; default=true;}
}
