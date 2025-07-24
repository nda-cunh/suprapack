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


namespace BetterSearch {

	public string? search_good_package_from_query (string package, bool choose = false) {
		double max_distance = double.MAX;
		unowned string? best_result = null;
		double similarity_percentage = 0.0;
		var list = Query.get_all_installed_pkg ();
		int len1 = package.length;

		foreach (unowned var i in list) {
			int len2 = i.length;
			int distance = levenshtein(i, package, len2, len1);
			double normalized_distance = (double) distance / max(len2, len1);

			if (normalized_distance < max_distance) {
				max_distance = normalized_distance;
				best_result = i;
				similarity_percentage = (1.0 - normalized_distance) * 100;
			}
		}
		return (search_end(best_result, package, choose));
	}

	private string? search_end (string? best_result, string package, bool choose) {
		var str = (YELLOW + "[SupraPack]" + NONE + " Package " + BOLD + PURPLE + "%s" + NONE + " not found ! Did you mean " + BOLD + PURPLE + "%s ?" + NONE + " %s:").printf(package, best_result, choose ? "[Y/n]" : "[y/N]");
		if (Utils.stdin_bool_choose (str, choose))
			return best_result;
		return null;
	}

	public string? search_good_package_from_sync (string package, bool choose = false) {
		double max_distance = double.MAX;
		unowned string? best_result = null;
		double similarity_percentage = 0.0;
		var list = Sync.get_list_package();
		int len1 = package.length;

		foreach (unowned var i in list) {
			int len2 = i.name.length;
			int distance = levenshtein(i.name, package, len2, len1);
			double normalized_distance = (double) distance / max(len2, len1);

			if (normalized_distance < max_distance) {
				max_distance = normalized_distance;
				best_result = i.name;
				similarity_percentage = (1.0 - normalized_distance) * 100;
			}
		}
		return (search_end(best_result, package, choose));
	}

	//bad score is lower and good score is higher
	public int get_score_sync (string s1, string s2) {
		double max_distance = double.MAX;
		int score = 0;
		int len1 = s1.length;
		int len2 = s2.length;
		int distance = levenshtein(s1, s2, len1, len2);
		double normalized_distance = (double) distance / max(len1, len2);
		if (normalized_distance < max_distance) {
			max_distance = normalized_distance;
			score = (int) ((1.0 - normalized_distance) * 100);
		}

		return score;
	}

	public inline int min (int a, int b) {
		return a < b ? a : b;
	}

	public inline int max (int a, int b) {
		return a > b ? a : b;
	}


	private int levenshtein (string s1, string s2, int len1, int len2) {
		int [,] D = new int[len1 + 1, len2 + 1];

		for (int i = 0; i <= len1; ++i) {
			D[i,0] = i;
		}
		for (int j = 0; j <= len2; ++j) {
			D[0,j] = j;
		}

		for (int i = 1; i <= len1; ++i) {
			for (int j = 1; j <= len2; ++j) {
				int costSubstitution;
				if (s1[i - 1] == s2[j - 1]) {
					costSubstitution = 0;
				} else {
					costSubstitution = 1;
				}
				D[i,j] = min(
					D[i - 1,j] + 1,
					min(
						D[i,j - 1] + 1,
						D[i - 1,j - 1] + costSubstitution
					)
				);
			}
		}
		return D[len1,len2];
	}
}
