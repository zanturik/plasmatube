import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18n("Settings")
         icon: "preferences-desktop-settings"
         source: "config/configSettings.qml"
    }
  
    ConfigCategory {
         name: i18n("Youtube channels")
         icon: "preferences-web-browser-shortcuts"
         source: "config/configChannels.qml"
    }  
    
}
