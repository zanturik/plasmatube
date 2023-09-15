import QtQuick 2.15
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls 2.15 as QtControls
import "ajax.js" as Ajax

Rectangle {
    id: container
    signal presetClicked(string videoId, string type, string title)
    color: theme.backgroundColor


    QtObject {
        id: currentFolder
        property string title: ''
    }

    DB {
        id: database
    }

    QtLayouts.RowLayout {
    anchors.fill: parent
    
        ListView {
            id: folderView
            focus: true
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            QtLayouts.Layout.fillHeight: true
            QtLayouts.Layout.topMargin: 10;
            width: 200
            model: folderModel
            boundsBehavior: Flickable.DragAndOvershootBounds         
            delegate:     Component {
                QtControls.Button {
                    width: 200
                    icon.name: 'document-open-folder'
                    text: title
                    onClicked: { refreshChannelsList(id, title); }
                }
            }
            header: Component {
                QtControls.Button {
                    id: homeFolderButton
                    icon.name: 'home'
                    onClicked: { refreshChannelsList(null, null); }
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
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                database.addFolder(newFolderInput.text)
                                refreshFolders();
                                newFolder.visible = false
                                newFolderButton.visible = true
                                newFolderInput.text = ''                                
                                refreshChannelsList(null, null)
                            }
                            
                            if(event.key === Qt.Key_Escape) {
                                newFolder.visible = false
                                newFolderButton.visible = true
                                newFolderInput.text = ''
                            }
                        }
                    }

                }
                QtControls.Button {
                    id: newFolderButton
                    icon.name: 'folder-new'
                    onClicked: {newFolder.visible = true;  newFolderInput.forceActiveFocus(); newFolderButton.visible = false; }
               }                
                
            }
        }


        ListView {
            id: view
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            QtLayouts.Layout.fillHeight: true
            QtLayouts.Layout.topMargin: 10
            width: 200
            model: channelModel
            boundsBehavior: Flickable.DragAndOvershootBounds         
            delegate:     Component {
                QtControls.Button {
                    width: 200
                    height: 25
                    text: title
                    onClicked: presetClicked(videoId,type, title)
                }
            }
            header: Component {
                QtControls.Label {
                    text: currentFolder.title              
                }              
            }             
        }
        
    }


    function refreshFolders() {
        folderModel.clear();
        var folders = database.getFolders();
        for (var i = 0; i < folders.rows.length; i++) {
            folderModel.append({"title": folders.rows.item(i).name, "id": folders.rows.item(i).id });
        }
    }


    function refreshChannelsList(folderId, folderTitle) {
        channelModel.clear();
        currentFolder.title = folderTitle;
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
                "videoId": videos.rows.item(i).videoid
                 });
        }
    }
    
    ListModel {
        id: channelModel
    }

    ListModel {
        id: folderModel
    }
    Component.onCompleted: {
      refreshFolders();
      refreshChannelsList(null, null);
    }    
    
}

