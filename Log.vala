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

[CCode (cname = "printf", cheader_filename="stdio.h")]
extern int printf(string str, ...);


public void init_message () {
	Log.set_default_handler((type, level, message)=> {
		unowned string real_message;
		var len = message.index_of_char(':') + 1;
		real_message = message.offset(len);
		len += real_message.index_of_char(':') + 2;
		real_message = message.offset(len);

		switch (level) {
			case LogLevelFlags.LEVEL_WARNING:
				print("\033[33m[WARNING]\033[0m: %s \033[35m(", real_message);
				stdout.write(message[0:len - 2].data);
				print(")\033[0m\n");
				break;
			case LogLevelFlags.LEVEL_CRITICAL:
				print("\033[31m[Critical]\033[0m: %s\n", message);
				break;
			case LogLevelFlags.LEVEL_MESSAGE:
				print("\033[32m[SupraPack]\033[0m: %s\n", message);
				break;
			case LogLevelFlags.LEVEL_DEBUG:
				if (Environment.get_variable ("G_MESSAGES_DEBUG") != null) {
					print("\033[35m[Debug]\033[0m: %s \033[35m(", real_message);
					stdout.write(message[0:len - 2].data);
					print(")\033[0m\n");
				}
				break;
			case LogLevelFlags.LEVEL_INFO:
				if (type == null)
					print("\033[35m[Info]\033[0m: %s\n", real_message);
				else
					print("%s: %s\n", type, real_message);
				break;
			case LogLevelFlags.FLAG_RECURSION:
			case LogLevelFlags.FLAG_FATAL:
			case LogLevelFlags.LEVEL_ERROR:
			default:
				print("\033[31m[Error]\033[0m: %s \033[35m(", real_message);
				stdout.write(message[0:len - 2].data);
				print(")\033[0m\n");
				Process.exit(-1);
		}
	});
}

errordomain ErrorSP {
	ACCESS,
	FAILED,
	CANCEL,
	BADFILE
	
}

public void debug(string type, string msg, ...) {
	logv(type, LogLevelFlags.LEVEL_DEBUG, msg, va_list());
}
	
public void print_info(string? msg, string prefix = "SupraPack", string color = "\033[33;1m") {
	string type = "%s[%s]\033[0m".printf(color, prefix);
	log(type, LogLevelFlags.LEVEL_INFO, msg ?? "");
}
