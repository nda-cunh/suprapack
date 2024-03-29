public class Makepkg : Object {
	public Makepkg (string pkgbuild) throws Error{
		MatchInfo match_info;
		string contents;

		FileUtils.get_contents (pkgbuild, out contents);
		var regex_attribut = new Regex("""^([^\s]+)[=](([(].*?[)])|(.*?$))""", RegexCompileFlags.MULTILINE | RegexCompileFlags.DOTALL);
		var regex_function = new Regex("""^([^\s]+)[(][)]\s*[{](.*?)[}]""", RegexCompileFlags.MULTILINE | RegexCompileFlags.DOTALL);

		if (regex_attribut.match (contents, 0, out match_info)) {
			do {
				string name = match_info.fetch(1);
				string value = match_info.fetch(2);	

				set_data<string> (name, value);
			} while (match_info.next ());
		}
	}

}
