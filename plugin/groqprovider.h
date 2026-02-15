#ifndef GROQPROVIDER_H
#define GROQPROVIDER_H

#include "providerbackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * Groq provider backend.
 *
 * Uses OpenAI-compatible API at api.groq.com/openai/v1.
 * - Rate limit headers: x-ratelimit-*
 * - Very fast inference on optimized hardware
 *
 * Models: llama-3.3-70b-versatile, llama-3.1-8b-instant, mixtral-8x7b-32768, gemma2-9b-it
 */
class GroqProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)

public:
    explicit GroqProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("Groq"); }
    QString iconName() const override { return QStringLiteral("globe"); }

    QString model() const;
    void setModel(const QString &model);

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void modelChanged();

private Q_SLOTS:
    void onCompletionReply(QNetworkReply *reply);

private:
    void fetchRateLimits();

    QString m_model = QStringLiteral("llama-3.3-70b-versatile");

    static constexpr const char *BASE_URL = "https://api.groq.com/openai/v1";
};

#endif // GROQPROVIDER_H
