# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils alternatives flag-o-matic toolchain-funcs multilib multiprocessing prefix

PATCH_VER=1

PERL_OLDVERSEN=""
MODULE_AUTHOR=SHAY

SHORT_PV="${PV%.*}"
MY_P="perl-${PV/_rc/-RC}"
MY_PV="${PV%_rc*}"

DESCRIPTION="Larry Wall's Practical Extraction and Report Language"

SRC_URI="
	mirror://cpan/src/5.0/${MY_P}.tar.bz2
	mirror://cpan/authors/id/${MODULE_AUTHOR:0:1}/${MODULE_AUTHOR:0:2}/${MODULE_AUTHOR}/${MY_P}.tar.bz2
	mirror://gentoo/${MY_P}-patches-${PATCH_VER}.tar.xz
	http://dev.gentoo.org/~civil/distfiles/${MY_P}-patches-${PATCH_VER}.tar.xz
"
HOMEPAGE="http://www.perl.org/"

LICENSE="|| ( Artistic GPL-1+ )"
SLOT="0/${SHORT_PV}"
KEYWORDS="~alpha ~amd64 ~amd64-fbsd ~amd64-linux ~arm ~arm64 ~hppa ~hppa-hpux ~ia64 ~ia64-hpux ~ia64-linux ~m68k ~m68k-mint ~mips ~ppc ~ppc64 ~ppc-aix ~ppc-macos ~s390 ~sh ~sparc ~sparc64-solaris ~sparc-solaris ~x64-freebsd ~x64-macos ~x64-solaris ~x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~x86-linux ~x86-macos ~x86-solaris"
IUSE="berkdb debug doc gdbm ithreads"

RDEPEND="
	berkdb? ( sys-libs/db:* )
	gdbm? ( >=sys-libs/gdbm-1.8.3 )
	app-arch/bzip2
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	!prefix? ( elibc_FreeBSD? ( sys-freebsd/freebsd-mk-defs ) )
"
PDEPEND="
	>=app-admin/perl-cleaner-2.5
	>=virtual/perl-File-Temp-0.230.400-r2
	>=virtual/perl-Data-Dumper-2.154.0
"
# bug 390719, bug 523624

S="${WORKDIR}/${MY_P}"

dual_scripts() {
	src_remove_dual      perl-core/Archive-Tar        2.40.0       ptar ptardiff ptargrep
	src_remove_dual      perl-core/Digest-SHA         5.950.0       shasum
	src_remove_dual      perl-core/CPAN               2.110.0        cpan
	src_remove_dual      perl-core/Encode             2.720.0       enc2xs piconv
	src_remove_dual      perl-core/ExtUtils-MakeMaker 7.40.100       instmodsh
	src_remove_dual      perl-core/ExtUtils-ParseXS   3.280.0       xsubpp
	src_remove_dual      perl-core/IO-Compress        2.68.0        zipdetails
	src_remove_dual      perl-core/JSON-PP            2.273.0      json_pp
	src_remove_dual      perl-core/Module-CoreList    5.201.505.200 corelist
	src_remove_dual      perl-core/Pod-Parser         1.630.0       pod2usage podchecker podselect
	src_remove_dual      perl-core/Pod-Perldoc        3.250.0       perldoc
	src_remove_dual      perl-core/Test-Harness       3.350.0       prove
	src_remove_dual      perl-core/podlators          2.5.3         pod2man pod2text
	src_remove_dual_man  perl-core/podlators          2.5.3         /usr/share/man/man1/perlpodstyle.1
}

# eblit-include [--skip] <function> [version]
eblit-include() {
	local skipable=false
	[[ $1 == "--skip" ]] && skipable=true && shift
	[[ $1 == pkg_* ]] && skipable=true

	local e v func=$1 ver=$2
	[[ -z ${func} ]] && die "Usage: eblit-include <function> [version]"
	for v in ${ver:+-}${ver} -${PVR} -${PV} "" ; do
		e="${FILESDIR}/eblits/${func}${v}.eblit"
		if [[ -e ${e} ]] ; then
			. "${e}"
			return 0
		fi
	done
	${skipable} && return 0
	die "Could not locate requested eblit '${func}' in ${FILESDIR}/eblits/"
}

# eblit-run-maybe <function>
# run the specified function if it is defined
eblit-run-maybe() {
	[[ $(type -t "$@") == "function" ]] && "$@"
}

# eblit-run <function> [version]
# aka: src_unpack() { eblit-run src_unpack ; }
eblit-run() {
	eblit-include --skip common "${*:2}"
	eblit-include "$@"
	eblit-run-maybe eblit-$1-pre
	eblit-${PN}-$1
	eblit-run-maybe eblit-$1-post
}

src_prepare()	{
	eblit-run src_prepare   v50160001
	epatch "${FILESDIR}"/${P}-cwd-prefix.patch
	eprefixify dist/PathTools/Cwd.pm
}
src_configure()	{ eblit-run src_configure v50180002 ; }
#src_compile()	{ eblit-run src_compile   v50160001 ; }
src_test()		{
	export NO_GENTOO_NETWORK_TESTS=1;
	eblit-run src_test      v50160001 ;
}
src_install()	{ eblit-run src_install   v50200001 ; }

# FILESDIR might not be available during binpkg install
# FIXME: version passing
for x in setup {pre,post}{inst,rm} ; do
	e="${FILESDIR}/eblits/pkg_${x}-v50220001.eblit"
	if [[ -e ${e} ]] ; then
		. "${e}"
		eval "pkg_${x}() { eblit-run pkg_${x} v50160001 ; }"
	fi
done
