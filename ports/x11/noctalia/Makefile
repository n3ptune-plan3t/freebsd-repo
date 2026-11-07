PORTNAME=	noctalia
DISTVERSIONPREFIX=	v
DISTVERSION=	5.4.1
CATEGORIES=	x11 wayland

MAINTAINER=	you@example.org
COMMENT=	Native C++/OpenGL ES desktop shell for Wayland compositors
WWW=		https://noctalia.dev/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	wayland-protocols>0:graphics/wayland-protocols \
		nlohmann-json>0:devel/nlohmann-json \
		stb>0:devel/stb \
		tomlplusplus>0:devel/tomlplusplus
LIB_DEPENDS=	libwayland-client.so:graphics/wayland \
		libxkbcommon.so:x11/libxkbcommon \
		libfreetype.so:print/freetype2 \
		libfontconfig.so:x11-fonts/fontconfig \
		libcairo.so:graphics/cairo \
		libpango-1.0.so:x11-toolkits/pango \
		libharfbuzz.so:print/harfbuzz \
		libsecret-1.so:security/libsecret \
		libsodium.so:security/libsodium \
		libsdbus-c++.so:devel/sdbus-cpp \
		libpipewire-0.3.so:multimedia/pipewire \
		libwireplumber-0.5.so:multimedia/wireplumber \
		libpolkit-agent-1.so:sysutils/polkit \
		libcurl.so:ftp/curl \
		libwebp.so:graphics/webp \
		libjxl.so:graphics/libjxl \
		libsndfile.so:audio/libsndfile \
		librsvg-2.so:graphics/librsvg2 \
		libqalculate.so:math/libqalculate \
		libxml2.so:textproc/libxml2 \
		libical.so:devel/libical \
		libmd4c.so:textproc/md4c \
		libepoll-shim.so:devel/libepoll-shim \
		libinotify.so:devel/libinotify

RUN_DEPENDS=	git:devel/git \
		${LOCALBASE}/share/fonts/dejavu/DejaVuSans.ttf:x11-fonts/dejavu

USES=		compiler:c++23-lang gl meson pkgconfig
USE_GL=		egl glesv2
USE_GITHUB=	yes
GH_ACCOUNT=	noctalia-dev

# FreeBSD libc already is jemalloc; upstream only auto-enables it on glibc
MESON_ARGS=	-Djemalloc=disabled -Dtests=disabled -Dnative_optimizations=false -Db_lto=false

CPPFLAGS+=	-I${LOCALBASE}/include/libepoll-shim
LDFLAGS+=	-L${LOCALBASE}/lib -lepoll-shim -linotify

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/share/bash-completion/completions \
		${STAGEDIR}${PREFIX}/share/fish/vendor_completions.d \
		${STAGEDIR}${PREFIX}/share/zsh/site-functions
	${STAGEDIR}${PREFIX}/bin/noctalia completions bash > ${STAGEDIR}${PREFIX}/share/bash-completion/completions/noctalia
	${STAGEDIR}${PREFIX}/bin/noctalia completions fish > ${STAGEDIR}${PREFIX}/share/fish/vendor_completions.d/noctalia.fish
	${STAGEDIR}${PREFIX}/bin/noctalia completions zsh > ${STAGEDIR}${PREFIX}/share/zsh/site-functions/_noctalia

.include <bsd.port.mk>
