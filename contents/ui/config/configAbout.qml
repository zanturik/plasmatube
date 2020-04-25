import QtQuick 2.0
import QtQuick.Controls 1.2 as QtControls
import QtQuick.Layouts 1.0 as QtLayouts
import org.kde.plasma.plasmoid 2.0

Item {
    id: settingsPage

    
        QtLayouts.ColumnLayout {

          Column {  
            QtLayouts.RowLayout {
                QtControls.Label {
                    text: i18n("Version: 3.0.4")
                }
            }
          }
        }
}
