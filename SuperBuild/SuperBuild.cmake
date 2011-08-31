find_package(Git REQUIRED)
#-----------------------------------------------------------------------------

set(BUILDNAME "NoBuldNameGiven")
set(SITE      "NoSiteGiven")

enable_language(C)
enable_language(CXX)

#-----------------------------------------------------------------------------
# Platform check
#-----------------------------------------------------------------------------
set(PLATFORM_CHECK true)
if(PLATFORM_CHECK)
  # See CMake/Modules/Platform/Darwin.cmake)
  #   6.x == Mac OSX 10.2 (Jaguar)
  #   7.x == Mac OSX 10.3 (Panther)
  #   8.x == Mac OSX 10.4 (Tiger)
  #   9.x == Mac OSX 10.5 (Leopard)
  #  10.x == Mac OSX 10.6 (Snow Leopard)
  if (DARWIN_MAJOR_VERSION LESS "9")
    message(FATAL_ERROR "Only Mac OSX >= 10.5 are supported !")
  endif()
endif()

#-----------------------------------------------------------------------------
# Update CMake module path
#------------------------------------------------------------------------------

set(CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/CMake
  ${CMAKE_SOURCE_DIR}/SuperBuild
  ${CMAKE_BINARY_DIR}/CMake
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../CMake #  CMake directory
  ${CMAKE_CURRENT_SOURCE_DIR}/../Wrapping
  ${CMAKE_MODULE_PATH}
  )

include(PreventInSourceBuilds)
include(PreventInBuildInstalls)
include(VariableList)


#-----------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------
#
# SimpleITK Addition: install to the common library
# directory, so that all libs/include etc ends up
# in one common tree
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "Where all the prerequisite libraries go" FORCE)

# Compute -G arg for configuring external projects with the same CMake generator:
if(CMAKE_EXTRA_GENERATOR)
  set(gen "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
else()
  set(gen "${CMAKE_GENERATOR}")
endif()


#-----------------------------------------------------------------------------
# SimpleITK options
#------------------------------------------------------------------------------
option( ${CMAKE_PROJECT_NAME}_BUILD_TESTING "Turn on Testing for SimpleITK" ON )


#-----------------------------------------------------------------------------
# Default to build shared libraries off
#------------------------------------------------------------------------------
set(BUILD_SHARED_LIBS OFF)

#-----------------------------------------------------------------------------
# Setup build type
#------------------------------------------------------------------------------

# By default, let's build as Debug
if(NOT DEFINED CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()

# let a dashboard override the default.
if(CTEST_BUILD_CONFIGURATION)
  set(CMAKE_BUILD_TYPE "${CTEST_BUILD_CONFIGURATION}")
endif()

#-------------------------------------------------------------------------
# augment compiler flags
#-------------------------------------------------------------------------
include(CompilerFlagSettings)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_DEBUG_DESIRED_FLAGS}" )
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_DEBUG_DESIRED_FLAGS}" )
else() # Release, or anything else
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_RELEASE_DESIRED_FLAGS}" )
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_RELEASE_DESIRED_FLAGS}" )
endif()

#------------------------------------------------------------------------------
# BuildName used for dashboard reporting
#------------------------------------------------------------------------------
if(NOT BUILDNAME)
  set(BUILDNAME "Unknown-build" CACHE STRING "Name of build to report to dashboard")
endif()


#------------------------------------------------------------------------------
# WIN32 /bigobj is required for windows builds because of the size of
#------------------------------------------------------------------------------
if (WIN32)
  # some object files (CastImage for instance)
  set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj" )
  set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /bigobj" )
  # Avoid some warnings
  add_definitions ( -D_SCL_SECURE_NO_WARNINGS )
endif()

#------------------------------------------------------------------------------
# Setup build locations.
#------------------------------------------------------------------------------
if(NOT SETIFEMPTY)
  macro(SETIFEMPTY) # A macro to set empty variables to meaninful defaults
    set(KEY ${ARGV0})
    set(VALUE ${ARGV1})
    if(NOT ${KEY})
      set(${ARGV})
    endif(NOT ${KEY})
  endmacro(SETIFEMPTY KEY VALUE)
