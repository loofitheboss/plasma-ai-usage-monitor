#ifndef DEEPSEEKPROVIDER_H
#define DEEPSEEKPROVIDER_H

#include "providerbackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * DeepSeek provider backend.
 *
 * Uses OpenAI-compatible API at api.deepseek.com/v1.
 * - Rate limit info from response headers (x-ratelimit-*)
 * - Usage data from chat completion response body
 * - Balance/cost from GET /user/balance endpoint
 *
 * Models: deepseek-chat, deepseek-reasoner
 */
class DeepSeekProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)

public:
    explicit DeepSeekProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("DeepSeek"); }
    QString iconName() const override { return QStringLiteral("globe"); }

    QString model() const;
    void setModel(const QString &model);

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void modelChanged();

private Q_SLOTS:
    void onCompletionReply(QNetworkReply *reply);
    void onBalanceReply(QNetworkReply *reply);

private:
    void fetchRateLimits();
    void fetchBalance();
    void checkAllDone();

    QString m_model = QStringLiteral("deepseek-chat");
    int m_pendingRequests = 0;

    static constexpr const char *BASE_URL = "https://api.deepseek.com";
};

#endif // DEEPSEEKPROVIDER_H
