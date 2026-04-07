cmake_minimum_required(VERSION 3.16)

project(MiniDashboard VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Szukamy tylko podstawowych modułów (Bez Shapes w C++)
find_package(Qt6 6.2 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup()

qt_add_executable(appMiniDashboard
    main.cpp
)

qt_add_qml_module(appMiniDashboard
    URI MiniDashboard
    VERSION 1.0
    QML_FILES
        main.qml
    RESOURCES
        Michroma-Regular.ttf
)

# Linkujemy tylko to co niezbędne
target_link_libraries(appMiniDashboard
    PRIVATE Qt6::Quick
    PRIVATE Qt6::QuickControls2
)
