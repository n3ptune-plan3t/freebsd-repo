PORTNAME=	moksha-menu
DISTVERSION=	1.0
CATEGORIES=	x11-wm enlightenment
DIST_SUBDIR=	moksha

MAINTAINER=	you@example.org
COMMENT=	Freedesktop.org menu specification files for Moksha
WWW=		https://github.com/BodhiDev/Moksha-menu

LICENSE=	LGPL21
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	autoconf>0:devel/autoconf \
		automake>0:devel/automake

USES=		gettext-tools gmake gnome pkgconfig
USE_GNOME=	glib20 intltool
USE_GITHUB=	yes
GH_ACCOUNT=	BodhiDev
GH_PROJECT=	Moksha-menu
GH_TAGNAME=	9b6f18badb8c4c88225a429c405e5194d8f5b56c

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--sysconfdir=${PREFIX}/etc
NO_ARCH=	yes

# Upstream ships no configure script; autogen.sh only regenerates it
pre-configure:
	cd ${WRKSRC} && ./autogen.sh

.include <bsd.port.mk>
