#
# Copyright 2013 Kitware, Inc.
#
# This file is part of the Shiboken Python Binding Generator project.
#
# Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
#
# Contact: PySide team <contact@pyside.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

# Dependencies use target usage requirements, which were added in 2.8.11; ergo
# we require at least that version
cmake_minimum_required(VERSION 2.8.11)

find_package(PythonLibs REQUIRED)
find_package(Shiboken REQUIRED)
find_package(PySide)

set(PYTHON_SHORT python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})

define_property(TARGET PROPERTY SBK_WRAPPER_TARGET
                BRIEF_DOCS "Name of the shiboken wrapping library associated with this target"
                FULL_DOCS "Property defined by ${CMAKE_CURRENT_LIST_FILE}")
define_property(TARGET PROPERTY SBK_TYPESYSTEM
                BRIEF_DOCS "Shiboken typesystem XML for this target's wrapper library"
                FULL_DOCS "Property defined by ${CMAKE_CURRENT_LIST_FILE}")
define_property(TARGET PROPERTY SBK_GLOBAL_HEADER
                BRIEF_DOCS "Header file containing all includes for this target"
                FULL_DOCS "Property defined by ${CMAKE_CURRENT_LIST_FILE}")
define_property(TARGET PROPERTY SBK_TYPESYSTEM_PATHS
                BRIEF_DOCS "Shiboken typesystem paths for this target's wrapper library"
                FULL_DOCS "Property defined by ${CMAKE_CURRENT_LIST_FILE}")
define_property(TARGET PROPERTY SBK_WRAP_INCLUDE_DIRS
                BRIEF_DOCS "Additional include directories for this target's wrapper library"
                FULL_DOCS "Property defined by ${CMAKE_CURRENT_LIST_FILE}")
define_property(TARGET PROPERTY SBK_WRAP_LINK_LIBRARIES
                BRIEF_DOCS "Additional link interface libraries for this target's wrapper library"
                FULL_DOCS "Property defined by ${CMAKE_CURRENT_LIST_FILE}")

if(PySide_FOUND)
    # Create 'virtual modules' for use as wrapping dependencies, starting with
    # common properties (note that any PySide dependency requires using the
    # pyside_global.h header, which in turn brings in all of Qt that is wrapped
    # by PySide, hence every 'virtual module' needs include paths for
    # everything)
    set(SHIBOKEN_VIRTUAL_DEPENDENCIES)
    set(_pyside_includes
        ${PYSIDE_INCLUDE_DIR}
        ${PYSIDE_INCLUDE_DIR}/QtCore
        ${PYSIDE_INCLUDE_DIR}/QtGui)
    foreach(_module Core Gui)
        add_library(PySide:${_module} UNKNOWN IMPORTED)
        string(TOLOWER "typesystem_${_module}.xml" _typesystem)
        set_target_properties(
            PySide:${_module} PROPERTIES
            SBK_TYPESYSTEM "${_typesystem}"
            SBK_GLOBAL_HEADER pyside_global.h
            SBK_TYPESYSTEM_PATHS "${PYSIDE_TYPESYSTEMS}"
            SBK_WRAP_INCLUDE_DIRS "${_pyside_includes}"
            SBK_WRAP_LINK_LIBRARIES "${PYSIDE_LIBRARY}")
        list(APPEND SHIBOKEN_VIRTUAL_DEPENDENCIES PySide:${_module})
    endforeach()
endif()

include(CMakeParseArguments)

###############################################################################

#------------------------------------------------------------------------------
# Function to concatenate strings in a list into a single string
function(sbk_cat VAR SEP)
    set(_result)
    foreach(_item ${ARGN})
        if(_result)
            set(_result "${_result}${SEP}${_item}")
        else()
            set(_result "${_item}")
        endif()
    endforeach()
    set(${VAR} "${_result}" PARENT_SCOPE)
endfunction()

#------------------------------------------------------------------------------
# Function to write content to a file, without spurious changes to time stamp
function(sbk_write_file PATH CONTENT)
    set(CMAKE_CONFIGURABLE_FILE_CONTENT "${CONTENT}")
    configure_file(
        "${CMAKE_ROOT}/Modules/CMakeConfigurableFile.in"
        "${PATH}" @ONLY)
endfunction()

