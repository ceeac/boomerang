#
# This file is part of the Boomerang Decompiler.
#
# See the file "LICENSE.TERMS" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL
# WARRANTIES.
#
#
# - Find bisonc++ executable.
#
# The module defines the following variables:
#  BisonCPP_FOUND       - true if bisonc++ was found
#  BisonCPP_EXECUTABLE  - the path to the bisonc++ excutable
#  BisonCPP_VERSION     - the version of bisonc++
#
# The minimum required version of bisonc++ can be specified using the
# standard syntax, e.g. find_package(BisonCPP 6.00.00)
#

find_program(BisonCPP_EXECUTABLE NAMES bisonc++ bisoncpp DOC "Path to the bisonc++ executable")
mark_as_advanced(BisonCPP_EXECUTABLE)

if (BisonCPP_EXECUTABLE)
    execute_process(COMMAND ${BisonCPP_EXECUTABLE} --version
        OUTPUT_VARIABLE BisonCPP_version_output
        ERROR_VARIABLE BisonCPP_version_error
        RESULT_VARIABLE BisonCPP_version_result
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if (NOT ${BisonCPP_version_result} EQUAL 0)
        if (BisonCPP_FIND_REQUIRED)
            message(SEND_ERROR "Command \"${BisonCPP_EXECUTABLE} --version\" failed with output:\n${BisonCPP_version_output}\n${BisonCPP_version_error}")
		else ()
			message("Command \"${BisonCPP_EXECUTABLE} --version\" failed with output:\n${BisonCPP_version_output}\n${BisonCPP_version_error}\nBisonCPP_VERSION will not be available")
		endif ()
	else () # bisonc++ version found
        string(REGEX REPLACE "^bisonc\\+\\+ V([0-9]+[^ ]*)$" "\\1"
            BisonCPP_VERSION_NEW "${BisonCPP_version_output}")
        set(BisonCPP_VERSION "${BisonCPP_VERSION_NEW}")
    endif ()
endif (BisonCPP_EXECUTABLE)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(BisonCPP REQUIRED_VARS BisonCPP_EXECUTABLE
    VERSION_VAR BisonCPP_VERSION)