endif(NOT SETIFEMPTY)
SETIFEMPTY(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
SETIFEMPTY(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
SETIFEMPTY(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
SETIFEMPTY(CMAKE_BUNDLE_OUTPUT_DIRECTORY  ${CMAKE_CURRENT_BINARY_DIR}/bin)


#------------------------------------------------------------------------------
# Common Build Options to pass to all subsequent tools
#------------------------------------------------------------------------------
list( APPEND ep_common_list 
  MAKECOMMAND
  CMAKE_BUILD_TYPE
  CMAKE_C_COMPILER
  CMAKE_C_COMPILER_ARG1
  CMAKE_CXX_COMPILER
  CMAKE_CXX_COMPILER_ARG1
  CMAKE_CXX_FLAGS_RELEASE
  CMAKE_CXX_FLAGS_DEBUG
  CMAKE_CXX_FLAGS
  CMAKE_C_FLAGS_RELEASE
  CMAKE_C_FLAGS_DEBUG
  CMAKE_C_FLAGS
  CMAKE_EXE_LINKER_FLAGS
  CMAKE_EXE_LINKER_FLAGS_DEBUG
  CMAKE_GENERATOR
  CMAKE_EXTRA_GENERATOR
  CMAKE_INSTALL_PREFIX
  CMAKE_LIBRARY_OUTPUT_DIRECTORY
  CMAKE_ARCHIVE_OUTPUT_DIRECTORY
  CMAKE_RUNTIME_OUTPUT_DIRECTORY
  CMAKE_BUNDLE_OUTPUT_DIRECTORY
  MEMORYCHECK_COMMAND_OPTIONS
  MEMORYCHECK_COMMAND
  CMAKE_SHARED_LINKER_FLAGS
  CMAKE_EXE_LINKER_FLAGS
  CMAKE_MODULE_LINKER_FLAGS
  SITE
  BUILDNAME )

VariableListToCache( ep_common_list ep_common_cache )
VariableListToArgs( ep_common_list ep_common_args )

list( APPEND ep_common_args
  -DCMAKE_SKIP_RPATH:BOOL=ON
  -DBUILD_EXAMPLES:BOOL=OFF
)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
include(ExternalProject)
#------------------------------------------------------------------------------
# Swig
#------------------------------------------------------------------------------
option ( USE_SYSTEM_SWIG "Use a pre-compiled version of SWIG 2.0 previously configured for your system" OFF )
mark_as_advanced(USE_SYSTEM_SWIG)
if(USE_SYSTEM_SWIG)
  find_package ( SWIG 2 REQUIRED )
  include ( UseSWIGLocal )
else()
  include(External_Swig)
  list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES Swig)
endif()

#------------------------------------------------------------------------------
# ITK
#------------------------------------------------------------------------------

set(ITK_WRAPPING OFF CACHE BOOL "Turn OFF wrapping ITK with WrapITK")
if(ITK_WRAPNG)
  list(APPEND ITK_DEPENDENCIES Swig)
endif()
if(ITK_USE_FFTW)
  list(APPEND ITK_DEPENDENCIES fftw)
endif()
include(External_ITKv4)
list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES ITK)


#------------------------------------------------------------------------------
# List of external projects
#------------------------------------------------------------------------------
set(external_project_list  ITK swig)

#-----------------------------------------------------------------------------
# Dump external project dependencies
#-----------------------------------------------------------------------------
set(ep_dependency_graph "# External project dependencies")
foreach(ep ${external_project_list})
  set(ep_dependency_graph "${ep_dependency_graph}\n${ep}:${${ep}_DEPENDENCIES}")
endforeach()
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/ExternalProjectDependencies.txt "${ep_dependency_graph}\n")

#-----------------------------------------------------------------------------
# Now delegate back to the main SimpleITK with ${CMAKE_PROJECT_NAME}_SuperBuild=OFF
# to actually build Simple ITK
#-----------------------------------------------------------------------------
message(STATUS "${CMAKE_PROJECT_NAME}_DEPENDENCIES ${${CMAKE_PROJECT_NAME}_DEPENDENCIES}")

#
# Use CMake file which present options for wrapped languages, and finds languages as needed
#
include(SITKLanguageOptions)


VariableListToCache( SITK_LANGUAGES_VARS  ep_languages_cache )
VariableListToArgs( SITK_LANGUAGES_VARS  ep_languages_args )

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/SimpleITK-build/CMakeCacheInit.txt" "${ep_common_cache}\n${ep_languages_cache}" )

set(proj SimpleITK)
ExternalProject_Add(${proj}
  DOWNLOAD_COMMAND ""
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
  BINARY_DIR SimpleITK-build
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    -C "${CMAKE_CURRENT_BINARY_DIR}/SimpleITK-build/CMakeCacheInit.txt"
    ${ep_common_args}
    ${ep_languages_args}
    # ITK
    -DITK_DIR:PATH=${ITK_DIR}
    # Swig
    -DSWIG_DIR:PATH=${SWIG_DIR}
    -DSWIG_EXECUTABLE:PATH=${SWIG_EXECUTABLE}
    -DBUILD_TESTING:BOOL=${CMAKE_PROJECT_NAME}_BUILD_TESTING
    -DWRAP_LUA:BOOL=${WRAP_LUA}
    -DWRAP_PYTHON:BOOL=${WRAP_PYTHON}
    -DWRAP_RUBY:BOOL=${WRAP_RUBY}
    -DWRAP_JAVA:BOOL=${WRAP_JAVA}
    -DWRAP_TCL:BOOL=${WRAP_TCL}
    -DWRAP_CSHARP:BOOL=${WRAP_CSHARP}
    -DWRAP_R:BOOL=${WRAP_R}
  INSTALL_COMMAND ""
  DEPENDS ${${CMAKE_PROJECT_NAME}_DEPENDENCIES}
)