#------------------------------------------------------------------------------
# Function to get the list of generated source files for a Shiboken wrapping.
function(sbk_get_generated_sources_list
    OUTPUT_VARIABLE
    TYPESYSTEM
    OUTPUT_DIRECTORY
)
    if(NOT OUTPUT_DIRECTORY)
        set(OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    set(GLOBAL_HEADER "") # Not needed for --list-outputs
    execute_process(
        COMMAND "${SHIBOKEN_BINARY}"
                --generatorSet=shiboken
                --list-outputs
                "--output-directory=${OUTPUT_DIRECTORY}"
                "${GLOBAL_HEADER}"
                "${TYPESYSTEM}"
        OUTPUT_VARIABLE _out)
    string(REPLACE "\n" ";" _out "${_out}")
    set(${OUTPUT_VARIABLE} "${_out}" PARENT_SCOPE)
endfunction()

#------------------------------------------------------------------------------
# Function to wrap a library using Shiboken
function(sbk_wrap_library NAME)
    set(_pyname ${NAME}Python)

    set(_named_arg_lists
        OBJECTS
        HEADERS
        DEPENDS
        EXTRA_INCLUDES
        LOCAL_INCLUDE_DIRECTORIES
        GENERATE_FLAGS
        COMPILE_FLAGS)
    cmake_parse_arguments(
        ""
        "NO_DEFAULT_HEURISTICS"
        "TYPESYSTEM;OUTPUT_NAME"
        "${_named_arg_lists}"
        ${ARGN})
    if(OUTPUT_NAME)
        set(_pyname "${OUTPUT_NAME}")
    endif()

    # Get base include directories
    get_directory_property(_extra_include_dirs INCLUDE_DIRECTORIES)
    if(_LOCAL_INCLUDE_DIRECTORIES)
        list(APPEND _extra_include_dirs ${_LOCAL_INCLUDE_DIRECTORIES})
    else()
        list(APPEND _extra_include_dirs
             ${CMAKE_CURRENT_SOURCE_DIR}
             ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    # Get list of typesystem dependencies and build paths for the same
    set(_typesystem_depends)
    set(_typesystem_paths)
    set(_extra_typesystems)
    set(_extra_link_libraries)
    foreach(_dep ${_DEPENDS})
        get_target_property(_dep_typesystem ${_dep} SBK_TYPESYSTEM)
        if(NOT _dep_typesystem)
            message(SEND_ERROR "${NAME} dependency ${_dep} is not a wrapped library")
        else()
            # Get typesystem and typesystem paths for dependency
            if(IS_ABSOLUTE "${_dep_typesystem}")
                list(APPEND _typesystem_depends "${_dep_typesystem}")
            endif()
            get_filename_component(_dep_typesystem_name "${_dep_typesystem}" NAME)
            get_filename_component(_dep_typesystem_path "${_dep_typesystem}" PATH)
            list(APPEND _extra_typesystems
                "  <load-typesystem name=\"${_dep_typesystem_name}\" generate=\"no\"/>")
            if(_dep_typesystem_path)
                list(APPEND _typesystem_paths "${_dep_typesystem_path}")
            endif()
            get_target_property(_dep_typesystem_paths ${_dep} SBK_TYPESYSTEM_PATHS)
            if(_dep_typesystem_paths)
                list(APPEND _typesystem_paths "${_dep_typesystem_paths}")
            endif()
            # Get global header for dependency
            get_target_property(_dep_global_header ${_dep} SBK_GLOBAL_HEADER)
            if(_dep_global_header)
                list(APPEND _EXTRA_INCLUDES "${_dep_global_header}")
            endif()
            # Get include directories for dependency
            get_target_property(_dep_wrap_includes ${_dep} SBK_WRAP_INCLUDE_DIRS)
            if(_dep_wrap_includes)
                list(APPEND _extra_include_dirs ${_dep_wrap_includes})
            endif()
            get_target_property(_target_includes ${_dep} INCLUDE_DIRECTORIES)
            list(APPEND _extra_include_dirs ${_target_includes})
            # Get additional link libraries for dependency (usually only set for
            # virtual modules)
            get_target_property(_dep_wrap_link_libraries ${_dep} SBK_WRAP_LINK_LIBRARIES)
            if(_dep_wrap_link_libraries)
                list(APPEND _extra_link_libraries ${_dep_wrap_link_libraries})
            endif()
        endif()
    endforeach()

    # Generate monolithic include file, as required by shiboken
    set(_global_header "${CMAKE_CURRENT_BINARY_DIR}/${NAME}_global.h")
    set(_depends)
    set(_content)
    foreach(_extra_include ${_EXTRA_INCLUDES})
        list(APPEND _content "#include <${_extra_include}>")
    endforeach()
    foreach(_hdr ${_HEADERS})
        get_filename_component(_hdr "${_hdr}" REALPATH)
        list(APPEND _depends "${_hdr}")
        list(APPEND _content "#include \"${_hdr}\"")
    endforeach()
    sbk_cat(_content "\n" ${_content})
    sbk_write_file("${_global_header}" "${_content}\n")

    # Get list of objects to wrap
    set(_objects)
    set(_type "object-type")
    foreach(_object ${_OBJECTS})
        if(_object STREQUAL "BY_REF")
            set(_type "object-type")
        elseif(_object STREQUAL "BY_VALUE")
            set(_type "value-type")
        elseif(_object STREQUAL "INTERFACES")
            set(_type "interface-type")
        else()
            list(APPEND _objects "  <${_type} name=\"${_object}\"/>")
        endif()
    endforeach()

    # Generate typesystem
    set(_typesystem "${CMAKE_CURRENT_BINARY_DIR}/${NAME}_typesystem.xml")
    if(_TYPESYSTEM)
        sbk_cat(EXTRA_TYPESYSTEMS "\n" "${_extra_typesystems}")
        sbk_cat(EXTRA_OBJECTS "\n" "${_objects}")
        set(TYPESYSTEM_NAME "${_pyname}")

        configure_file("${_TYPESYSTEM}" "${_typesystem}")
    else()
        sbk_cat(_content "\n"
                "<?xml version=\"1.0\"?>"
                "<typesystem package=\"${_pyname}\">"
                ${_extra_typesystems}
                ${_objects}
                "</typesystem>")
        sbk_write_file("${_typesystem}" "${_content}\n")
    endif()

    # Determine list of generated source files
    sbk_get_generated_sources_list(_sources "${_typesystem}")
    if(NOT _sources)
        message(FATAL_ERROR "sbk_wrap_library: no generated source files found "
                            "for wrapped library ${NAME}")
    endif()
    set_source_files_properties(${_sources} PROPERTIES GENERATED TRUE)

    # Define rule to run the generator
    list(REMOVE_DUPLICATES _includes)
    list(REMOVE_DUPLICATES _typesystem_paths)
    if(WIN32)
        sbk_cat(_includes ";" ${_extra_include_dirs})
        sbk_cat(_typesystem_paths ";" ${_typesystem_paths})
    else()
        sbk_cat(_includes ":" ${_extra_include_dirs})
        sbk_cat(_typesystem_paths ":" ${_typesystem_paths})
    endif()

    set(_shiboken_options --generatorSet=shiboken)
    if(NOT _NO_DEFAULT_HEURISTICS)
        list(APPEND _shiboken_options
             --enable-parent-ctor-heuristic
             --enable-return-value-heuristic)
    endif()
    if(PySide_FOUND AND _DEPENDS MATCHES "^PySide:")
        list(APPEND _shiboken_options --enable-pyside-extensions)
    endif()
    if(_GENERATE_FLAGS)
        list(APPEND _shiboken_options ${_GENERATE_FLAGS})
    endif()

    add_custom_command(
        OUTPUT ${_sources}
        DEPENDS ${_typesystem} ${_global_header} ${_depends} ${_typesystem_depends}
        COMMAND "${SHIBOKEN_BINARY}"
                ${_shiboken_options}
                "--include-paths=${_includes}"
                "--typesystem-paths=${_typesystem_paths}"
                "--output-directory=${CMAKE_CURRENT_BINARY_DIR}"
                "${_global_header}"
                "${_typesystem}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating Python bindings for ${NAME}")

    # Remove "special" dependencies
    if(_DEPENDS)
        list(REMOVE_ITEM _DEPENDS ${SHIBOKEN_VIRTUAL_DEPENDENCIES})
    endif()

    # Declare the wrapper library
    add_library(${_pyname} MODULE ${_sources})
    set_property(TARGET ${_pyname} PROPERTY PREFIX "")
    if(WIN32)
        set_property(TARGET sample PROPERTY SUFFIX ".pyd")
    endif()
    if(_COMPILE_FLAGS)
        sbk_cat(_flags " " ${_COMPILE_FLAGS})
        set_target_properties(${_pyname} PROPERTIES COMPILE_FLAGS "${_flags}")
    endif()
    target_compile_definitions(${_pyname} PRIVATE -DSBK_WRAPPED_CODE)
    target_include_directories(${_pyname} PRIVATE
        ${PYTHON_INCLUDE_DIRS}
        ${SHIBOKEN_INCLUDE_DIR}
        ${_extra_include_dirs})
    target_link_libraries(${_pyname} LINK_PRIVATE
        ${NAME}
        ${_DEPENDS}
        ${SHIBOKEN_PYTHON_LIBRARIES}
        ${SHIBOKEN_LIBRARY}
        ${_extra_link_libraries})

    foreach(_dep ${_DEPENDS})
        get_target_property(_pydep ${_dep} SBK_WRAPPER_TARGET)
        add_dependencies(${_pyname} ${_pydep})
    endforeach()

    # Record dependency information
    set_target_properties(
        ${NAME} PROPERTIES
        SBK_WRAPPER_TARGET ${_pyname}
        SBK_TYPESYSTEM "${_typesystem}"
        SBK_GLOBAL_HEADER "${_global_header}"
        SBK_TYPESYSTEM_PATHS "${_typesystem_paths}"
        SBK_WRAP_INCLUDE_DIRS "${CMAKE_CURRENT_BINARY_DIR}/${_pyname};${_extra_include_dirs}")
endfunction()
