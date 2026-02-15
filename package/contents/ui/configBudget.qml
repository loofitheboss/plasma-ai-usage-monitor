import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: budgetPage

    // Config stores cents (Int). SpinBox value is also cents. Direct alias works.
    property alias cfg_openaiDailyBudget: openaiDailyField.value
    property alias cfg_openaiMonthlyBudget: openaiMonthlyField.value
    property alias cfg_anthropicDailyBudget: anthropicDailyField.value
    property alias cfg_anthropicMonthlyBudget: anthropicMonthlyField.value
    property alias cfg_googleDailyBudget: googleDailyField.value
    property alias cfg_googleMonthlyBudget: googleMonthlyField.value
    property alias cfg_mistralDailyBudget: mistralDailyField.value
    property alias cfg_mistralMonthlyBudget: mistralMonthlyField.value
    property alias cfg_deepseekDailyBudget: deepseekDailyField.value
    property alias cfg_deepseekMonthlyBudget: deepseekMonthlyField.value
    property alias cfg_groqDailyBudget: groqDailyField.value
    property alias cfg_groqMonthlyBudget: groqMonthlyField.value
    property alias cfg_xaiDailyBudget: xaiDailyField.value
    property alias cfg_xaiMonthlyBudget: xaiMonthlyField.value
    property alias cfg_budgetWarningPercent: warningPercentSlider.value

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.Label {
            text: i18n("Set daily and monthly budget limits per provider. Set to $0.00 to disable budget tracking for that provider.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Warning Threshold")
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Warn at:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: warningPercentSlider
                Layout.fillWidth: true
                from: 50
                to: 100
                stepSize: 5
                value: plasmoid.configuration.budgetWarningPercent
            }

            QQC2.Label {
                text: i18n("%1% of budget", warningPercentSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── OpenAI ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("OpenAI")
        }

        QQC2.SpinBox {
            id: openaiDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: openaiMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        // ── Anthropic ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Anthropic")
        }

        QQC2.SpinBox {
            id: anthropicDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: anthropicMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        // ── Google ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Google Gemini")
        }

        QQC2.SpinBox {
            id: googleDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: googleMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        // ── Mistral ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mistral AI")
        }

        QQC2.SpinBox {
            id: mistralDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: mistralMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        // ── DeepSeek ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("DeepSeek")
        }

        QQC2.SpinBox {
            id: deepseekDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: deepseekMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        // ── Groq ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Groq")
        }

        QQC2.SpinBox {
            id: groqDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: groqMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        // ── xAI ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("xAI / Grok")
        }

        QQC2.SpinBox {
            id: xaiDailyField
            Kirigami.FormData.label: i18n("Daily budget ($):")
            from: 0; to: 100000; stepSize: 100

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }

        QQC2.SpinBox {
            id: xaiMonthlyField
            Kirigami.FormData.label: i18n("Monthly budget ($):")
            from: 0; to: 1000000; stepSize: 500

            textFromValue: function(value, locale) {
                return "$" + (value / 100).toFixed(2);
            }
            valueFromText: function(text, locale) {
                return Math.round(parseFloat(text.replace("$", "")) * 100);
            }
        }
    }
}
