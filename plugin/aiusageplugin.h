#ifndef AIUSAGEPLUGIN_H
#define AIUSAGEPLUGIN_H

#include <QQmlExtensionPlugin>

/**
 * QML plugin that registers all C++ types for the AI Usage Monitor plasmoid.
 */
class AiUsagePlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override;
};

#endif // AIUSAGEPLUGIN_H
