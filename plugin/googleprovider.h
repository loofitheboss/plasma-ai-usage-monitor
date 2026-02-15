#ifndef GOOGLEPROVIDER_H
#define GOOGLEPROVIDER_H

#include "providerbackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * Google Gemini provider backend.
 *
 * Google does NOT have a dedicated usage/billing API for the Gemini API.
 * This provider makes a lightweight countTokens call to verify connectivity
 * and extract any available metadata.
 *
 * Rate limits for the Gemini API are not exposed via response headers,
 * so we display known free-tier/paid-tier limits from documentation.
 *
 * Endpoint: POST /v1beta/models/{model}:countTokens
 */
class GoogleProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)

public:
    explicit GoogleProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("Google Gemini"); }
    QString iconName() const override { return QStringLiteral("globe"); }

    QString model() const;
    void setModel(const QString &model);

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void modelChanged();

private Q_SLOTS:
    void onCountTokensReply(QNetworkReply *reply);

private:
    void fetchStatus();
    void applyKnownLimits();

    QString m_model = QStringLiteral("gemini-2.0-flash");

    static constexpr const char *BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
};

#endif // GOOGLEPROVIDER_H
