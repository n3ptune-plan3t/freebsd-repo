PORTNAME=	moksha
DISTVERSION=	0.4.2
CATEGORIES=	x11-wm enlightenment
DIST_SUBDIR=	moksha

MAINTAINER=	you@example.org
COMMENT=	Fork of the Enlightenment E17 window manager and desktop shell
WWW=		https://github.com/JeffHoogland/moksha

LICENSE=	BSD2CLAUSE
LICENSE_FILE=	${WRKSRC}/COPYING

LIB_DEPENDS=	libeina.so:devel/efl \
		libxcb-keysyms.so:x11/xcb-util-keysyms \
		libdbus-1.so:devel/dbus \
		libinput.so:x11/libinput \
		libudev.so:devel/libudev-devd \
		libudisks2.so:sysutils/libudisks
RUN_DEPENDS=	moksha-menu>0:x11-wm/moksha-menu \
		bsdisks>0:sysutils/bsdisks \
		update-desktop-database:devel/desktop-file-utils \
		${LOCALBASE}/share/icons/hicolor/index.theme:misc/hicolor-icon-theme \
		${LOCALBASE}/share/X11/xkb/rules/base:x11/xkeyboard-config

CONFLICTS_INSTALL=	enlightenment

USES=		autoreconf gettext gmake libtool localbase pkgconfig xorg
USE_XORG=	x11 xcb xext
USE_GITHUB=	yes
GH_ACCOUNT=	JeffHoogland
GH_TAGNAME=	a556c48cf09f274db14e720c2648446e49d06206

# patches are git-style (-p1) and touch configure.ac / Makefile.am
PATCH_STRIP=	-p1
GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--sysconfdir=${PREFIX}/etc --disable-bodhi
# no systemd on FreeBSD; PAM comes from base (security/pam_appl.h)
CFLAGS+=	-std=gnu17
INSTALL_TARGET=	install-strip

.include <bsd.port.mk>
