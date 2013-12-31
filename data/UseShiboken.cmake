#==============================================================================
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
#==============================================================================

#[[.rst:
UseShiboken
-----------

This module provides a set of functions that simplify wrapping libraries using
Shiboken. Using these macros, a simple library wrapping might look like:

.. code-block:: cmake

 set(mylib_SOURCES ...)
 set(mylib_SDK_HEADERS ...)
 add_library(mylib ${mylib_SOURCES})
 target_link_libraries(mylib ...)

 sbk_wrap_library(mylib
   OBJECTS ...
   HEADERS ${mylib_SDK_HEADERS})

Using :command:`sbk_wrap_library` can remove the need to create a "global"
header file (since the headers required by the wrapped objects are often the
same as the set of headers that are installed) and in trivial cases even a
typesystem XML. Additionally, it takes care of setting up the necessary build
rules and dependencies for the wrapper library, including propagation of
include, link and external typesystem dependencies for other wrapped libraries.

When necessary, a custom typesystem template may be specified. The default
template looks like::

 <?xml version="1.0"?>
 <typesystem package="@TYPESYSTEM_NAME@">
 @EXTRA_TYPESYSTEMS@
 @EXTRA_OBJECTS@
 </typesystem>

.. variable:: @TYPESYSTEM_NAME@

 In typesystem templates, replaced with the name of the wrapped library. This
 should always be used as the ``package`` attribute of the typesystem, as in
 the example above.

.. variable:: @EXTRA_TYPESYSTEMS@

 In typesystem templates, replaced with the XML to include the typesystems of
 any dependency wrapped libraries.

.. variable:: @EXTRA_OBJECTS@

 In typesystem templates, replaced with the XML to declare wrapped objects
 specified as arguments to :command:`sbk_wrap_library`.

