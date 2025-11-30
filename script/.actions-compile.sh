#!/bin/bash
set -ex

# Setup shortcuts.
ROOT=`pwd`

# Clone nginx read-only git repository.
if [ ! -d "nginx" ]; then
  git clone https://github.com/nginx/nginx.git
fi

# Build nginx + filter module.
cd $ROOT/nginx
# Pro memoria: --with-debug
./auto/configure \
    --prefix=$ROOT/script/test \
    --with-cc-opt=" -O2 -fstack-protector-strong -fstack-clash-protection -fPIE -D_FORTIFY_SOURCE=3 -Wformat -Wformat-security -Werror=format-security -Wno-sign-compare -fno-plt" \
    --with-ld-opt=" -fuse-ld=lld -pie -m64 -Wl,-O1 -Wl,--gc-sections -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,-z,nodlopen -Wl,-z,pack-relative-relocs -Wl,--sort-common -Wl,-z,defs -Wl" \
    --with-compat \
    --with-file-aio \
    --with-pcre-jit \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-stream_realip_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_sub_module \
    --with-http_stub_status_module \
    --with-libatomic \
    --with-http_perl_module \
    --with-http_degradation_module \
    --with-stream_geoip_module \
    --with-http_geoip_module  \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_slice_module \
    --with-select_module \
    --with-poll_module \
    --with-http_xslt_module \
    --with-http_image_filter_module \
    --with-cpp_test_module  \
    --with-mail \
    --with-mail_ssl_module \
    --add-module=$ROOT
make -j 16



# Build nginx + filter module.
#cd $ROOT/nginx
# Pro memoria: --with-debug
#./auto/configure \
#    --prefix=$ROOT/script/test \
#    --with-http_v2_module \
#    --add-module=$ROOT
#make -j 16


# Build brotli CLI.
cd $ROOT/deps/brotli
mkdir out
cd out
cmake ..
make -j 16 brotli

# Restore status-quo.
cd $ROOT
