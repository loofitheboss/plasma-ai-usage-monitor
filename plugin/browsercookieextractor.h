#ifndef BROWSERCOOKIEEXTRACTOR_H
#define BROWSERCOOKIEEXTRACTOR_H

#include <QObject>
#include <QString>
#include <QMap>
#include <QDateTime>

/**
 * Utility class to extract session cookies from the user's web browser.
 *
 * This is used by the experimental browser-sync feature to authenticate
 * with internal APIs of Claude.ai, ChatGPT, and GitHub.
 *
 * Supported browsers:
 * - Firefox: reads cookies from ~/.mozilla/firefox/<profile>/cookies.sqlite
 *   (plain SQLite, no encryption)
 * - Chrome/Chromium: cookies.sqlite in profile dir, but values are AES-encrypted.
 *   Chrome cookie decryption requires the Safe Storage key from the system keyring
 *   which is complex and platform-specific. For now, only Firefox is fully supported.
 *
 * WARNING: This feature uses internal/undocumented APIs of third-party services.
 * It may violate Terms of Service and can break without notice. Users must
 * opt-in and acknowledge the experimental nature.
 */
class BrowserCookieExtractor : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int browserType READ browserType WRITE setBrowserType NOTIFY browserTypeChanged)
    Q_PROPERTY(bool hasFirefoxProfile READ hasFirefoxProfile NOTIFY profilesChanged)

public:
    enum BrowserType {
        Firefox = 0,
        Chrome = 1,
        Chromium = 2
    };
    Q_ENUM(BrowserType)

    explicit BrowserCookieExtractor(QObject *parent = nullptr);

    int browserType() const;
    void setBrowserType(int type);
    bool hasFirefoxProfile() const;

    /**
     * Get the path to the active browser's cookie database.
     * For Firefox, returns the cookies.sqlite path of the default profile.
     */
    Q_INVOKABLE QString cookieDbPath() const;

    /**
     * Extract a specific cookie value from the browser's cookie store.
     * @param domain Cookie domain (e.g., ".claude.ai", ".chatgpt.com")
     * @param name Cookie name (e.g., "sessionKey", "__Secure-next-auth.session-token")
     * @return Cookie value, or empty string if not found or expired
     */
    Q_INVOKABLE QString getCookie(const QString &domain, const QString &name) const;

    /**
     * Check if valid (non-expired) cookies exist for a given domain.
     */
    Q_INVOKABLE bool hasCookiesFor(const QString &domain) const;

    /**
     * Get all cookies for a domain as a formatted cookie header string.
     * e.g., "name1=value1; name2=value2"
     */
    Q_INVOKABLE QString getCookieHeader(const QString &domain) const;

    /**
     * Test connection to a service by checking if we have valid session cookies.
     * @param service One of "claude", "codex", "github"
     * @return Status string: "connected", "expired", "not_found"
     */
    Q_INVOKABLE QString testConnection(const QString &service) const;

    /**
     * Detect available Firefox profiles.
     */
    Q_INVOKABLE QStringList firefoxProfiles() const;

Q_SIGNALS:
    void browserTypeChanged();
    void profilesChanged();

private:
    QString firefoxProfilePath() const;
    QString chromeProfilePath() const;
    QString chromiumProfilePath() const;

    // Read cookies from Firefox SQLite database (unencrypted)
    QMap<QString, QString> readFirefoxCookies(const QString &domain) const;

    int m_browserType = Firefox;
};

#endif // BROWSERCOOKIEEXTRACTOR_H
