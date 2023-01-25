REBOL [
	System: "REBOL [R3] Language Interpreter and Run-time Environment"
	Title: "Zlib source files amalgamation"
	Rights: {
		Copyright 2012 REBOL Technologies
		Copyright 2012-2023 Rebol Open Source Contributors
		REBOL is a trademark of REBOL Technologies
	}
	License: {
		Licensed under the Apache License, Version 2.0
		See: http://www.apache.org/licenses/LICENSE-2.0
	}
	Author: "Oldes"
	Version: 1.0.0
	Needs:   3.5.0
	Purpose: {
		Amalgamates Zlib source files into u-zlib.c and sys-zlib.h files.
	}
	Note: {
		This script is based on make-zlib.r script from Ren-C project:
		https://github.com/metaeducation/ren-c/blob/master/tools/make-zlib.r
	}
]

start: stats/timer
dir:   %zlib/
space-or-tab: system/catalog/bitsets/space


disable-user-includes: function[
	code   [string!]
	/inline
	 files [block!] "Files supposed to be directly inlined"
][
	files: any [files []]
	parse code [
		any [
			to #"#" s: skip opt [
				any space-or-tab "include"
				;; process only user includes
				some space-or-tab #"^"" copy name: to #"^"" thru lf e:
				;; make sure, that the include is not commented out
				if (find crlf s/-1 ) (
					
					if file: find files name: as file! name [
						print [space name]
						write/append output ajoin ["^///       " name]
						insert e append read/string dir/:name LF
						remove file
					]
					insert s "//REBOL: "
				)
			]
		]
	]
	code
]


output: open/new file-h: %build/sys-zlib.h
buffer: make string! 100000

print as-yellow "-- Making sys-zlib.h ----------------------------------"

write/append output ajoin [
{////////////////////////////////////////////////////////////////////////
// File: sys-zlib.h
// Home: https://github.com/Siskin-framework/Rebol-Zlib
// Date: } now/date {
// Note: This file is amalgamated from these sources:
//}]

foreach file [
	%zconf.h
	%zutil.h
	%zlib.h
	%deflate.h
][
	probe file
	write/append output ajoin ["^///       " file]
	append buffer disable-user-includes read/string dir/:file
]

write/append output {
//
////////////////////////////////////////////////////////////////////////
// Rebol options:
#define NO_DUMMY_DECL 1
#define Z_PREFIX 1
#define ZLIB_CONST
////////////////////////////////////////////////////////////////////////

}
write/append output buffer
close output
clear buffer


print as-yellow "-- Making u-zlib.c ------------------------------------"

output: open/new file-c: %build/u-zlib.c

write/append output ajoin [
{////////////////////////////////////////////////////////////////////////
// File: u-zlib.c
// Home: https://github.com/Siskin-framework/Rebol-Zlib
// Date: } now/date {
// Note: This file is amalgamated from these sources:
//}]

foreach file [
	%crc32.c
	%adler32.c

	%deflate.c
	%zutil.c
	%compress.c
	%uncompr.c
	%trees.c

	%inftrees.h
	%inftrees.c
	%inffast.h
	%inflate.h
	%inffast.c
	%inflate.c
][
	probe file
	write/append output ajoin ["^///       " file]
	append buffer disable-user-includes/inline read/string dir/:file [
		;; these files cannot be collected directly, because are used inside ifdef blocks
		%crc32.h
		%inffixed.h
		%trees.h
	]
]

write/append output {
//
////////////////////////////////////////////////////////////////////////

#include "sys-zlib.h"

}

write/append output buffer
close output

print [
	as-yellow "Amalgamated in time:"
	as-green  stats/timer - start
]
print [space as-green "sys-zlib.h" as-yellow (size? file-h) "bytes"]
print [space as-green "  u-zlib.c" as-yellow (size? file-c) "bytes"]
