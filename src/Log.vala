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

public class LogObject : Object {

	public static void logfunc(string? type, LogLevelFlags levels, string message) {
		unowned string real_message;
		real_message = message;
		int len;

		switch (levels) {
			case LogLevelFlags.LEVEL_WARNING:
				stderr.printf("\033[33m[WARNING]\033[0m %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.LEVEL_CRITICAL:
				stderr.printf("\033[31m[Critical]\033[0m %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.LEVEL_MESSAGE:
				print("\033[32m[SupraPack]\033[0m %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.LEVEL_DEBUG:
				if (Environment.get_variable ("G_MESSAGES_DEBUG") != null) {
					stderr.printf("\033[32m[Debug]\033[0m %s", text_to_debug (message, out len));
					print_line_debug(message, len);
				}
				break;
			case LogLevelFlags.LEVEL_INFO:
				const string type_default = "\033[37m[Info]\033[0m";
				print("%s: %s", type ?? type_default, text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.FLAG_RECURSION:
			case LogLevelFlags.FLAG_FATAL:
			case LogLevelFlags.LEVEL_ERROR:
			default:
				stderr.printf("\033[31m[Error]\033[0m %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				Process.exit(-1);
		}
	}

	private static void print_line_debug (string text, int len) {
		if (len != -1)
			stderr.printf ("\033[35m (%.*s)\033[0m", len - 2, text);
		stderr.printf("\n");
	}

	private static unowned string text_to_debug (string text, out int len) {
		unowned string real_message;
		len = text.index_of_char(':') + 1;
		if (len == 0) {
			len = -1;
			return text;
		}
		real_message = text.offset(len);
		len += real_message.index_of_char(':') + 2;
		real_message = text.offset(len);
		if (debug == true) {
			len = -1;
			return real_message;
		}
		return real_message;
	}

	private static bool? _debug = null;
	private static bool debug {
		get {
			if (_debug == null) {
				if (Environment.get_variable ("G_MESSAGES_DEBUG") == null) {
					_debug = true;
				} else {
					_debug = false;
				}
			}
			return _debug;
		}
	}
}

public void init_message () {
	GLib.Log.set_default_handler(LogObject.logfunc);
}


errordomain ErrorSP {
	ACCESS,
	FAILED,
	CANCEL,
	NOT_FOUND,
	BADFILE

}

namespace Log {

	[Diagnostics]
	public unowned string vala_line(string do_not_touch = "") {
		return do_not_touch;
	}

	[Diagnostics]
	public void debug (string type, string msg, ...) {
		logv(type, LogLevelFlags.LEVEL_DEBUG, msg, va_list());
	}

	[Diagnostics]
	public void info (string format, ...) {
		const string type = "\033[37m[Info]\033[0m";
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void skip (string format, ...) {
		const string type = "\033[33;1m[Skip]\033[0m";
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void suprapack (string format, ...) {
		const string type = "\033[33;1m[Suprapack]\033[0m";
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void download (string format, ...) {
		const string type = "\033[33;1m[Download]\033[0m";
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void conflict (string format, ...) {
		const string type = "\033[31;1m[Conflict]\033[0m";
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}
}
