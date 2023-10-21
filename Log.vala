public const string BLANK = "                                                  ";
public const string BOLD = "\033[;1m";
public const string COM = "\033[;2m";
public const string INV = "\033[;7m";
public const string RED = "\033[31m";
public const string GREEN = "\033[32m";
public const string YELLOW = "\033[33m";
public const string WHITE = "\033[39m";
public const string CYAN = "\033[96m";
public const string PURPLE = "\033[35m";
public const string NONE = "\033[0m";

public void print_info(string msg) {
	print("\033[33;1m[SupraStore]\033[0m: %s\n", msg);
}

[NoReturn]
public void print_error(string msg) {
	print("\033[91;1m[Error]\033[0m: %s\n", msg);
	Process.exit(1);
}
		
int run_cmd(string []av) {
	try {
		var pid = new Subprocess.newv(av, SubprocessFlags.STDERR_SILENCE);
		pid.wait();
		return pid.get_status();
	} catch (Error e) {
		print_error(e.message);
	}
}
