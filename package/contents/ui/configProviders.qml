import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import com.github.loofi.aiusagemonitor 1.0

KCM.SimpleKCM {
    id: providersPage

    property alias cfg_openaiEnabled: openaiSwitch.checked
    property alias cfg_openaiModel: openaiModelField.text
    property alias cfg_openaiProjectId: openaiProjectField.text

    property alias cfg_anthropicEnabled: anthropicSwitch.checked
    property alias cfg_anthropicModel: anthropicModelField.text

    property alias cfg_googleEnabled: googleSwitch.checked
    property alias cfg_googleModel: googleModelField.text

    // Track whether the user has actually edited each key field
    // so we don't overwrite the real key with the masked placeholder
    property bool openaiKeyDirty: false
    property bool anthropicKeyDirty: false
    property bool googleKeyDirty: false

    // ── KWallet Integration ──
    SecretsManager {
        id: secrets

        onWalletOpenChanged: {
            if (walletOpen) {
                loadKeys();
            }
        }

        onKeyStored: function(provider) {
            console.log("Key stored for", provider);
        }

        onError: function(message) {
            console.warn("SecretsManager error:", message);
        }
    }

    function loadKeys() {
        // Load actual key presence from KWallet and display masked or empty
        if (secrets.hasKey("openai")) {
            openaiKeyField.text = "********";
            openaiKeyDirty = false;
        } else {
            openaiKeyField.text = "";
        }

        if (secrets.hasKey("anthropic")) {
            anthropicKeyField.text = "********";
            anthropicKeyDirty = false;
        } else {
            anthropicKeyField.text = "";
        }

        if (secrets.hasKey("google")) {
            googleKeyField.text = "********";
            googleKeyDirty = false;
        } else {
            googleKeyField.text = "";
        }
    }

    function saveKeys() {
        // Only store keys that the user actually edited
        if (openaiKeyDirty && openaiKeyField.text.length > 0 && openaiKeyField.text !== "********") {
            secrets.storeKey("openai", openaiKeyField.text);
        } else if (openaiKeyDirty && openaiKeyField.text.length === 0) {
            secrets.removeKey("openai");
        }

        if (anthropicKeyDirty && anthropicKeyField.text.length > 0 && anthropicKeyField.text !== "********") {
            secrets.storeKey("anthropic", anthropicKeyField.text);
        } else if (anthropicKeyDirty && anthropicKeyField.text.length === 0) {
            secrets.removeKey("anthropic");
        }

        if (googleKeyDirty && googleKeyField.text.length > 0 && googleKeyField.text !== "********") {
            secrets.storeKey("google", googleKeyField.text);
        } else if (googleKeyDirty && googleKeyField.text.length === 0) {
            secrets.removeKey("google");
        }
    }

    Component.onCompleted: {
        if (secrets.walletOpen) {
            loadKeys();
        }
    }

    // Save keys when the config page is about to be destroyed (user clicks OK/Apply)
    Component.onDestruction: {
        saveKeys();
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        // ── OpenAI ──────────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("OpenAI")
        }

        QQC2.Switch {
            id: openaiSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.openaiEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Admin API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: openaiKeyField
                enabled: openaiSwitch.checked
                echoMode: openaiKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("sk-admin-...")
                Layout.fillWidth: true

                onTextEdited: {
                    providersPage.openaiKeyDirty = true;
                }
            }

            QQC2.ToolButton {
                id: openaiKeyVisible
                checkable: true
                checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: openaiKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key")
                QQC2.ToolTip.visible: hovered
                onClicked: {
                    openaiKeyField.text = "";
                    providersPage.openaiKeyDirty = true;
                }
            }
        }

        QQC2.Label {
            visible: openaiSwitch.checked
            text: i18n("Requires an Admin API key for usage/costs endpoints")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: openaiModelField
            Kirigami.FormData.label: i18n("Model filter:")
            enabled: openaiSwitch.checked
            text: plasmoid.configuration.openaiModel
            placeholderText: "gpt-4o"
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: openaiProjectField
            Kirigami.FormData.label: i18n("Project ID (optional):")
            enabled: openaiSwitch.checked
            text: plasmoid.configuration.openaiProjectId
            placeholderText: "proj_..."
            Layout.fillWidth: true
        }

        // ── Anthropic ──────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Anthropic")
        }

        QQC2.Switch {
            id: anthropicSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.anthropicEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: anthropicKeyField
                enabled: anthropicSwitch.checked
                echoMode: anthropicKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("sk-ant-...")
                Layout.fillWidth: true

                onTextEdited: {
                    providersPage.anthropicKeyDirty = true;
                }
            }

            QQC2.ToolButton {
                id: anthropicKeyVisible
                checkable: true
                checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: anthropicKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key")
                QQC2.ToolTip.visible: hovered
                onClicked: {
                    anthropicKeyField.text = "";
                    providersPage.anthropicKeyDirty = true;
                }
            }
        }

        QQC2.Label {
            visible: anthropicSwitch.checked
            text: i18n("Shows rate limit status only (Anthropic has no usage API)")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: anthropicModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: anthropicSwitch.checked
            editable: true
            editText: plasmoid.configuration.anthropicModel
            model: [
                "claude-sonnet-4-20250514",
                "claude-opus-4-20250514",
                "claude-haiku-4-20250514",
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022"
            ]
            onEditTextChanged: plasmoid.configuration.anthropicModel = editText

            // Bind alias to editText for config saving
            property alias text: anthropicModelField.editText
        }

        // ── Google Gemini ──────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Google Gemini")
        }

        QQC2.Switch {
            id: googleSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.googleEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: googleKeyField
                enabled: googleSwitch.checked
                echoMode: googleKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("AIza...")
                Layout.fillWidth: true

                onTextEdited: {
                    providersPage.googleKeyDirty = true;
                }
            }

            QQC2.ToolButton {
                id: googleKeyVisible
                checkable: true
                checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: googleKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key")
                QQC2.ToolTip.visible: hovered
                onClicked: {
                    googleKeyField.text = "";
                    providersPage.googleKeyDirty = true;
                }
            }
        }

        QQC2.Label {
            visible: googleSwitch.checked
            text: i18n("Shows connectivity status and known tier limits")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: googleModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: googleSwitch.checked
            editable: true
            editText: plasmoid.configuration.googleModel
            model: [
                "gemini-2.0-flash",
                "gemini-2.0-flash-lite",
                "gemini-2.5-pro-preview-05-06",
                "gemini-2.5-flash-preview-04-17",
                "gemini-1.5-pro",
                "gemini-1.5-flash"
            ]
            onEditTextChanged: plasmoid.configuration.googleModel = editText

            property alias text: googleModelField.editText
        }
    }
}
