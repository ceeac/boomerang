#
# This file is part of the Boomerang Decompiler.
#
# See the file "LICENSE.TERMS" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL
# WARRANTIES.
#
#
# - Find flexc++ executable.
#
# The module defines the following variables:
#  FlexCPP_FOUND        - true if flexc++ was found
#  FlexCPP_EXECUTABLE   - the path to the flexc++ executable
#  FlexCPP_VERSION      - the version of flexc++
#
# The minimum required version of flexc++ can be specified using the
# standard syntax, e.g. find_package(FlexCPP 2.5.13)
#

find_program(FlexCPP_EXECUTABLE NAMES flexc++ flexcpp DOC "Path to the flexc++ executable")
mark_as_advanced(FlexCPP_EXECUTABLE)

if (FlexCPP_EXECUTABLE)
    execute_process(COMMAND ${FlexCPP_EXECUTABLE} --version
        OUTPUT_VARIABLE FlexCPP_version_output
        ERROR_VARIABLE FlexCPP_version_error
        RESULT_VARIABLE FlexCPP_version_result
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if (NOT ${FlexCPP_version_result} EQUAL 0)
        if (FlexCPP_FIND_REQUIRED)
            message(SEND_ERROR "Command \"${FlexCPP_EXECUTABLE} --version\" failed with output:\n${FLEXCPP_version_output}\n${FLEXCPP_version_error}")
		else ()
			message("Command \"${FlexCPP_EXECUTABLE} --version\" failed with output:\n${FLEXCPP_version_output}\n${FLEXCPP_version_error}\nFlexCPP_VERSION will not be available")
		endif ()
	else () # flexc++ version found
        string(REGEX REPLACE "^flexc\\+\\+ V([0-9]+[^ ]*)$" "\\1"
            FlexCPP_VERSION_NEW "${FlexCPP_version_output}")
        set(FlexCPP_VERSION "${FlexCPP_VERSION_NEW}")
    endif ()
endif (FlexCPP_EXECUTABLE)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(FlexCPP REQUIRED_VARS FlexCPP_EXECUTABLE
    VERSION_VAR FlexCPP_VERSION)

