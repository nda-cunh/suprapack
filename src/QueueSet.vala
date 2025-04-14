public class QueueSet : GenericSet<string?> {
	public QueueSet () {
		base (str_hash, str_equal);
	}
}

public class PackageSet : GenericSet<Package?> {
	public PackageSet () {
		base (hash, equal);
	}

	private static uint hash (Package? pkg) {
		return pkg.hash ();
	}

	private static bool equal (Package? pkg1, Package? pkg2) {
		return pkg1.equal (pkg2);
	}
	
	public bool contains_name (string name) {
		foreach (unowned var pkg in this) {
			if (pkg.name == name)
				return true;
		} 
		return false;
	}

	public unowned Package? get_first () {
		foreach (unowned var pkg in this) {
			return pkg;
		}
		return null;
	}

}
