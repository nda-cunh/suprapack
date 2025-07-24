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

/**
 * This is a simple binding for the uname system call.
 * It is based on the C header file sys/utsname.h.
 */
[CCode (cname = "struct utsname", cheader_filename = "sys/utsname.h")]
public struct utsname {

	[CCode (cname="uname")]
	public static int uname(out utsname name);

	unowned string sysname;    /* Operating system name (e.g., "Linux") */
	unowned string nodename;   /* Name within "some implementation-defined network" */
	unowned string release;    /* Operating system release */
	unowned string version;    /* Operating system version */
	unowned string machine;    /* Hardware identifier */
	unowned string domainname; /* NIS or YP domain name */
}

namespace SupraUnix {
	[IntegerType ( rank = 9 )]
	[CCode ( cname="uid_t", has_type_id = false )]
	[SimpleType]
	public struct uid : int {
	}

	[CCode (cname = "getuid", cheader_filename = "unistd.h")]
	public uid getuid ();
	[CCode (cname = "geteuid", cheader_filename = "unistd.h")]
	public uid geteuid ();

	public bool is_root () {
		uid uid = getuid();
		uid euid = geteuid();

		if (uid == 0 && euid == 0)
			return true;
		else
			return false;
	}
}
