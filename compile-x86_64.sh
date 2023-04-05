#!/bin/sh

set -ex

# Compiler Configuration
CROSS_TARGET=x86_64-elf
GCC_VERSION="10.4.0" # GCC version
BIN_VERSION="2.38"  # Binutils version
MPF_VERSION="4.1.0" # MPFR version
GMP_VERSION="6.2.1" # GMP version
MPC_VERSION="1.2.1" # MPC version

# Build Configuration
MAKE_JOBS=8
INSTALL_PATH="$PWD/compiler/x64"

GCC_PKG_NAME="gcc-$GCC_VERSION"
BIN_PKG_NAME="binutils-$BIN_VERSION"
MPF_PKG_NAME="mpfr-$MPF_VERSION"
GMP_PKG_NAME="gmp-$GMP_VERSION"
MPC_PKG_NAME="mpc-$MPC_VERSION"
LHD_PKG_NAME="linux-$LHD_VERSION"
GLC_PKG_NAME="glibc-$GLC_VERSION"
KMD_PKG_NAME="kmod-$KMD_VERSION"
SSL_PKG_NAME="openssl-$SSL_VERSION"

GCC_SRC="https://ftp.gnu.org/gnu/gcc/$GCC_PKG_NAME/$GCC_PKG_NAME.tar.gz" # GCC download link
BIN_SRC="https://ftp.gnu.org/gnu/binutils/$BIN_PKG_NAME.tar.gz"          # Binutils download link
MPF_SRC="https://ftp.gnu.org/gnu/mpfr/$MPF_PKG_NAME.tar.xz"          # MPFR download link
GMP_SRC="https://ftp.gnu.org/gnu/gmp/$GMP_PKG_NAME.tar.xz"          # GMP download link
MPC_SRC="https://ftp.gnu.org/gnu/mpc/$MPC_PKG_NAME.tar.gz"          # MPC download link
mkdir -p $INSTALL_PATH

# download sources
echo "--> [STATUS] downloading sources..."
if [ ! -f $GCC_PKG_NAME.tar.gz ]; then
	wget $GCC_SRC
fi
if [ ! -f $BIN_PKG_NAME.tar.gz ]; then
	wget $BIN_SRC
fi
if [ ! -f $MPF_PKG_NAME.tar.xz ]; then
	wget $MPF_SRC
fi
if [ ! -f $GMP_PKG_NAME.tar.xz ]; then
	wget $GMP_SRC
fi
if [ ! -f $MPC_PKG_NAME.tar.gz ]; then
	wget $MPC_SRC
fi

# create directory
mkdir -pv $CROSS_TARGET
cd $CROSS_TARGET

# unpack source archives
echo "--> [STATUS] unpacking archives..."
if [ ! -d $GCC_PKG_NAME ]; then
	tar -xpvf ../$GCC_PKG_NAME.tar.gz
fi
if [ ! -d $BIN_PKG_NAME ]; then
	tar -xpvf ../$BIN_PKG_NAME.tar.gz
fi


# build binutils
cd $BIN_PKG_NAME
mkdir -pv build
cd build
../configure                      \
	--target=$CROSS_TARGET    \
	--prefix="$INSTALL_PATH"  \
	--with-sysroot            \
	--disable-nls             \
	--disable-werror
make -j$MAKE_JOBS
make install

cd ../..

# build gcc
cd $GCC_PKG_NAME
tar -xvpf ../../$MPF_PKG_NAME.tar.xz
tar -xvpf ../../$GMP_PKG_NAME.tar.xz
tar -xpvf ../../$MPC_PKG_NAME.tar.gz
mv -v $MPF_PKG_NAME mpfr
mv -v $GMP_PKG_NAME gmp
mv -v $MPC_PKG_NAME mpc
mkdir -pv build
cd build
../configure                      \
	--target=$CROSS_TARGET    \
	--prefix="$INSTALL_PATH"  \
	--with-glibc-version=2.36 \
	--with-newlib             \
	--without-headers         \
	--enable-initfini-array   \
	--disable-nls             \
	--disable-shared          \
	--disable-multilib        \
	--disable-decimal-float   \
	--disable-threads         \
	--disable-libatomic       \
	--disable-libgomp         \
	--disable-libquadmath     \
	--disable-libssp          \
	--disable-libvtv          \
	--disable-libstdcxx       \
	--enable-languages=c,c++
make all-gcc -j$MAKE_JOBS
make all-target-libgcc -j$MAKE_JOBS
make install-gcc
make install-target-libgcc

cd ../..

echo "--> [STATUS] DONE!"
