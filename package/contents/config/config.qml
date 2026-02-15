import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Providers")
        icon: "network-connect"
        source: "configProviders.qml"
    }
    ConfigCategory {
        name: i18n("Alerts")
        icon: "dialog-warning"
        source: "configAlerts.qml"
    }
}
