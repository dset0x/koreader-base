PROJECT(freetype2)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --disable-static --enable-shared --with-zlib=no --with-bzip2=no --with-png=no --with-harfbuzz=no --host=\"${CHOST}\"")
set(CFG_CMD_STR "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    git://git.sv.gnu.org/freetype/freetype2.git
    49984c9bc0ee0a91474227fd911b4a79d73dc682
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR}
    BUILD_COMMAND $(MAKE) -j${PROCESSOR_COUNT}
    INSTALL_COMMAND $(MAKE) -j${PROCESSOR_COUNT} --silent install
)
