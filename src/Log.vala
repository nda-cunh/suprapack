/*
 * This file is part of SupraPack.
 *
 * SupraPack is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SupraPack is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2025 SupraCorp - Nathan Da Cunha (nda-cunh)
 */

public const string BLANK = "                                                  ";
public const string BOLD = "\033[;1m";
public const string COM = "\033[;2m";
public const string INV = "\033[;7m";
public const string RED = "\033[31m";
public const string GREEN = "\033[32m";
public const string YELLOW = "\033[33m";
public const string BLUE = "\033[34m";
public const string PURPLE = "\033[35m";
public const string MAGENTA = "\033[36m";
public const string GREY = "\033[37m";
public const string WHITE = "\033[39m";
public const string CYAN = "\033[96m";
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
				stderr.printf(YELLOW + "[WARNING]" + NONE + " %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.LEVEL_CRITICAL:
				stderr.printf(RED + "[Critical]" + NONE + " %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.LEVEL_MESSAGE:
				print(GREEN + "[SupraPack]" + NONE + " %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.LEVEL_DEBUG:
				if (debug == true) {
					stderr.printf(GREEN + "[Debug]" + NONE + " %s", text_to_debug (message, out len));
					print_line_debug(message, len);
				}
				break;
			case LogLevelFlags.LEVEL_INFO:
				const string type_default = GREY + "[Info]" + NONE;
				print("%s: %s", type ?? type_default, text_to_debug (message, out len));
				print_line_debug(message, len);
				break;
			case LogLevelFlags.FLAG_RECURSION:
			case LogLevelFlags.FLAG_FATAL:
			case LogLevelFlags.LEVEL_ERROR:
			default:
				stderr.printf(RED + "[Error]" + NONE + " %s", text_to_debug (message, out len));
				print_line_debug(message, len);
				Process.exit(-1);
		}
	}

	private static void print_line_debug (string text, int len) {
		if (len != -1)
			stderr.printf (PURPLE + "(%.*s)" + NONE, len - 2, text);
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
		if (debug == false) {
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
					_debug = false;
				} else {
					_debug = true;
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
		const string type = BOLD + GREY + "[Info]" + NONE;
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void skip (string format, ...) {
		const string type = BOLD + YELLOW + "[Skip]" + NONE;
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void suprapack (string format, ...) {
		const string type = BOLD + YELLOW + "[Suprapack]" + NONE;
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void download (string format, ...) {
		const string type = BOLD + YELLOW + "[Download]" + NONE;
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}

	[Diagnostics]
	public void conflict (string format, ...) {
		const string type = BOLD + RED + "[Conflict]" + NONE;
		va_list args = va_list();
		logv(type, LogLevelFlags.LEVEL_INFO, format, args); 
	}
}
