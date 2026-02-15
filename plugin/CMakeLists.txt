set(aiusagemonitor_SRCS
    aiusageplugin.cpp
    secretsmanager.cpp
    providerbackend.cpp
    openaiprovider.cpp
    anthropicprovider.cpp
    googleprovider.cpp
)

set(aiusagemonitor_HDRS
    aiusageplugin.h
    secretsmanager.h
    providerbackend.h
    openaiprovider.h
    anthropicprovider.h
    googleprovider.h
)

add_library(aiusagemonitorplugin SHARED ${aiusagemonitor_SRCS} ${aiusagemonitor_HDRS})

target_link_libraries(aiusagemonitorplugin
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    KF6::Wallet
    KF6::Notifications
    KF6::I18n
)

install(TARGETS aiusagemonitorplugin DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/loofi/aiusagemonitor)
install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/loofi/aiusagemonitor)
