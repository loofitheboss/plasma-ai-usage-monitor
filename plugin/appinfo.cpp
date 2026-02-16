#include "appinfo.h"

#ifndef AIUSAGE_MONITOR_VERSION
#define AIUSAGE_MONITOR_VERSION "0.0.0"
#endif

AppInfo::AppInfo(QObject *parent)
    : QObject(parent)
{
}

QString AppInfo::version() const
{
    return QStringLiteral(AIUSAGE_MONITOR_VERSION);
}
