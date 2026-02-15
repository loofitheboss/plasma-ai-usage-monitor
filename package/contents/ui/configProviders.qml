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
    property alias cfg_openaiCustomBaseUrl: openaiBaseUrlField.text

    property alias cfg_anthropicEnabled: anthropicSwitch.checked
    property alias cfg_anthropicModel: anthropicModelField.text
    property alias cfg_anthropicCustomBaseUrl: anthropicBaseUrlField.text

    property alias cfg_googleEnabled: googleSwitch.checked
    property alias cfg_googleModel: googleModelField.text
    property alias cfg_googleCustomBaseUrl: googleBaseUrlField.text

    property alias cfg_mistralEnabled: mistralSwitch.checked
    property alias cfg_mistralModel: mistralModelField.text
    property alias cfg_mistralCustomBaseUrl: mistralBaseUrlField.text

    property alias cfg_deepseekEnabled: deepseekSwitch.checked
    property alias cfg_deepseekModel: deepseekModelField.text
    property alias cfg_deepseekCustomBaseUrl: deepseekBaseUrlField.text

    property alias cfg_groqEnabled: groqSwitch.checked
    property alias cfg_groqModel: groqModelField.text
    property alias cfg_groqCustomBaseUrl: groqBaseUrlField.text

    property alias cfg_xaiEnabled: xaiSwitch.checked
    property alias cfg_xaiModel: xaiModelField.text
    property alias cfg_xaiCustomBaseUrl: xaiBaseUrlField.text

    // Track whether the user has actually edited each key field
    property bool openaiKeyDirty: false
    property bool anthropicKeyDirty: false
    property bool googleKeyDirty: false
    property bool mistralKeyDirty: false
    property bool deepseekKeyDirty: false
    property bool groqKeyDirty: false
    property bool xaiKeyDirty: false

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
        var providers = [
            { name: "openai", field: openaiKeyField, dirtyProp: "openaiKeyDirty" },
            { name: "anthropic", field: anthropicKeyField, dirtyProp: "anthropicKeyDirty" },
            { name: "google", field: googleKeyField, dirtyProp: "googleKeyDirty" },
            { name: "mistral", field: mistralKeyField, dirtyProp: "mistralKeyDirty" },
            { name: "deepseek", field: deepseekKeyField, dirtyProp: "deepseekKeyDirty" },
            { name: "groq", field: groqKeyField, dirtyProp: "groqKeyDirty" },
            { name: "xai", field: xaiKeyField, dirtyProp: "xaiKeyDirty" }
        ];

        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (secrets.hasKey(p.name)) {
                p.field.text = "********";
                providersPage[p.dirtyProp] = false;
            } else {
                p.field.text = "";
            }
        }
    }

    function saveKeys() {
        var providers = [
            { name: "openai", field: openaiKeyField, dirty: openaiKeyDirty },
            { name: "anthropic", field: anthropicKeyField, dirty: anthropicKeyDirty },
            { name: "google", field: googleKeyField, dirty: googleKeyDirty },
            { name: "mistral", field: mistralKeyField, dirty: mistralKeyDirty },
            { name: "deepseek", field: deepseekKeyField, dirty: deepseekKeyDirty },
            { name: "groq", field: groqKeyField, dirty: groqKeyDirty },
            { name: "xai", field: xaiKeyField, dirty: xaiKeyDirty }
        ];

        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p.dirty && p.field.text.length > 0 && p.field.text !== "********") {
                secrets.storeKey(p.name, p.field.text);
            } else if (p.dirty && p.field.text.length === 0) {
                secrets.removeKey(p.name);
            }
        }
    }

    Component.onCompleted: {
        if (secrets.walletOpen) {
            loadKeys();
        }
    }

    Component.onDestruction: {
        saveKeys();
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        // ══════════════════════════════════════════════
        // ── OpenAI ──
        // ══════════════════════════════════════════════

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
                onTextEdited: providersPage.openaiKeyDirty = true
            }

            QQC2.ToolButton {
                id: openaiKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: openaiKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { openaiKeyField.text = ""; providersPage.openaiKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: openaiSwitch.checked
            text: i18n("Requires an Admin API key for usage/costs endpoints")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
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

        QQC2.TextField {
            id: openaiBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: openaiSwitch.checked
            text: plasmoid.configuration.openaiCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: openaiBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Anthropic ──
        // ══════════════════════════════════════════════

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
                onTextEdited: providersPage.anthropicKeyDirty = true
            }

            QQC2.ToolButton {
                id: anthropicKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: anthropicKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { anthropicKeyField.text = ""; providersPage.anthropicKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: anthropicSwitch.checked
            text: i18n("Shows rate limit status only (Anthropic has no usage API)")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
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
            property alias text: anthropicModelField.editText
        }

        QQC2.TextField {
            id: anthropicBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: anthropicSwitch.checked
            text: plasmoid.configuration.anthropicCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: anthropicBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Google Gemini ──
        // ══════════════════════════════════════════════

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
                onTextEdited: providersPage.googleKeyDirty = true
            }

            QQC2.ToolButton {
                id: googleKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: googleKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { googleKeyField.text = ""; providersPage.googleKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: googleSwitch.checked
            text: i18n("Shows connectivity status and known tier limits")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
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

        QQC2.TextField {
            id: googleBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: googleSwitch.checked
            text: plasmoid.configuration.googleCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: googleBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Mistral AI ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mistral AI")
        }

        QQC2.Switch {
            id: mistralSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.mistralEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: mistralKeyField
                enabled: mistralSwitch.checked
                echoMode: mistralKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Mistral API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.mistralKeyDirty = true
            }

            QQC2.ToolButton {
                id: mistralKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: mistralKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { mistralKeyField.text = ""; providersPage.mistralKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: mistralSwitch.checked
            text: i18n("Rate limits and token usage via chat/completions endpoint")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: mistralModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: mistralSwitch.checked
            editable: true
            editText: plasmoid.configuration.mistralModel
            model: [
                "mistral-large-latest",
                "mistral-medium-latest",
                "mistral-small-latest",
                "open-mistral-7b",
                "open-mixtral-8x7b",
                "codestral-latest"
            ]
            onEditTextChanged: plasmoid.configuration.mistralModel = editText
            property alias text: mistralModelField.editText
        }

        QQC2.TextField {
            id: mistralBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: mistralSwitch.checked
            text: plasmoid.configuration.mistralCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: mistralBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── DeepSeek ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("DeepSeek")
        }

        QQC2.Switch {
            id: deepseekSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.deepseekEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: deepseekKeyField
                enabled: deepseekSwitch.checked
                echoMode: deepseekKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter DeepSeek API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.deepseekKeyDirty = true
            }

            QQC2.ToolButton {
                id: deepseekKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: deepseekKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { deepseekKeyField.text = ""; providersPage.deepseekKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: deepseekSwitch.checked
            text: i18n("Tracks rate limits, token usage, and account balance")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: deepseekModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: deepseekSwitch.checked
            editable: true
            editText: plasmoid.configuration.deepseekModel
            model: [
                "deepseek-chat",
                "deepseek-coder",
                "deepseek-reasoner"
            ]
            onEditTextChanged: plasmoid.configuration.deepseekModel = editText
            property alias text: deepseekModelField.editText
        }

        QQC2.TextField {
            id: deepseekBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: deepseekSwitch.checked
            text: plasmoid.configuration.deepseekCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: deepseekBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Groq ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Groq")
        }

        QQC2.Switch {
            id: groqSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.groqEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: groqKeyField
                enabled: groqSwitch.checked
                echoMode: groqKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Groq API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.groqKeyDirty = true
            }

            QQC2.ToolButton {
                id: groqKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: groqKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { groqKeyField.text = ""; providersPage.groqKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: groqSwitch.checked
            text: i18n("OpenAI-compatible API with rate limit headers")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: groqModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: groqSwitch.checked
            editable: true
            editText: plasmoid.configuration.groqModel
            model: [
                "llama-3.3-70b-versatile",
                "llama-3.1-8b-instant",
                "mixtral-8x7b-32768",
                "gemma2-9b-it"
            ]
            onEditTextChanged: plasmoid.configuration.groqModel = editText
            property alias text: groqModelField.editText
        }

        QQC2.TextField {
            id: groqBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: groqSwitch.checked
            text: plasmoid.configuration.groqCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: groqBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── xAI / Grok ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("xAI / Grok")
        }

        QQC2.Switch {
            id: xaiSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.xaiEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: xaiKeyField
                enabled: xaiSwitch.checked
                echoMode: xaiKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter xAI API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.xaiKeyDirty = true
            }

            QQC2.ToolButton {
                id: xaiKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: xaiKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { xaiKeyField.text = ""; providersPage.xaiKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: xaiSwitch.checked
            text: i18n("OpenAI-compatible API for Grok models")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: xaiModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: xaiSwitch.checked
            editable: true
            editText: plasmoid.configuration.xaiModel
            model: [
                "grok-3",
                "grok-3-mini",
                "grok-2",
                "grok-2-mini"
            ]
            onEditTextChanged: plasmoid.configuration.xaiModel = editText
            property alias text: xaiModelField.editText
        }

        QQC2.TextField {
            id: xaiBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: xaiSwitch.checked
            text: plasmoid.configuration.xaiCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: xaiBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
