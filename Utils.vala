namespace Utils {
	int run(string []av, bool silence = false, string []envp = Environ.get()){
		int status;
		SpawnFlags flags;

		if (silence == true)
			flags = SEARCH_PATH_FROM_ENVP | CHILD_INHERITS_STDIN | STDERR_TO_DEV_NULL | STDOUT_TO_DEV_NULL;
		else
			flags = SEARCH_PATH_FROM_ENVP | CHILD_INHERITS_STDIN;
		try {
			Process.spawn_sync("/", av, envp, SpawnFlags.SEARCH_PATH | SpawnFlags.CHILD_INHERITS_STDIN, null, null, null, out status);
			return status;
		} catch (Error e) {
			print_error(e.message);
		}
	}
}
