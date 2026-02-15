import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import com.github.loofi.aiusagemonitor 1.0

KCM.SimpleKCM {
    id: subscriptionsPage

    // ── Claude Code ──
    property alias cfg_claudeCodeEnabled: claudeCodeSwitch.checked
    property alias cfg_claudeCodePlan: claudeCodePlanCombo.currentIndex
    property alias cfg_claudeCodeCustomLimit: claudeCodeLimitSpin.value
    property alias cfg_claudeCodeNotifications: claudeCodeNotifySwitch.checked

    // ── Codex CLI ──
    property alias cfg_codexEnabled: codexSwitch.checked
    property alias cfg_codexPlan: codexPlanCombo.currentIndex
    property alias cfg_codexCustomLimit: codexLimitSpin.value
    property alias cfg_codexNotifications: codexNotifySwitch.checked

    // ── GitHub Copilot ──
    property alias cfg_copilotEnabled: copilotSwitch.checked
    property alias cfg_copilotPlan: copilotPlanCombo.currentIndex
    property alias cfg_copilotCustomLimit: copilotLimitSpin.value
    property alias cfg_copilotNotifications: copilotNotifySwitch.checked
    property alias cfg_copilotOrgName: copilotOrgField.text

    // Track key dirtiness for Copilot PAT
    property bool copilotTokenDirty: false

    // ── Temporary monitors for detection ──
    ClaudeCodeMonitor {
        id: claudeDetector
        Component.onCompleted: checkToolInstalled()
    }

    CodexCliMonitor {
        id: codexDetector
        Component.onCompleted: checkToolInstalled()
    }

    CopilotMonitor {
        id: copilotDetector
        Component.onCompleted: checkToolInstalled()
    }

    // ── KWallet Integration for Copilot token ──
    SecretsManager {
        id: secrets

        onWalletOpenChanged: {
            if (walletOpen) {
                loadCopilotToken();
            }
        }

        onKeyStored: function(provider) {
            console.log("Key stored for", provider);
        }

        onError: function(message) {
            console.warn("SecretsManager error:", message);
        }
    }

    function loadCopilotToken() {
        if (secrets.hasKey("copilot_github")) {
            copilotTokenField.text = "********";
            copilotTokenDirty = false;
        } else {
            copilotTokenField.text = "";
        }
    }

    function saveCopilotToken() {
        if (copilotTokenDirty && copilotTokenField.text.length > 0 && copilotTokenField.text !== "********") {
            secrets.storeKey("copilot_github", copilotTokenField.text);
        } else if (copilotTokenDirty && copilotTokenField.text.length === 0) {
            secrets.removeKey("copilot_github");
        }
    }

    Component.onCompleted: {
        if (secrets.walletOpen) {
            loadCopilotToken();
        }
    }

    Component.onDestruction: {
        saveCopilotToken();
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        // ── Description ──
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Track usage limits for AI coding tools with fixed subscription quotas. "
                     + "These tools don't expose public APIs for quota checking, so usage is "
                     + "tracked locally via filesystem monitoring and manual counting.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
        }

        // ══════════════════════════════════════════════
        // ── Claude Code ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Claude Code")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Enable:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.Switch {
                id: claudeCodeSwitch
                checked: plasmoid.configuration.claudeCodeEnabled
            }

            // Detection status
            QQC2.Label {
                text: claudeDetector.installed
                    ? "✓ " + i18n("Detected")
                    : "✗ " + i18n("Not found")
                color: claudeDetector.installed
                    ? Kirigami.Theme.positiveTextColor
                    : Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        QQC2.ComboBox {
            id: claudeCodePlanCombo
            Kirigami.FormData.label: i18n("Plan:")
            enabled: claudeCodeSwitch.checked
            model: claudeDetector.availablePlans()
            currentIndex: plasmoid.configuration.claudeCodePlan
            onCurrentIndexChanged: {
                // Auto-fill default limit when plan changes
                var plans = claudeDetector.availablePlans();
                if (currentIndex >= 0 && currentIndex < plans.length) {
                    var def = claudeDetector.defaultLimitForPlan(plans[currentIndex]);
                    if (claudeCodeLimitSpin.value === 0 || !claudeCodeLimitOverride.checked) {
                        claudeCodeLimitSpin.value = def;
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Usage limit (per 5h):")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: claudeCodeLimitSpin
                enabled: claudeCodeSwitch.checked
                from: 0
                to: 99999
                value: plasmoid.configuration.claudeCodeCustomLimit
                editable: true

                Component.onCompleted: {
                    // Set default from plan if not custom
                    if (value === 0) {
                        var plans = claudeDetector.availablePlans();
                        var idx = claudeCodePlanCombo.currentIndex;
                        if (idx >= 0 && idx < plans.length) {
                            value = claudeDetector.defaultLimitForPlan(plans[idx]);
                        }
                    }
                }
            }

            QQC2.CheckBox {
                id: claudeCodeLimitOverride
                text: i18n("Custom")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        QQC2.Label {
            visible: claudeCodeSwitch.checked
            text: i18n("Claude Code also has a weekly rolling limit. The secondary limit "
                     + "is automatically calculated from the plan tier.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Switch {
            id: claudeCodeNotifySwitch
            Kirigami.FormData.label: i18n("Notifications:")
            enabled: claudeCodeSwitch.checked
            checked: plasmoid.configuration.claudeCodeNotifications
        }

        // ══════════════════════════════════════════════
        // ── Codex CLI ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Codex CLI")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Enable:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.Switch {
                id: codexSwitch
                checked: plasmoid.configuration.codexEnabled
            }

            QQC2.Label {
                text: codexDetector.installed
                    ? "✓ " + i18n("Detected")
                    : "✗ " + i18n("Not found")
                color: codexDetector.installed
                    ? Kirigami.Theme.positiveTextColor
                    : Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        QQC2.ComboBox {
            id: codexPlanCombo
            Kirigami.FormData.label: i18n("Plan:")
            enabled: codexSwitch.checked
            model: codexDetector.availablePlans()
            currentIndex: plasmoid.configuration.codexPlan
            onCurrentIndexChanged: {
                var plans = codexDetector.availablePlans();
                if (currentIndex >= 0 && currentIndex < plans.length) {
                    var def = codexDetector.defaultLimitForPlan(plans[currentIndex]);
                    if (codexLimitSpin.value === 0 || !codexLimitOverride.checked) {
                        codexLimitSpin.value = def;
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Usage limit (per 5h):")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: codexLimitSpin
                enabled: codexSwitch.checked
                from: 0
                to: 99999
                value: plasmoid.configuration.codexCustomLimit
                editable: true

                Component.onCompleted: {
                    if (value === 0) {
                        var plans = codexDetector.availablePlans();
                        var idx = codexPlanCombo.currentIndex;
                        if (idx >= 0 && idx < plans.length) {
                            value = codexDetector.defaultLimitForPlan(plans[idx]);
                        }
                    }
                }
            }

            QQC2.CheckBox {
                id: codexLimitOverride
                text: i18n("Custom")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        QQC2.Switch {
            id: codexNotifySwitch
            Kirigami.FormData.label: i18n("Notifications:")
            enabled: codexSwitch.checked
            checked: plasmoid.configuration.codexNotifications
        }

        // ══════════════════════════════════════════════
        // ── GitHub Copilot ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("GitHub Copilot")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Enable:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.Switch {
                id: copilotSwitch
                checked: plasmoid.configuration.copilotEnabled
            }

            QQC2.Label {
                text: copilotDetector.installed
                    ? "✓ " + i18n("Detected")
                    : "✗ " + i18n("Not found")
                color: copilotDetector.installed
                    ? Kirigami.Theme.positiveTextColor
                    : Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        QQC2.ComboBox {
            id: copilotPlanCombo
            Kirigami.FormData.label: i18n("Plan:")
            enabled: copilotSwitch.checked
            model: copilotDetector.availablePlans()
            currentIndex: plasmoid.configuration.copilotPlan
            onCurrentIndexChanged: {
                var plans = copilotDetector.availablePlans();
                if (currentIndex >= 0 && currentIndex < plans.length) {
                    var def = copilotDetector.defaultLimitForPlan(plans[currentIndex]);
                    if (copilotLimitSpin.value === 0 || !copilotLimitOverride.checked) {
                        copilotLimitSpin.value = def;
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Premium requests (monthly):")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: copilotLimitSpin
                enabled: copilotSwitch.checked
                from: 0
                to: 99999
                value: plasmoid.configuration.copilotCustomLimit
                editable: true

                Component.onCompleted: {
                    if (value === 0) {
                        var plans = copilotDetector.availablePlans();
                        var idx = copilotPlanCombo.currentIndex;
                        if (idx >= 0 && idx < plans.length) {
                            value = copilotDetector.defaultLimitForPlan(plans[idx]);
                        }
                    }
                }
            }

            QQC2.CheckBox {
                id: copilotLimitOverride
                text: i18n("Custom")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        QQC2.Switch {
            id: copilotNotifySwitch
            Kirigami.FormData.label: i18n("Notifications:")
            enabled: copilotSwitch.checked
            checked: plasmoid.configuration.copilotNotifications
        }

        // ── Optional GitHub API integration ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("GitHub API (Optional)")
            visible: copilotSwitch.checked
        }

        QQC2.Label {
            visible: copilotSwitch.checked
            text: i18n("Provide a GitHub Personal Access Token to fetch organization-level "
                     + "Copilot seat metrics. Requires 'manage_billing:copilot' scope.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("GitHub Token:")
            visible: copilotSwitch.checked
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: copilotTokenField
                enabled: copilotSwitch.checked
                echoMode: copilotTokenVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("ghp_...")
                Layout.fillWidth: true
                onTextEdited: subscriptionsPage.copilotTokenDirty = true
            }

            QQC2.ToolButton {
                id: copilotTokenVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide token") : i18n("Show token")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: copilotTokenField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear token"); QQC2.ToolTip.visible: hovered
                onClicked: { copilotTokenField.text = ""; subscriptionsPage.copilotTokenDirty = true; }
            }
        }

        QQC2.TextField {
            id: copilotOrgField
            Kirigami.FormData.label: i18n("Organization:")
            visible: copilotSwitch.checked
            enabled: copilotSwitch.checked
            text: plasmoid.configuration.copilotOrgName
            placeholderText: i18n("my-org-name")
            Layout.fillWidth: true
        }
    }
}
