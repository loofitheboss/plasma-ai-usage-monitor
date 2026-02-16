#ifndef APPINFO_H
#define APPINFO_H

#include <QObject>
#include <QString>

class AppInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit AppInfo(QObject *parent = nullptr);

    QString version() const;
};

#endif // APPINFO_H
