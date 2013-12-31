if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(LIBRARY_OUTPUT_SUFFIX ${CMAKE_DEBUG_POSTFIX})
else()
    set(LIBRARY_OUTPUT_SUFFIX ${CMAKE_RELEASE_POSTFIX})
endif()

add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/UseShiboken.cmake"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/ReformatRst.py"
            "${CMAKE_CURRENT_SOURCE_DIR}/UseShiboken.cmake"
    COMMAND "${PYTHON_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/ReformatRst.py"
            "${CMAKE_CURRENT_SOURCE_DIR}/UseShiboken.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/UseShiboken.cmake")

add_custom_target(data ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/UseShiboken.cmake")
add_dependencies(data shiboken)
get_target_property(SHIBOKEN_GENERATOR shiboken OUTPUT_NAME)

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/ShibokenConfig.cmake.in"
               "${CMAKE_CURRENT_BINARY_DIR}/ShibokenConfig.cmake" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/ShibokenConfig-spec.cmake.in"
               "${CMAKE_CURRENT_BINARY_DIR}/ShibokenConfig${PYTHON_SUFFIX}.cmake" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/ShibokenConfigVersion.cmake.in"
               "${CMAKE_CURRENT_BINARY_DIR}/ShibokenConfigVersion.cmake" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/shiboken.pc.in"
               "${CMAKE_CURRENT_BINARY_DIR}/shiboken${shiboken_SUFFIX}.pc" @ONLY)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ShibokenConfig.cmake"
        DESTINATION "${LIB_INSTALL_DIR}/cmake/Shiboken-${shiboken_VERSION}")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ShibokenConfig${PYTHON_SUFFIX}.cmake"
        DESTINATION "${LIB_INSTALL_DIR}/cmake/Shiboken-${shiboken_VERSION}")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ShibokenConfigVersion.cmake"
        DESTINATION "${LIB_INSTALL_DIR}/cmake/Shiboken-${shiboken_VERSION}")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/shiboken${shiboken_SUFFIX}.pc"
        DESTINATION "${LIB_INSTALL_DIR}/pkgconfig")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/UseShiboken.cmake"
        DESTINATION "${LIB_INSTALL_DIR}/cmake/Shiboken-${shiboken_VERSION}")
