import QtQuick 2.0
import QtQuick.Controls 1.4 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import QtQml.Models 2.1
import "../ajax.js" as Ajax
import org.kde.plasma.activityswitcher 1.0 as ActivitySwitcher
Rectangle {
    id: root
    clip: true
    property alias cfg_channels_list: channels_list.text
    property var  switcherModel: ActivitySwitcher.Backend.runningActivitiesModel()   
    
    width: 300; 


    Component {
        id: dragDelegate
        MouseArea {
            id: dragArea

            property bool held: false

            anchors { left: parent.left; right: parent.right }
            height: content.height

            drag.target: held ? content : undefined
            drag.axis: Drag.YAxis

            onPressAndHold: held = true
            onReleased: {
                held = false;
                cfg_channels_list = Ajax.saveChannelsList(channelModel,folderModel, switcherModel.activityIdForRow(0)).toString();//FIXME: dirty hack, but plasmoid.currentActivity doesn`t give ID if plasmoid is docked in panel
            }
            Rectangle {
                id: content
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                width: dragArea.width; height: column.implicitHeight + 4

                border.width: 1
                border.color: "lightsteelblue"

                color: dragArea.held ? "lightsteelblue" : "white"
                Behavior on color { ColorAnimation { duration: 100 } }

                radius: 2
                Drag.active: dragArea.held
                Drag.source: dragArea
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
                states: State {
                    when: dragArea.held

                    ParentChange { target: content; parent: root }
                    AnchorChanges {
                        target: content
                        anchors { horizontalCenter: undefined; verticalCenter: undefined }
                    }
                }
                Column {
                    id: column
                    height: 88
  
                    anchors { fill: parent; margins: 2 }
                    QtLayouts.RowLayout {
                        width: parent.width   
                        Image { id: imageChoosen; source: thumbnail; anchors.left: parent.left; }
                        Column {
                            anchors.left: imageChoosen.right
                            anchors.leftMargin: 25
                            Text { text: i18n('Name:  ') + title }
                            Text { text: i18n((type==="youtube#channel")?"Type: channel":"Type: playlist") }
                            Text { text: i18n('Videos:  ') + total }
                            QtControls.ComboBox {
                                width: 150
                                activeFocusOnPress: true
                                currentIndex: Ajax.getFolderIndexByName(folderModel, parentFolder) 
                                visible: folderModel.count

                                model: folderModel
                                onCurrentIndexChanged: setFolder(folderModel.get(currentIndex).title, index)
                            }
                        }
                            QtControls.Button {
                                width: 150
                                anchors.right: parent.right
                                anchors.rightMargin: 15
                                text: i18n((type==="youtube#channel")?"Remove channel":"Remove playlist")
                                onClicked: channelModel.removeItem(index)
                            }

                    }
                }
            }
            DropArea {
                anchors { fill: parent; margins: 10 }

                onEntered: {
                    channelModel.move(drag.source.DelegateModel.itemsIndex,dragArea.DelegateModel.itemsIndex,1);
                }
            }
        }
    }
    DelegateModel {
        id: visualModel
        model: channelModel
        delegate: dragDelegate
    }
    
    Component {
     id: folderPanelView
     QtLayouts.RowLayout {
                Rectangle {
                    width: 200
                    height: 25
                    PlasmaCore.IconItem {
                        source: "go-home"
                        width: 25
                        height: width
                        visible: !title.length
                    }                     
                    
                    Text {
                        anchors.left: parent.left
                        text: title 
                    }
                }
                QtControls.Button {
                    anchors.right: deleteFolderButton.left;
                    width: 200
                    height: 25
                    text: 'Show'
                    visible: false
                    onClicked: refreshChannelsList(title,false)
                }                
         
                QtControls.Button {
                    id: deleteFolderButton
                    anchors.right: parent.right;
                    width: 200
                    height: 25
                    text: 'Delete'
                    onClicked: cfg_channels_list = Ajax.deleteFolder(title, channelModel,folderModel,switcherModel.activityIdForRow(0))
                }
     }
    }
    
    ListView {
        id: folderPanel
        anchors.top: parent.top;
        anchors.left: parent.left;
        anchors.leftMargin: 15;
        anchors.right: parent.right;
        model: folderModel
        delegate: folderPanelView
        boundsBehavior: Flickable.DragAndOvershootBounds   
        height: 200
    }
    
    ListView {
        id: view
        anchors { 
            left: parent.left; 
            right: parent.right; 
            top: folderPanel.bottom;
            topMargin: 10;
            leftMargin: 5;
            rightMargin: 5;
            bottomMargin: 2;
            bottom: parent.bottom; 
                
        }
        height: dragArea.height
        model: visualModel
        spacing: 4
        cacheBuffer: 50
    }
    ListModel {
        id: folderModel
    }
    
 	ListModel {
	  id: channelModel
	  function removeItem(index) {
        channelModel.remove(index);
        cfg_channels_list = Ajax.saveChannelsList(channelModel,folderModel,switcherModel.activityIdForRow(0));//FIXME: dirty hack, but plasmoid.currentActivity doesn`t give ID if plasmoid is docked in panel
	  }
	}   
    
    Column {
      visible: false
      QtLayouts.RowLayout {
        QtControls.Label {
            text: i18n("channels_list:")
        }
        QtControls.TextField {
            id: channels_list
            }
        } 
      }
    
        
    function refreshChannelsList(folder, initial) {
        var activityId = switcherModel.activityIdForRow(0); //FIXME: dirty hack, but plasmoid.currentActivity doesn`t give ID if plasmoid is docked in panel
        channelModel.clear();
                
        if(initial) {
            folderModel.clear();
            folderModel.append({"title":"" });
        }
        var channels = plasmoid.configuration.channels_list ? JSON.parse(Qt.atob(plasmoid.configuration.channels_list)) : new Object();

        if (!(activityId in channels)) {
            channels[activityId]=[];	  
        }

        for(var i=0, len = channels[activityId].length; i<len; i++) {
            if(!channels[activityId][i]) { continue; }
            if(!channels[activityId][i]["folder"] )
//                && ((!channels[activityId][i]["parentFolder"] && !folder) || (channels[activityId][i]["parentFolder"] !== undefined && channels[activityId][i]["parentFolder"] == folder)))
             {
                channelModel.append({"title": channels[activityId][i]["title"], "id": channels[activityId][i]["id"],"type": channels[activityId][i]["type"], "thumbnail": channels[activityId][i]["thumbnail"], "total": channels[activityId][i]["total"], "parentFolder": channels[activityId][i]["parentFolder"] });	    
            }
            if(channels[activityId][i]["folder"] && initial) {
                folderModel.append({"title": channels[activityId][i]["title"] });	    
            }            
        }
    }    
    
    function setFolder(title,id) {
       if ((!channelModel.get(id).parentFolder && !title) || (channelModel.get(id).parentFolder !== undefined && channelModel.get(id).parentFolder == title))
       {
       }else {
        channelModel.setProperty(id, "parentFolder", title)
        cfg_channels_list = Ajax.saveChannelsList(channelModel,folderModel,switcherModel.activityIdForRow(0));
//        channelModel.remove(id);
        }
    }
    


    Component.onCompleted: {
      refreshChannelsList(null, true);
    }        
}