Target Properties
'''''''''''''''''

The following properties are set on wrapped library targets by
:command:`sbk_wrap_library`, on both the C++ library and the wrapping library.
They are used for automatic injection of usage and dependency information in
conjunction with the ``DEPENDS`` option to :command:`sbk_wrap_library`.

.. prop_tgt:: SBK_WRAPPED_LIBRARY

 The (target) name of the wrapped C++ library associated with this target.
 Will be the same as the target name for the C++ library.

.. prop_tgt:: SBK_WRAPPER_TARGET

 The (target) name of the shiboken wrapping library associated with this
 target. Will be the same as the target name for the wrapping library. See also
 the ``OUTPUT_NAME`` option to :command:`sbk_wrap_library`.

.. prop_tgt:: SBK_TYPESYSTEM

 The Shiboken typesystem XML for this target's wrapper library.

.. prop_tgt:: SBK_GLOBAL_HEADER

 Path to the (generated) header file containing all includes for this target.
 The generated header of a wrapping library automatically includes the global
 headers of dependencies.

.. prop_tgt:: SBK_TYPESYSTEM_PATHS

 Path to the Shiboken typesystem for this target's wrapper library. When
 generating a wrapping library's typesystem, :variable:`@EXTRA_TYPESYSTEMS@`
 automatically includes the typesystems of dependencies.

.. prop_tgt:: SBK_WRAP_INCLUDE_DIRS

 Additional include directories for this target's wrapper library. This can be
 thought of as a wrapping-specific :variable:`INTERFACE_INCLUDE_DIRECTORIES`,
 and is used in much the same manner.

.. prop_tgt:: SBK_WRAP_LINK_LIBRARIES

 Additional link interface libraries for this target's wrapper library. Like
 :variable:`SBK_WRAP_INCLUDE_DIRS`, this can be thought of as a
 wrapping-specific :variable:`INTERFACE_LINK_LIBRARIES`, and is used in much
 the same manner. Unlike :variable:`SBK_WRAP_INCLUDE_DIRS`, since wrapping
 libraries usually do not need to link to each other, this is usually only set
 for 'virtual' modules (e.g. ``PySide:Core``).

#]]

###############################################################################

# Dependencies use target usage requirements, which were added in 2.8.11; ergo
# we require at least that version
cmake_minimum_required(VERSION 2.8.11)

find_package(PythonLibs REQUIRED)
find_package(Shiboken REQUIRED)
find_package(PySide)

set(PYTHON_SHORT python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})

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

#==============================================================================
#[[.rst:
.. command:: sbk_cat

 Concatenate strings in a list into a single string.

 Parameters
 ----------

 :``VAR``: Output variable into which the result will be placed.
 :``SEP``: String used to join adjacent tokens.
 :``<ARGN>``: Tokens to be joined.

 Example
 -------

 .. code-block:: cmake
  sbk_cat(out "," a b c d e)

#]]
#------------------------------------------------------------------------------
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

#==============================================================================
#[[.rst:
.. command:: sbk_write_file

 Write content to a file, only if the contents would change. This is used to
 write a file without changing the time stamp (and causing build dependencies
 to become out of date) unnecessarily.

 Parameters
 ----------

 :``PATH``: Path to the file to be written.
 :``CONTENT``: Content to write to the file.

#]]
#------------------------------------------------------------------------------
function(sbk_write_file PATH CONTENT)
    set(CMAKE_CONFIGURABLE_FILE_CONTENT "${CONTENT}")
    configure_file(
        "${CMAKE_ROOT}/Modules/CMakeConfigurableFile.in"
        "${PATH}" @ONLY)
endfunction()

#==============================================================================
#[[.rst:
.. command:: sbk_get_generated_sources_list

 Get the list of files that Shiboken will generate for a library wrapping,
 based on the specified typesystem. This executes Shiboken with the
 ``--list-outputs`` option.

 Parameters
 ----------

 :``OUTPUT_VARIABLE``: Output variable into which the result will be placed.
 :``TYPESYSTEM``: Path to the typesystem XML file for the library wrapping.
 :``OUTPUT_DIRECTORY``:
   (Optional) Directory to which generated files would be written. This is
   passed to Shiboken and appears as part of the names of generated files.
   Defaults to ``${CMAKE_CURRENT_BINARY_DIR}``.

#]]
#------------------------------------------------------------------------------
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

#==============================================================================
#[[.rst:
.. command:: sbk_wrap_library

 Generate a Python wrapping library for the specified C++ library. See the
 `UseShiboken`_ overview for further details and a simple example.

 Parameters
 ----------

 :``NAME``: CMake target name of the library to be wrapped.

 Options
 -------
 :``NO_DEFAULT_HEURISTICS``:
   (Boolean) By default, the ``--enable-parent-ctor-heuristic`` and
   ``--enable-return-value-heuristic`` are passed to Shiboken. Giving this
   option instructs ``sbk_wrap_library`` to omit them.
 :``TYPESYSTEM``:
   (String) Path to a custom typesystem template. ``sbk_wrap_library`` will use
   a default template that is sufficient for trivial wrappings. For more
   complex cases, this allows a custom typesystem template to be used instead.
 :``OUTPUT_NAME``:
   (String) Name of the output library (also the Shiboken package name). The
   default is ``${NAME}Python``. See also :variable:`@TYPESYSTEM_NAME@`.
 :``OBJECTS``:
   (List) Names of objects (i.e. classes, structs) to be wrapped.
   Object names following ``BY_REF`` will be wrapped as ``object-type``.
   Object names following ``BY_VALUE`` will be wrapped as ``value-type``.
   Object names following ``INTERFACES`` will be wrapped as ``interface-type``.
   The default is ``BY_REF``. Type specifiers may be used more than once.
 :``HEADERS``:
   (List) Paths to headers that will be used to build the type system. Ideally
   this will be e.g. ``${mylib_SDK_HEADERS}``.
 :``DEPENDS``:
   (List) Target names of wrapped libraries on which this wrapping depends.
   Note that the names of the C++ libraries, not the wrapper libraries, should
   be given. As an exception, if PySide was found, the names ``PySide:Core``
   and ``PySide:Gui`` are also supported.
 :``EXTRA_INCLUDES``:
   (List) Additional (system) headers to include before the library headers in
   the wrapping library global header. (Headers for dependencies are included
   automatically and do not need to be listed.)
 :``LOCAL_INCLUDE_DIRECTORIES``:
   (List) Additional include directories (besides the C++ library and current
   directory includes, which are added automatically) needed to build the
   wrapping library.
 :``GENERATE_FLAGS``:
   (List) Additional options to pass to Shiboken.
 :``COMPILE_FLAGS``:
   (List) Additional compile flags to set on the wrapping library.

#]]
#------------------------------------------------------------------------------
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
        ${NAME} ${_pyname} PROPERTIES
        SBK_WRAPPED_LIBRARY ${NAME}
        SBK_WRAPPER_TARGET ${_pyname}
        SBK_TYPESYSTEM "${_typesystem}"
        SBK_GLOBAL_HEADER "${_global_header}"
        SBK_TYPESYSTEM_PATHS "${_typesystem_paths}"
        SBK_WRAP_INCLUDE_DIRS "${CMAKE_CURRENT_BINARY_DIR}/${_pyname};${_extra_include_dirs}")
endfunction()
