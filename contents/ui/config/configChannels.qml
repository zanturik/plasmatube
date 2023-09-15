import QtQuick 2.0
import QtQuick.Controls 1.4 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import QtQml.Models 2.1
import "../ajax.js" as Ajax
import "../" // workaround to have DB

Rectangle {
    id: root
    clip: true
    property alias cfg_channels_list: channels_list.text
    color: theme.backgroundColor
    width: 300; 

    DB {
        id: database
    }

    Component {
        id: dragDelegate
        MouseArea {
            id: dragArea

            property bool held: false

            anchors { left: parent ? parent.left: undefined ; right: parent ? parent.right : undefined }
            height: content.height

            drag.target: held ? content : undefined
            drag.axis: Drag.YAxis

            onPressAndHold: held = true
            onReleased: {
                held = false;
                saveChannelsList();
            }
            Rectangle {
                id: content
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                width: dragArea.width; height: column.implicitHeight + 4

                border.width: 1
                border.color: Qt.darker(theme.backgroundColor, 1.25)

                color: dragArea.held ? Qt.darker(theme.backgroundColor, 1.25) : theme.backgroundColor
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
                        Image { id: imageChoosen; source: thumbnail; QtLayouts.Layout.alignment: Qt.AlignLeft; }
                        Column {
                            QtLayouts.Layout.alignment: Qt.AlignLeft;
                            QtLayouts.Layout.leftMargin: 25
                            QtLayouts.Layout.fillWidth: true
                            Text { 
                                text: i18n('Name:  ') + title 
                                color: theme.textColor
                            }
                            Text { 
                                text: i18n((type==="youtube#channel")?"Type: channel":"Type: playlist") 
                                color: theme.textColor
                                
                            }
                            Text { 
                                text: i18n('Videos:  ') + totalcount
                                color: theme.textColor
                                
                            }
                            QtControls.ComboBox {
                                width: 150
                                activeFocusOnPress: true
                                currentIndex: Ajax.getFolderIndexByName(folderModel, folder)
                                visible: folderModel.count

                                model: folderModel
                                onCurrentIndexChanged: setFolder(folderModel.get(currentIndex).id, id)
                            }
                        }
                        QtControls.Button {
                                width: 150
                                QtLayouts.Layout.alignment: Qt.AlignRight;
                                QtLayouts.Layout.rightMargin: 15
                                text: i18n("Remove")
                                onClicked: removeVideo(id, folderId);
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
                    color: theme.backgroundColor
                    PlasmaCore.IconItem {
                        source: "go-home"
                        width: 25
                        height: width
                        visible: !title.length
                    }                     
                    
                    Text {
                        anchors.left: parent.left
                        color: theme.textColor
                        text: title
                    }
                }
                QtControls.Button {
                    QtLayouts.Layout.alignment: Qt.AlignRight
                    width: 200
                    height: 25
                    text: 'Show'
                    visible: true
                    onClicked: refreshChannelsList(id)
                }                
         
                QtControls.Button {
                    id: deleteFolderButton
                    QtLayouts.Layout.alignment: Qt.AlignRight
                    width: 200
                    height: 25
                    text: 'Delete'
                    onClicked: { database.deleteFolderByName(title); refreshFolders(); refreshChannelsList(null); }
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
        model: visualModel
        spacing: 4
        cacheBuffer: 50
    }
    ListModel {
        id: folderModel
    }
    
 	ListModel {
	  id: channelModel
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
    


    function refreshFolders() {
        folderModel.clear();
        folderModel.append({"text":"","title": "","id": null });
        var folders = database.getFolders();
        for (var i = 0; i < folders.rows.length; i++) {
            folderModel.append({"text": folders.rows.item(i).name, "title": folders.rows.item(i).name, "id": folders.rows.item(i).id});
        }
    }


    function refreshChannelsList(folderId) {
        channelModel.clear();
        var folderName = database.getFolderName(folderId)
        var videos = database.getVideos(folderId);
        for (var i = 0; i < videos.rows.length; i++) {
            channelModel.append({
                "title": videos.rows.item(i).title,
                "type": videos.rows.item(i).type,
                "thumbnail": videos.rows.item(i).thumbnail,
                "totalcount": videos.rows.item(i).totalcount,
                "lastupdated": videos.rows.item(i).lastupdated,
                "rating": videos.rows.item(i).rating,
                "id": videos.rows.item(i).id,
                "videoId": videos.rows.item(i).videoid,
                "folder": String(folderName),
                "folderId": (folderId === null) ? 0 : folderId
                 });
        }
    }


    function setFolder(folderId, videoId) {
        database.setFolder(folderId,videoId);
    }
    
    function removeVideo(videoId, folderId) {
        database.deleteVideo(videoId);
        refreshChannelsList(folderId);
    }

    function saveChannelsList() {
        for (var i = 0, len = channelModel.count; i < len; i++) {
            database.setSortVideo(channelModel.get(i).id, i);
		}
    }

    Component.onCompleted: {
      refreshFolders();
      refreshChannelsList(null);
    }        
}
