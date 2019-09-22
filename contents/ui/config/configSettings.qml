import QtQuick 2.0
import QtQuick.Controls 1.2 as QtControls
import QtQuick.Layouts 1.0 as QtLayouts

Item {
    id: settingsPage

    property alias cfg_autoplay: autoplay.checked    
    property alias cfg_pinned:  pinned.checked
    property alias cfg_playNext:  playNext.checked    
    property alias cfg_baseUrl: baseUrl.text   
    property alias cfg_windowSize: windowSize.value
    property alias cfg_numberOfVideos: numberOfVideos.value    
    
        QtLayouts.ColumnLayout {

          Column {  
            QtLayouts.RowLayout {
                QtControls.CheckBox {
                    id: autoplay
                    text: i18n("Autoplay on click")
                }
	    }

	}
	
          Column {  
            QtLayouts.RowLayout {
                QtControls.CheckBox {
                    id: pinned
                    text: i18n("Pinned by default")
                }
	    }

	}	
	
          Column {  
            QtLayouts.RowLayout {
                QtControls.CheckBox {
                    id: playNext
                    text: i18n("Play next video non-stop")
                }
	    }

	}		
	
             Column {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("Default window size (usefull for docked in a panel plasmoid. Works after relogin, sorry):")
                }
	     }
             Column {
                QtControls.Slider {
                    id: windowSize
                    maximumValue: 5
                    minimumValue: 1
                    stepSize: 1
                    tickmarksEnabled: true
                    updateValueWhileDragging: false
                }
            }
            
             Column {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("Number of loaded videos")
                }
	     }
             Column {
                QtControls.Slider {
                    id: numberOfVideos
                    maximumValue: 10
                    minimumValue: 1
                    stepSize: 1
                    tickmarksEnabled: true
                    updateValueWhileDragging: false
                }
            }	            


	}	
	
	Column {
            visible: false
            QtLayouts.RowLayout {
                QtControls.TextField {
                    id: baseUrl
                }
            }
		}

}
