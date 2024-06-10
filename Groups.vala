/* Exemple of Group in repo.list */
/*
```
[Groups]
compiler: (ccls clangd) foo bar
```

# if user download compiler suprapack tell if the user want ccls or clangd and install foo and bar
*/

public class Groups {
	public Groups () {
		group = {};
	}

	public void add_line(string line) throws Error {
		group += new Group(line);
	}

	public unowned List<List<string>>? get(string name) {
		foreach (unowned var g in group) {
			if (g.name == name)
				return g.list;
		}
		return null;
	}

	private Group[] group;
}

private class Group {
	public Group (string line) throws Error {
		list = new List <List<string>>();

		int comma_index = line.index_of_char(':');
		name = line[0 : comma_index];
		
		unowned var remain = line.offset(comma_index + 1);

		list = Utils.parse_dependency(remain);
	}

	public List<List<string>> list {get; private owned set;}
	public string name {get; private set;}
}
