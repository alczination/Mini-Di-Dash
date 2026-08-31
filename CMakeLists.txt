set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
cmake_minimum_required(VERSION 3.16)

project(MiniDashboard VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Network)

qt_standard_project_setup()

qt_add_executable(appMiniDashboard
    main.cpp

    CanBusBackend.h
)

qt_add_qml_module(appMiniDashboard
    URI MiniDashboard
    VERSION 1.0
    QML_FILES
        Main.qml
        ClassicTheme.qml
        EngineMode.qml
        TripMode.qml
        TurboMode.qml
        InspectionMode.qml
        ParkMode.qml
        TiresMode.qml
        SettingsMode.qml
        LcdPanel.qml
    RESOURCES
        assets/Michroma-Regular.ttf
        assets/mini_logo.png
        assets/minimodern_logo.png
        assets/mini_slogo.png
        assets/model_electricblue.png
        control_lights/tank_light.png
        control_lights/avg_consumption.png
        control_lights/trip_light.png
        control_lights/temp_light.png
        control_lights/oil_light.png
        control_lights/handbrake_light.png
        control_lights/check_light.png
        control_lights/abs_light.png
        control_lights/dsc_light.png
        control_lights/airbag_light.png
        control_lights/lowtempoutside_light.png
        control_lights/dooropen_light.png
        control_lights/hoodopen_light.png
        control_lights/trunkopen_light.png
        control_lights/highbeam_light.png
        control_lights/turbo_symbol.png
        control_lights/gas_symbol.png
        control_lights/intake_symbol.png
        SOURCES
        SOURCES
)

target_include_directories(appMiniDashboard PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR} # To kieruje kompilator bezpośrednio do folderu build
)

target_link_libraries(appMiniDashboard
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appMiniDashboard
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
