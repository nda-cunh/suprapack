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

namespace Utils {

	/**
	 * Compare two versions
	 *
	 * @param v1 the first version
	 * @param v2 the second version
	 * @return true if v1 is greater than v2
	 */
	public bool compare_versions (string v1, string v2) {
		if (v1 == v2)
			return false;
		var s1 = v1.split(".");
		var s2 = v2.split(".");

		int i = 0;
		while (i < s1.length && i < s2.length) {
			int a = int.parse(s1[i]);
			int b = int.parse(s2[i]);
			if (a > b)
				return true;
			else if (a < b)
				return false;
			++i;
		}
		while (i < s1.length) {
			if (int.parse(s1[i]) != 0) {
				return true;
			}
			++i;
		}
		return false;
	}
}
