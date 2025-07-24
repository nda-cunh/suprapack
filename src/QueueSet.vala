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
