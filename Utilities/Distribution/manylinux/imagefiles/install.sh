NPROC=$(grep -c processor /proc/cpuinfo)

export MAKEFLAGS="-j ${NPROC}"

OPENSSL_ROOT=openssl-1.0.2q
# Hash from https://www.openssl.org/source/openssl-1.0.2q.tar.gz.sha256
OPENSSL_HASH=5744cfcbcec2b1b48629f7354203bc1e5e9b5466998bbccc5b5fcde3b18eb684
CMAKE_ROOT=cmake-3.11.4


function check_var {
    if [ -z "$1" ]; then
        echo "required variable not defined"
        exit 1
    fi
}

function do_openssl_build {

    ./config no-ssl2 no-shared -fPIC --prefix=/usr/local/ssl &&
    MAKEFLAGS="" make &&
    MAKEFLAGS="" make install
}

function check_sha256sum {
    local fname=$1
    check_var ${fname}
    local sha256=$2
    check_var ${sha256}

    echo "${sha256}  ${fname}" > ${fname}.sha256
    sha256sum -c ${fname}.sha256
    rm -f ${fname}.sha256
}


function build_openssl {
    local openssl_fname=$1
    check_var ${openssl_fname}
    local openssl_sha256=$2
    check_var ${openssl_sha256} &&
    check_sha256sum ${openssl_fname}.tar.gz ${openssl_sha256} &&
    tar -xzf ${openssl_fname}.tar.gz &&
    (cd ${openssl_fname} && do_openssl_build) &&
    rm -rf ${openssl_fname} ${openssl_fname}.tar.gz
}

build_openssl $OPENSSL_ROOT $OPENSSL_HASH || exit 1

tar xvzf ${CMAKE_ROOT}.tar.gz &&
mkdir /tmp/cmake-build &&
(cd /tmp/cmake-build &&
    ../${CMAKE_ROOT}/bootstrap --parallel=${NPROC} -- \
        -DCMAKE_BUILD_TYPE:STRING=Release \
        -DCMAKE_USE_OPENSSL:BOOL=ON \
        -DOPENSSL_ROOT_DIR:PATH=/usr/local/ssl \
        -DCMAKE_USE_SYSTEM_CURL:BOOL=OFF  &&
    make  &&
    make install) ||
exit 1

rm -rf /usr/local/ssl
