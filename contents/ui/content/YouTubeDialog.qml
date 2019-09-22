import QtQuick 2.7
import QtQuick.Layouts 1.3 as QtLayouts
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.activityswitcher 1.0 as ActivitySwitcher
import "./../ajax.js" as Ajax

Rectangle {
    id: container
    signal presetClicked(string id, string type)
    property var  switcherModel: ActivitySwitcher.Backend.runningActivitiesModel()   
    color: theme.backgroundColor


  
    QtLayouts.RowLayout {
    anchors.fill: parent
    
        ListView {
            id: folderView
            focus: true
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            width: 200
            model: folderModel
            boundsBehavior: Flickable.DragAndOvershootBounds         
            delegate:     Component {
                PlasmaComponents.Button {
                    width: 200
                    iconSource: 'document-open-folder'
                    text: title
                    onClicked: { refreshChannelsList(title, false); }
                }
            }
            header: Component {
                PlasmaComponents.Button {
                    id: homeFolderButton
                    iconSource: 'go-home'
                    onClicked: { refreshChannelsList(null, false); }
               }   
            }            
            
            footer: FocusScope {
                width: childrenRect.width; height: childrenRect.height
                x:childrenRect.x; y: childrenRect.y
                Rectangle {
                    id: newFolder
                    color: "grey"
                    radius: 2
                    width: 200
                    height: 30
                    border.color: "black"
                    border.width: 2
                    visible: false
                    TextInput {
                        focus: true
                        id: newFolderInput
                        anchors.centerIn: parent
                        horizontalAlignment: TextInput.AlignHCenter
                        color: "black"
                        width: 150
                        maximumLength: 30
                        cursorVisible: true
                        text: ""
                        Keys.onPressed: {
                            if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                                Ajax.addFolder(newFolderInput.text,switcherModel.activityIdForRow(0))
                                newFolder.visible = false
                                newFolderButton.visible = true
                                newFolderInput.text = ''                                
                                refreshChannelsList(null,true)
                            }
                            
                            if(event.key == Qt.Key_Escape) {
                                newFolder.visible = false
                                newFolderButton.visible = true
                                newFolderInput.text = ''
                            }
                        }
                    }

                }
                PlasmaComponents.Button {
                    id: newFolderButton
                    iconSource: 'folder-new'
                    onClicked: {newFolder.visible = true;  newFolderInput.forceActiveFocus(); newFolderButton.visible = false; }
               }                
                
            }
        }


        ListView {
            id: view
            anchors.top: parent.top
            anchors.topMargin: 10            
            anchors.bottom: parent.bottom
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            width: 200
            model: channelModel
            boundsBehavior: Flickable.DragAndOvershootBounds         
            delegate:     Component {
                PlasmaComponents.Button {
                    width: 200
                    height: 25
                    text: title
                    onClicked: presetClicked(id,type)
                }
            }
            
            header: Component {
                PlasmaCore.IconItem {
                    source: "face-wink"
                    width: !channelModel.count ? parent.width : 0
                    height: width
                    visible: !channelModel.count
                }                
            }             
        }
        
    }



    function refreshChannelsList(folder, initial) {
        var activityId = switcherModel.activityIdForRow(0); //FIXME: dirty hack, but plasmoid.currentActivity doesn`t give ID if plasmoid is docked in panel
        channelModel.clear();
                
        if(initial) {
            folderModel.clear();
        }
        var channels = plasmoid.configuration.channels_list ? JSON.parse(Qt.atob(plasmoid.configuration.channels_list)) : new Object();

        if (!(activityId in channels)) {
            channels[activityId]=[];	  
        }

        for(var i=0, len = channels[activityId].length; i<len; i++) {
            if(!channels[activityId][i]) { continue; }
            if(!channels[activityId][i]["folder"] && ((!channels[activityId][i]["parentFolder"] && !folder) || (channels[activityId][i]["parentFolder"] !== undefined && channels[activityId][i]["parentFolder"] == folder))) {
                channelModel.append({"title": channels[activityId][i]["title"], "id": channels[activityId][i]["id"],"type": channels[activityId][i]["type"], "thumbnail": channels[activityId][i]["thumbnail"] });	    
            }
            if(channels[activityId][i]["folder"] && initial) {
                folderModel.append({"title": channels[activityId][i]["title"] });	    
            }            
        }
    } 
    
    ListModel {
        id: channelModel
    }

    ListModel {
        id: folderModel
    }
    Component.onCompleted: {
      refreshChannelsList(null, true);
    }    
    
}

