mark_as_advanced(REDISPLUSPLUS_INCLUDE_DIR REDISPLUSPLUS_LIBRARY)

if(DEPS STREQUAL "DOWNLOAD" OR DEP_REDISPLUSPLUS STREQUAL "DOWNLOAD")
  message(STATUS "Downloading redis-plus-plus as requested")
  set(_download_redisplusplus TRUE)
else()
  include(FindPkgConfig)
  pkg_check_modules(REDISPLUSPLUS redis++>=${RedisPlusPlus_FIND_VERSION})
  if(REDISPLUSPLUS_INCLUDE_DIR AND REDISPLUSPLUS_LIBRARY)
    set_target_properties(
        dep_redisplusplus
        PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${REDISPLUSPLUS_INCLUDE_DIR}"
        IMPORTED_LOCATION "${REDISPLUSPLUS_LIBRARY}"
      )
  endif()
  if(NOT _redisplusplus_origin)
    if(DEPS STREQUAL "AUTO")
      message(STATUS "Downloading RedisPlusPlus from the internet since RedisPlusPlus>=${RedisPlusPlus_FIND_VERSION} was not found locally and DEPS=AUTO")
      set(_download_redisplusplus TRUE)
    else()
      message(FATAL_ERROR "Could not find RedisPlusPlus>=${RedisPlusPlus_FIND_VERSION}")
    endif()
  endif()
endif()

if(_download_hiredis)
  set(_hiredis_origin DOWNLOADED)
  set(_hiredis_version_string 1.2.0)

  include(FetchContent)
  FetchContent_Declare(
    Hiredis
    URL "https://github.com/redis/hiredis/archive/refs/tags/v${_hiredis_version_string}.tar.gz"
    URL_HASH SHA256=82ad632d31ee05da13b537c124f819eb88e18851d9cb0c30ae0552084811588c
  )

  # Intentionally not using hiredis's build system since it doesn't put headers
  # in a hiredis subdirectory.
  FetchContent_Populate(Hiredis)
  set(
    _hiredis_sources
    "${hiredis_SOURCE_DIR}/alloc.c"
    "${hiredis_SOURCE_DIR}/async.c"
    "${hiredis_SOURCE_DIR}/dict.c"
    "${hiredis_SOURCE_DIR}/hiredis.c"
    "${hiredis_SOURCE_DIR}/net.c"
    "${hiredis_SOURCE_DIR}/read.c"
    "${hiredis_SOURCE_DIR}/sds.c"
    "${hiredis_SOURCE_DIR}/sockcompat.c"
  )
  add_library(dep_hiredis STATIC EXCLUDE_FROM_ALL "${_hiredis_sources}")
  if(WIN32)
    target_compile_definitions(dep_hiredis PRIVATE _CRT_SECURE_NO_WARNINGS)
  endif()
  make_directory("${hiredis_SOURCE_DIR}/include/hiredis")
  file(GLOB _hiredis_headers "${hiredis_SOURCE_DIR}/*.h")
  file(COPY ${_hiredis_headers} DESTINATION "${hiredis_SOURCE_DIR}/include/hiredis")
  target_include_directories(
    dep_hiredis SYSTEM INTERFACE "$<BUILD_INTERFACE:${hiredis_SOURCE_DIR}/include>"
  )
endif()

if(WIN32)
  target_link_libraries(dep_hiredis INTERFACE ws2_32)
endif()

register_dependency(Hiredis "${_hiredis_origin}" "${_hiredis_version_string}")
