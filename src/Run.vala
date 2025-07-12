namespace Shell {
	private void env_change (ref string []env, string variable, string value, bool no_last = false) {
		unowned string? last_variable = Environ.get_variable (env, variable);
		if (no_last)
			last_variable = null;
		string v = "%s/%s:%s".printf(config.prefix, value, last_variable ?? "");
		env = Environ.set_variable(env, variable, v, true);
	}


	private string[] load_env () {
		var env = Environ.get();
		env_change(ref env, "PATH", "bin");
		env_change(ref env, "LD_LIBRARY_PATH", "lib");
		env_change(ref env, "PKG_CONFIG_PATH", "share/pkgconfig");
		env_change(ref env, "PKG_CONFIG_PATH", "lib/pkgconfig");
		env_change(ref env, "XDG_DATA_DIRS", "share");
		env_change(ref env, "XDG_CONFIG_DIRS", "etc");
		env_change(ref env, "LD_LIBRARY_PATH", "lib");
		env_change(ref env, "LIBRARY_PATH", "lib");
		env_change(ref env, "C_INCLUDE_PATH", "include");
		env_change(ref env, "CPLUS_INCLUDE_PATH", "include");
		env_change(ref env, "PYTHONPATH", "lib/python3/dist-packages");
		env_change(ref env, "DOTNET_ROOT", "share/dotnet");
		env = Environ.set_variable (env, "PREFIX", config.prefix, true);
		return (owned)env;
	}

	[NoReturn]
		public void run_shell (string []args) throws Error {
			string ps1_contents;
			var env = load_env();

			var shell = Environ.get_variable(env, "SHELL") ?? "/bin/bash";
			if (shell == "/bin/zsh")
				ps1_contents = "%(?:%{\033[01;32m%}%1{➜%} :%{\033[01;31m%}%1{➜%} ) %{\033[36m%}%c%{\033[00m%} ";
			else
				ps1_contents = "\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ ";
			env = Environ.set_variable(env, "PS1", "\033[35m(suprapack) \033[0m" + ps1_contents, true);
			Process.exit(simple_run(args, env));
		}


	[NoReturn]
		public void run (string []args) throws Error {
			var env = load_env();
			Process.exit(simple_run(args, env));
		}

	inline int simple_run (string []args, string []env) throws Error
	{
		int status;
		Process.spawn_sync(null, args, env, SpawnFlags.SEARCH_PATH | SpawnFlags.CHILD_INHERITS_STDIN, null, null, null, out status);
		return Process.exit_status(status);
	}
}
