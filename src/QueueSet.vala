public class QueueSet : GenericSet<string?> {
	public QueueSet () {
		base (str_hash, str_equal);
	}
}

public class PackageSet {
	private SList<Package?>  lst = new SList<Package?> ();

	public void reverse () {
		lst.reverse ();
	}

	public bool contains_name (string name) {
		foreach (unowned var pkg in this) {
			if (pkg.name == name)
				return true;
		} 
		return false;
	}

	public void add ( Package? pkg ) {
		if (pkg == null)
			return;
		foreach (unowned var p in this) {
			if (p.name == pkg.name)
				return;
		}
		lst.append (pkg);
	}

	public unowned Package? get (uint index) {
		return lst.nth_data (index);
	}

	public uint size {
		get {
			return (uint)lst.length();
		}
	}
}
