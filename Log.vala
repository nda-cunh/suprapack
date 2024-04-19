public const string BLANK = "                                                  ";
public const string BOLD = "\033[;1m";
public const string COM = "\033[;2m";
public const string INV = "\033[;7m";
public const string RED = "\033[31m";
public const string GREEN = "\033[32m";
public const string YELLOW = "\033[33m";
public const string GREY = "\033[37m";
public const string WHITE = "\033[39m";
public const string CYAN = "\033[96m";
public const string PURPLE = "\033[35m";
public const string NONE = "\033[0m";
public const string CURSOR = "\033[?25l";
public const string ENDCURSOR= "\033[?25h";

errordomain ErrorSP {
	ACCESS,
	FAILED,
	CANCEL,
	BADFILE
	
}

public void print_info(string? msg, string prefix = "SupraPack", string color = "\033[33;1m") {
	if (msg == null)
		print("%s[%s]\033[0m\n", color, prefix);
	else
		print("%s[%s]\033[0m: %s\n", color, prefix, msg);
}

public void print_update(string msg) {
	print("\033[93;1m[Update]\033[0m: %s\n", msg);
}

[NoReturn]
public void print_error(string msg) {
	print("\033[91;1m[Error]\033[0m: %s\n", msg);
	Process.exit(1);
}

public void printerror(string msg)
{
	print("\033[91;1m[Error]\033[0m: %s\n", msg);
}
