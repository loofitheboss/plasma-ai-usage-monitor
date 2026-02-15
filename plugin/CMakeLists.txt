set(aiusagemonitor_SRCS
    aiusageplugin.cpp
    secretsmanager.cpp
    providerbackend.cpp
    openaicompatibleprovider.cpp
    openaiprovider.cpp
    anthropicprovider.cpp
    googleprovider.cpp
    mistralprovider.cpp
    deepseekprovider.cpp
    groqprovider.cpp
    xaiprovider.cpp
    usagedatabase.cpp
    subscriptiontoolbackend.cpp
    claudecodemonitor.cpp
    codexclimonitor.cpp
    copilotmonitor.cpp
)

set(aiusagemonitor_HDRS
    aiusageplugin.h
    secretsmanager.h
    providerbackend.h
    openaicompatibleprovider.h
    openaiprovider.h
    anthropicprovider.h
    googleprovider.h
    mistralprovider.h
    deepseekprovider.h
    groqprovider.h
    xaiprovider.h
    usagedatabase.h
    clipboardhelper.h
    updatechecker.h
    subscriptiontoolbackend.h
    claudecodemonitor.h
    codexclimonitor.h
    copilotmonitor.h
)

add_library(aiusagemonitorplugin SHARED ${aiusagemonitor_SRCS} ${aiusagemonitor_HDRS})

target_link_libraries(aiusagemonitorplugin
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    Qt6::Sql
    KF6::Wallet
    KF6::Notifications
    KF6::I18n
)

install(TARGETS aiusagemonitorplugin DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/loofi/aiusagemonitor)
install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/loofi/aiusagemonitor)
