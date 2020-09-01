SUITE_debug_prefix_map_PROBE() {
    touch test.c
    if ! $REAL_COMPILER -c -fdebug-prefix-map=old=new test.c 2>/dev/null; then
        echo "-fdebug-prefix-map not supported by compiler"
    fi
}

SUITE_debug_prefix_map_SETUP() {
    unset CCACHE_NODIRECT

    mkdir -p dir1/src dir1/include
    cat <<EOF >dir1/src/test.c
#include <stdarg.h>
#include <test.h>
EOF
    cat <<EOF >dir1/include/test.h
int test;
EOF
    cp -r dir1 dir2
    backdate dir1/include/test.h dir2/include/test.h
}

SUITE_debug_prefix_map() {
    # -------------------------------------------------------------------------
    TEST "Mapping of debug info CWD"

    cd dir1
    CCACHE_BASEDIR=$(pwd) $CCACHE_COMPILE -I$(pwd)/include -g -fdebug-prefix-map=$(pwd)=some_name_not_likely_to_exist_in_path -c $(pwd)/src/test.c -o $(pwd)/test.o
    expect_stat 'cache hit (direct)' 0
    expect_stat 'cache hit (preprocessed)' 0
    expect_stat 'cache miss' 1
    expect_stat 'files in cache' 2
    expect_objdump_not_contains test.o "$(pwd)"
    expect_objdump_contains test.o some_name_not_likely_to_exist_in_path

    cd ../dir2
    CCACHE_BASEDIR=$(pwd) $CCACHE_COMPILE -I$(pwd)/include -g -fdebug-prefix-map=$(pwd)=some_name_not_likely_to_exist_in_path -c $(pwd)/src/test.c -o $(pwd)/test.o
    expect_stat 'cache hit (direct)' 1
    expect_stat 'cache hit (preprocessed)' 0
    expect_stat 'cache miss' 1
    expect_stat 'files in cache' 2
    expect_objdump_not_contains test.o "$(pwd)"

    # -------------------------------------------------------------------------
    TEST "Multiple -fdebug-prefix-map"

    cd dir1
    CCACHE_BASEDIR=$(pwd) $CCACHE_COMPILE -I$(pwd)/include -g -fdebug-prefix-map=$(pwd)=some_name_not_likely_to_exist_in_path -fdebug-prefix-map=foo=bar -c $(pwd)/src/test.c -o $(pwd)/test.o
    expect_stat 'cache hit (direct)' 0
    expect_stat 'cache hit (preprocessed)' 0
    expect_stat 'cache miss' 1
    expect_stat 'files in cache' 2
    expect_objdump_not_contains test.o "$(pwd)"
    expect_objdump_contains test.o some_name_not_likely_to_exist_in_path

    cd ../dir2
    CCACHE_BASEDIR=$(pwd) $CCACHE_COMPILE -I$(pwd)/include -g -fdebug-prefix-map=$(pwd)=some_name_not_likely_to_exist_in_path -fdebug-prefix-map=foo=bar -c $(pwd)/src/test.c -o $(pwd)/test.o
    expect_stat 'cache hit (direct)' 1
    expect_stat 'cache hit (preprocessed)' 0
    expect_stat 'cache miss' 1
    expect_stat 'files in cache' 2
    expect_objdump_not_contains test.o "$(pwd)"
}
