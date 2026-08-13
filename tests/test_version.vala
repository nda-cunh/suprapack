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
 * Copyright (C) 2026 SupraCorp - Nathan Da Cunha (nda-cunh)
 */

void assert_greater (string v1, string v2) {
	if (Utils.compare_versions (v1, v2) == false)
		Test.fail_printf ("expected %s > %s", v1, v2);
}

void assert_not_greater (string v1, string v2) {
	if (Utils.compare_versions (v1, v2) == true)
		Test.fail_printf ("expected %s <= %s", v1, v2);
}

void test_equal () {
	assert_not_greater ("1.0.0", "1.0.0");
	assert_not_greater ("2.35", "2.35");
	assert_not_greater ("", "");
}

void test_same_length () {
	assert_greater ("2.0", "1.9");
	assert_not_greater ("1.9", "2.0");
	assert_greater ("2.35", "2.34");
	assert_not_greater ("2.34", "2.35");
	assert_greater ("1.2.3", "1.2.2");
	assert_not_greater ("1.2.2", "1.2.3");
}

void test_numeric_not_lexicographic () {
	assert_greater ("1.10", "1.9");
	assert_not_greater ("1.9", "1.10");
	assert_greater ("1.100.0", "1.99.9");
}

void test_trailing_components () {
	assert_greater ("1.0.1", "1.0");
	assert_not_greater ("1.0.0", "1.0");
	assert_not_greater ("1.0.0.0", "1.0");
	assert_not_greater ("1.0", "1.0.0");
	assert_not_greater ("1.0", "1.0.1");
	assert_greater ("1.2.3.4", "1.2.3");
}

void test_leading_zeros () {
	assert_not_greater ("1.01", "1.1");
	assert_not_greater ("1.1", "1.01");
	assert_greater ("1.02", "1.1");
	assert_not_greater ("1.0.00", "1.0");
}

void test_update_scenario () {
	assert_greater ("2.35", "2.34");
	assert_not_greater ("2.35", "2.36");
	assert_not_greater ("2.35", "2.35");
	assert_greater ("10.0", "9.99");
}

int main (string []args) {
	Test.init (ref args);
	Test.add_func ("/version/equal", test_equal);
	Test.add_func ("/version/same_length", test_same_length);
	Test.add_func ("/version/numeric", test_numeric_not_lexicographic);
	Test.add_func ("/version/trailing", test_trailing_components);
	Test.add_func ("/version/leading_zeros", test_leading_zeros);
	Test.add_func ("/version/update", test_update_scenario);
	return Test.run ();
}
