# CMake generated Testfile for 
# Source directory: /home/loofi/Dokument/plasma43/plasma-ai-usage-monitor
# Build directory: /home/loofi/Dokument/plasma43/plasma-ai-usage-monitor/build-local
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(appstreamtest "/usr/bin/cmake" "-DAPPSTREAMCLI=/usr/bin/appstreamcli" "-DINSTALL_FILES=/home/loofi/Dokument/plasma43/plasma-ai-usage-monitor/build-local/install_manifest.txt" "-P" "/usr/share/ECM/kde-modules/appstreamtest.cmake")
set_tests_properties(appstreamtest PROPERTIES  _BACKTRACE_TRIPLES "/usr/share/ECM/kde-modules/KDECMakeSettings.cmake;173;add_test;/usr/share/ECM/kde-modules/KDECMakeSettings.cmake;191;appstreamtest;/usr/share/ECM/kde-modules/KDECMakeSettings.cmake;0;;/home/loofi/Dokument/plasma43/plasma-ai-usage-monitor/CMakeLists.txt;14;include;/home/loofi/Dokument/plasma43/plasma-ai-usage-monitor/CMakeLists.txt;0;")
subdirs("plugin")
