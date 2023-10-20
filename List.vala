public const string REPO_LIST = "https://gitlab.com/supraproject/suprastore_repository/-/raw/master/";

class SupraList {
	public static string[] @get() {
		string list_file = "/tmp/" + Environment.get_user_name() + "_supralist";
		try {
			if (SUPRALIST == null) {
				print_info("Download list\n");
				run_cmd({"curl", "-o", list_file, REPO_LIST + "suprastore_list"});
				SUPRALIST = list_file;
			}
			if (lst == null) {
				var fs = FileStream.open(SUPRALIST, "r");
				if (fs == null)
					throw new FileError.ACCES("list introuvable ???");
				string tmp;
				while ((tmp = fs.read_line()) != null)
					lst += tmp;
			}
			return lst;
		}
		catch (Error e) {
			print_error(e.message);
		}
	}
	public static string[] get_only_name() {
		string []result = {};
		unowned string ptr;
		SupraList.get();

		foreach (var i in lst) {
			ptr = i.offset(i.index_of_char('-'));
			ptr.data[0] = '\0';
			result += i.dup();
			ptr.data[0] = '-';
		}
		return result;
	}

	static string []lst = null;
	static string? SUPRALIST = null;
}
