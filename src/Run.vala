private void env_change(ref string []env, string variable, string value, bool no_last = false) {
	unowned string? last_variable = Environ.get_variable (env, variable);
	if (no_last)
		last_variable = null;
	string v = "%s/%s:%s".printf(config.prefix, value, last_variable ?? "");
	env = Environ.set_variable(env, variable, v, true);
}

[NoReturn]
public void run (string []args) throws Error {

	var env = Environ.get();
	env_change(ref env, "LD_LIBRARY_PATH", "lib");
	env_change(ref env, "LIBRARY_PATH", "lib");
	env_change(ref env, "C_INCLUDE_PATH", "include");
	env_change(ref env, "CPLUS_INCLUDE_PATH", "include");
	env_change(ref env, "PATH", "bin");
	env_change(ref env, "XDG_DATA_DIRS", "share");
	env_change(ref env, "PKG_CONFIG_PATH", "share/pkgconfig", true);
	env_change(ref env, "PKG_CONFIG_PATH", "lib/pkgconfig");
	env = Environ.set_variable(env, "PS1", "%B%F{blue}(Suprapack)%f%b%~ $ ", true);

	int status;
	Process.spawn_sync(null, args, env, SpawnFlags.SEARCH_PATH | SpawnFlags.CHILD_INHERITS_STDIN, null, null, null, out status);
	Process.exit(Process.exit_status(status));
}
