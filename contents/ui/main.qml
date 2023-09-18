
import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQml 2.15
import QtWebEngine 1.5
import QtQuick.Controls 2.15 as QtControls
import org.kde.plasma.plasmoid 2.0
import "ajax.js" as Ajax
import org.kde.draganddrop 2.0 as DragDrop
Item {
    id: container
    property string hoveredTitle
    Layout.preferredWidth: units.gridUnit * 16 * plasmoid.configuration.windowSize
    Layout.preferredHeight: units.gridUnit * 9 * plasmoid.configuration.windowSize
    clip: true;


    property QtObject videoStatus: QtObject {
        property int initial: -1
        property int ready: 0
        property int playing: 1
        property int paused: 2
        property int ended: 3
    }

    DB {
        id: database
    }

    QtObject {
        id: currentVideo
        property string vId: ''
        property string title: ''
        property int status: videoStatus.initial
    }

    readonly property int padding: 20

    Rectangle {
        id: content
        anchors.fill: parent
        color: "black"

        WebEngineView {
            id: webView
            anchors.fill: parent
            opacity: 0
            url: "content/player.html"
            Behavior on opacity { NumberAnimation { duration: 200 } }

            onLoadingChanged: {
                switch (loadRequest.status)
                {
                case WebEngineView.LoadSucceededStatus:
                    opacity = 1
                    return
                case WebEngineView.LoadStartedStatus:
                case WebEngineView.LoadStoppedStatus:
                    break
                case WebEngineView.LoadFailedStatus:
                    topInfo.text = "Failed to load the requested video"
                    break
                }
                opacity = 0
            }
            onTitleChanged: {
                currentVideo.status = 1 * title
                if (currentVideo.status === videoStatus.paused || currentVideo.status === videoStatus.ready) {
                    panel.state = "list"
                } else if (currentVideo.status === videoStatus.playing) {
                    panel.state = "hidden"
                } else if (currentVideo.status === videoStatus.ended ) {
                    if(plasmoid.configuration.playNext) {
                        panel.state = "hidden"
                        videoModel.playNextVideo();
                    } else {
                        panel.state = "list";
                    }
                    
                }
            }

            onNewViewRequested: function(request) {
                var videoId = dropArea.getYoutubeId(request.requestedUrl.toString());
                if(videoId) {
                videoModel.addVideo(videoId);
                }
            }
        }

        YouTubeDialog {
            id: presetDialog
            anchors.fill: parent
            anchors.topMargin: 125
            visible: false
            onPresetClicked: {
                videoModel.startIndex = 1
                panel.state = "list"
                searchBinding.when = false
		        switch(type) {
                    case "youtube#playlist":
                        videoModel.playlistId = videoId
                        presetsBinding.when = false   
                        playlistBinding.when = true
                        videoModel.reload(true)
                        break;
                    case "youtube#channel":
                        videoModel.userName = videoId
                        playlistBinding.when = false
                        presetsBinding.when = true
                        videoModel.reload(true)
                        break;
                    case "youtube#video":
                        currentVideo.vId = videoId
                        currentVideo.title = title
                        videoModel.playVideo(videoId);
                        break;
                    }

            }
        }
    }

    Rectangle {
        id: panel
        height: 100
        color: "black";
        state: "list"

        Behavior on y { NumberAnimation { duration: 200 } }
        Behavior on height { NumberAnimation { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Binding { id: presetsBinding; target: videoModel; property: "source"; value: videoModel.usersSource; when: true; restoreMode: Binding.RestoreBinding }
        Binding { id: searchBinding; target: videoModel; property: "source"; value: videoModel.searchSource; when: false; restoreMode: Binding.RestoreBinding }
        Binding { id: playlistBinding; target: videoModel; property: "source"; value: videoModel.playlistSource; when: false; restoreMode: Binding.RestoreBinding }        

        anchors {
            left: container.left
            right: container.right
        }

        states: [
            State {
                name: "search"
                PropertyChanges { target: panel; color: "black"; opacity: 0.8; y: -height + topInfo.height + searchPanel.height + button.height }
                PropertyChanges { target: listView; visible: false }
                PropertyChanges { target: searchPanel; opacity: 0.8; visible: true }
                PropertyChanges { target: hideTimer; running: false }
                PropertyChanges { target: presetDialog; visible: true }
                PropertyChanges { target: webView; visible: false }
            },

            State {
                name: "list"
                PropertyChanges { target: panel; color: "black"; opacity: 0.8; y: 0 }
                PropertyChanges { target: listView; visible: true; focus: true }
                PropertyChanges { target: searchPanel; visible: false }
                PropertyChanges { target: presetDialog; visible: false }
                PropertyChanges { target: webView; visible: true }                
            },

            State {
                name: "hidden"
                PropertyChanges { target: panel; color: "gray"; opacity: 0.2; y: -height }
                PropertyChanges { target: webView; visible: true }                
            }
        ]

        Timer {
            id: hideTimer
            interval: 3000
            repeat: false
            onTriggered: panel.state = "hidden"
        }

        ListView {
            id: listView
            orientation: "Horizontal"

            anchors {
                top: panel.top
                bottom: button.top
                left: panel.left
                right: panel.right
            }

            focus: true
            model: videoModel

            header: Component {
                Rectangle {
                    visible: videoModel.startIndex != 1 && videoModel.count
                    color: "black"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: visible ? listView.contentItem.height : 0
                    Image { anchors.centerIn: parent; width: 22; height: 50; source: "icons/left-arrow.png" }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: videoModel.requestLess()
                    }
                }
            }

            footer: Component {
                Rectangle {
                    visible: videoModel.totalResults > videoModel.endIndex && videoModel.count
                    color: "black"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: visible ? listView.contentItem.height : 0
                    Image { anchors.centerIn: parent; width: 22; height: 50; source: "icons/right-arrow.png" }
                    MouseArea {
                        anchors.fill: parent

                        onClicked: videoModel.requestMore();
                    }
                }
            }

            delegate: Component {
                Image {
                    id: image
                    source: thumbnail
                    
                    states: [
                        State {
                            name: "image"
                            PropertyChanges { target: infoBackground; visible: (type === "youtube#channel" || type === "youtube#playlist")?true:false }
                            PropertyChanges { target: infoLabel; visible: (type === "youtube#channel" || type === "youtube#playlist")?true:false }                                
                            PropertyChanges { target: removeButton; visible: false }                  
                            PropertyChanges { target: addPresetButton; visible: false }                  
                        },
                        State {
                            name: "properties"
                            PropertyChanges { target: infoBackground; visible: false }
                            PropertyChanges { target: infoLabel; 	  visible: false }                
                            PropertyChanges { target: removeButton; visible: true }                       
                            PropertyChanges { target: addPresetButton; visible: true }
                        }]     
                    Timer {
                        id: hidePictureTimer
                        interval: 1500
                        repeat: false
                        onTriggered: image.state = "image"
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton      
                        hoverEnabled: true
                        onEntered: mouseEnteredProcess()
                        onExited: mouseExitedProcess()
                        onClicked: {
                            if (mouse.button == Qt.LeftButton) {
                            switch(type) {
                                case "youtube#video":
                                    currentVideo.vId = id
                                    currentVideo.title = title
                                    videoModel.playVideo(id);
                                break
                                case "youtube#playlist":
                                    videoModel.playlistId = id
                                    videoModel.startIndex = 1
                                    panel.state = "list"
                                    searchBinding.when = false
                                    presetsBinding.when = false
                                    playlistBinding.when = true
                                    videoModel.reload(true)
                                break
                                case "youtube#channel":
                                    videoModel.userName = id
                                    videoModel.startIndex = 1
                                    panel.state = "list"
                                    searchBinding.when = false
                                    playlistBinding.when = false
                                    presetsBinding.when = true			    
                                    videoModel.reload(true)
                                break				    
                            }
                            }
                            else
                            {
                                image.state = "properties";
                            }
                        }

                        function mouseEnteredProcess() {
                            container.hoveredTitle = (type === "youtube#channel" || type === "youtube#playlist")? title + ' (' + Ajax.countChannelVideos(id,type) + i18n(' video)'): title
                        }
                        function mouseExitedProcess() {
                            container.hoveredTitle = ''
                            if(image.state == "properties") {
                                hidePictureTimer.start();
                            }
                        }
                    }
                    QtControls.Button {
                        id: addPresetButton
                        visible: false
                        height: 25
                        anchors.bottomMargin: 15
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        anchors.bottom: parent.bottom
                        width: parent.width
                        opacity: 1
                        text: i18n('Add to preset')
                        onClicked: database.addVideo(videoModel.get(index),null)
                        }	
            
                    QtControls.Button {
                        id: removeButton
                        visible: false
                        height: 20
                        anchors.topMargin: 10
                        anchors.rightMargin: 5
                        anchors.leftMargin: 5
                        anchors.top: parent.top
                        width: parent.width;
                        opacity: 1                
                        text: i18n('Remove')
                        onClicked: videoModel.remove(index)
                    }
                    Rectangle {
                        id: infoBackground
                        visible: (type === "youtube#channel" || type === "youtube#playlist") 
                        height: 20
                        width: parent.width
                        color: "black";		      
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.7
                    }
                    QtControls.Label {
                        id: infoLabel
                        visible: (type === "youtube#channel" || type === "youtube#playlist") 		      
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "white"
                        font.bold: true
                        text: i18n((type === "youtube#channel")?"Channel":"Playlist")
                    }
                    Component.onCompleted: {
                        if (currentVideo.title == "") {
                            currentVideo.vId = id
                            currentVideo.title = title
                        }
                    }
                
                }
            }
            onDraggingChanged: {
                if (dragging)
                    hideTimer.stop()
                else if (currentVideo.status === videoStatus.playing)
                    hideTimer.start()
            }
            
            QtControls.Button {
                id: removeButton
                visible: panel.visible && videoModel.count
                height: 25
                anchors.topMargin: 10
                anchors.rightMargin: 2
                anchors.top: parent.top
                anchors.right: parent.right
                width: height;
			    opacity: 1                
                icon.name: 'edit-delete'
                onClicked: videoModel.clear()
            }            

        }
        
        Rectangle {
            id: searchPanel
            Behavior on opacity { NumberAnimation { duration: 300 } }

            height: searchField.height + container.padding

            anchors {
                left: parent.left
                right: parent.right
                bottom: button.top
            }

            opacity: 0
            color: "black"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "grey"
                }
                GradientStop {
                    position: 1.0
                    color: "black"
                }
            }

            Rectangle {
                id: searchField
                color: "white"
                radius: 2
                anchors.centerIn: parent
                width: 220
                border.color: "black"
                border.width: 2
                height: input.height + container.padding
                TextInput {
                    id: input
                    color: "black"
                    anchors.centerIn: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    font.capitalization: Font.AllLowercase
                    maximumLength: 30
                    cursorVisible: true
                    text: ""
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            videoModel.startIndex = 1
                            panel.state = "list"
                            presetsBinding.when = false
                            playlistBinding.when = false
                            searchBinding.when = true	                            
                            videoModel.reload(true)
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: input.focus = true
                }
            }
            

            QtControls.Button {
                id: searchButton
                anchors.left: searchField.right
                anchors.verticalCenter: parent.verticalCenter
			    anchors.leftMargin: 15                
                text: i18n('Search')
                height: searchField.height
                onClicked:  { 
                            videoModel.startIndex = 1;
                            panel.state = "list";
                            presetsBinding.when = false;
                            playlistBinding.when = false;
                            searchBinding.when = true;                           
                            videoModel.reload(true);
                }
            }            
            
        }

        QtControls.Button {
            id: button
            height: 25
            width: container.width
            visible: panel.state != "hidden"

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            states: [
                State {
                    name: "search"
                    PropertyChanges { target: button; text: "Press to switch back to the video list" }
                },

                State {
                    name: "list"
                    PropertyChanges { target: button; text: "Press to search for videos" }
                }
            ]

            state: panel.state

            onClicked: {
                if (panel.state == "search") {
                    panel.state = "list"
                } else {
                    panel.state = "search"
                }
            }
        }
        
    }

    Rectangle {
        height: 10
        color: "black"
        opacity: (panel.state == "hidden") ? 0 : 0.8

        Behavior on opacity { NumberAnimation { duration: 200 } }

        anchors {
            top: container.top
            left: container.left
            right: container.right
        }

        Text {
            id: topInfo
            color: "white"
            font.pointSize: 8
            anchors.centerIn: parent
            Binding on text {
                value: "Results " + videoModel.startIndex + " through " + ((videoModel.endIndex > videoModel.totalResults) ? videoModel.totalResults : videoModel.endIndex) + " out of " + videoModel.totalResults
                when: panel.state == "list" && videoModel.count && !container.hoveredTitle.length
                restoreMode: Binding.RestoreBinding
            }
            Binding on text {
                value: "No results found.";
                when: !videoModel.count && !container.hoveredTitle.length
                restoreMode: Binding.RestoreBinding                
            }
            Binding on text {
                value: "Search for videos"
                when: panel.state == "search" && !container.hoveredTitle.length
                restoreMode: Binding.RestoreBinding
            }
            
            Binding on text {
                value: container.hoveredTitle
                when: container.hoveredTitle.length
                restoreMode: Binding.RestoreBinding                
            }
        }
    }

    Rectangle {
        height: container.padding
        color: "black"
        opacity: (panel.state == "hidden") ? 0.2 : 0.8

        Behavior on opacity { NumberAnimation { duration: 200 } }

        anchors {
            top: panel.bottom
            left: container.left
            right: container.right
        }

        Text {
            id: bottomInfo
            color: "white"
            font.weight: Font.DemiBold
            font.pointSize: 8
            anchors.centerIn: parent
            text: {
                if (panel.state == "search")
                    return "Choose from preset video streams"
                else
                    return currentVideo.title
            }
        }

        MouseArea {
            // Responsible for showing and hiding the thumbnail list.
            anchors.fill: parent
            onPressed: {
                if (panel.state != "list") {
                    panel.state = "list"
                    if (currentVideo.status === videoStatus.playing)
                        hideTimer.restart()
                } else
                    panel.state = "hidden"
            }
        }
        
    }

    QtControls.ToolButton {
            id: pinButton
            padding: units.smallSpacing                 
            width: Math.round(units.gridUnit)
            height: width
            visible: panel.state != "hidden" 
            icon.name: "window-pin"     
            checkable: true
            checked: !plasmoid.hideOnWindowDeactivate            

            anchors {
                bottom: parent.bottom
                right: parent.right
            }

            onClicked: {
                plasmoid.hideOnWindowDeactivate = !plasmoid.hideOnWindowDeactivate;
            }
    } 

    Rectangle { 
            height: container.height - panel.height;
            anchors {
                bottom: container.bottom
                left: container.left
                right: container.right
            }
            opacity: 0
            color: "Black"

    DragDrop.DropArea {
            id: dropArea

            anchors.fill: parent

            onDrop: {
                var mimeData = event.mimeData
                if (mimeData.hasUrls) {
 
                    for (var i = 0, j = mimeData.urls.length; i < j; ++i) {
                        var id = getYoutubeId(mimeData.urls[i]);
                        if(id) {
                            videoModel.addVideo(id);
                        } 
                    }

                   event.accept(Qt.CopyAction);
                }
                parent.opacity = 0;                
            }
            onDragEnter: { 
                container.forceActiveFocus();
                parent.opacity = 0.75;
            }
            onDragLeave: {
                parent.opacity = 0;
            }

            function getYoutubeId(url) {
                var regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*/;
                var match = url.match(regExp);
                return (match&&match[7].length===11)? match[7] : false;
            }

        }
    }
    
    ListModel {
        id: videoModel

        property int totalResults: 0
        property int itemsPerPage: 0
        property int startIndex: 1
        property int endIndex: itemsPerPage + startIndex - 1
        
        property string prevPageToken: ""
        property string nextPageToken: ""
        property string userName: ""
        property string playlistId: ""
        property string test: "AIzaSyDjzV9J1J5mp5H4dE9Q8d3eqrSap8Vu9Qk"
        property string videoSource: plasmoid.configuration.baseUrl + "/videos?part=snippet&maxResults=" + plasmoid.configuration.numberOfVideos * 5 +"&key=" + plasmoid.configuration.restricted
        property string searchSource:  plasmoid.configuration.baseUrl + "/search?part=snippet&maxResults=" + plasmoid.configuration.numberOfVideos * 5 +"&q=" + input.text + "&key=" + plasmoid.configuration.restricted
        property string usersSource: plasmoid.configuration.baseUrl + "/search?part=snippet&order=date&type=video&maxResults=" + plasmoid.configuration.numberOfVideos * 5 +"&channelId="+ userName +"&key="  + plasmoid.configuration.restricted
        property string playlistSource: plasmoid.configuration.baseUrl + "/playlistItems?part=snippet&maxResults=" + plasmoid.configuration.numberOfVideos * 5 +"&playlistId=" + playlistId + "&key="  + plasmoid.configuration.restricted
        property string source: searchSource

        function addVideo(videoId) {
            source = videoSource + "&id=" + videoId;
            reload(false);
        }
        
        function requestMore() {
            source = ((presetsBinding.when)? usersSource : (searchBinding.when)? searchSource : playlistSource ) + '&pageToken=' + nextPageToken
                startIndex += itemsPerPage
            reload(true)
        }

        function requestLess() {
            source = ((presetsBinding.when)? usersSource : (searchBinding.when)? searchSource : playlistSource ) + '&pageToken=' + prevPageToken  
                startIndex -= itemsPerPage
            reload(true)
        }

        function playVideo(videoId) {
            if(currentVideo.status === videoStatus.initial) {
                return;
            }
            webView.runJavaScript('playVideo("' + videoId + '");');
        }

        
        function playNextVideo() {
            if(videoModel.count <= 1) { 
                panel.state = "list";
                return;
            }
            for(var i=0, len = videoModel.count; i < len; i++) {
                if(videoModel.get(i).id === currentVideo.vId && i != (len-1)) {
                    currentVideo.vId = videoModel.get(i + 1).id;
                    currentVideo.title = videoModel.get(i + 1).title;
                    if(videoModel.get(i + 1).type !== "youtube#video") {
                        videoModel.playNextVideo();
                    }                    
                    webView.runJavaScript('cueVideo("' + videoModel.get(i + 1).id + '");');    
                    webView.runJavaScript('nextVideo();');
                    break;
                    
                }
                
                if (i >= (len-1)) {
                    panel.state = "list";
                }
            }
        }

        function reload(clearModel) {
            Ajax.request(source,function(err, data, xhr) {
                if (err || (!err && data && data.error)) {
                    console.log('something went wrong:', err, data);
                    return;
                }                
                    var doc = JSON.parse(data);
                    itemsPerPage = doc.pageInfo.resultsPerPage;
                    totalResults = doc.pageInfo.totalResults;
                    nextPageToken = (doc.nextPageToken)?doc.nextPageToken:'';
                    prevPageToken = (doc.prevPageToken)?doc.prevPageToken:'';
                    if(clearModel) {
                        videoModel.clear();
                    }

                    for (var i = 0, len = doc.items.length; i < len; i++) {
                        var title = doc.items[i].snippet.title;
                        var thumbnail = (doc.items[i].snippet.thumbnails === undefined)?'./icons/not-found.png':doc.items[i].snippet.thumbnails.default.url;
                        var id;
                        var type;
                         if (doc.items[i].kind === "youtube#searchResult" ) {
                            type = doc.items[i].id.kind;

                            switch(type) {
                                case "youtube#video":
                                    id = doc.items[i].id.videoId;
                                    break;
                                case "youtube#playlist":
                                    id = doc.items[i].id.playlistId;
                                    break;
                                case "youtube#channel":
                                    id = doc.items[i].id.channelId;
                                break;					
                            }
                        }
                        if (doc.items[i].kind === "youtube#playlistItem") {
                            type = doc.items[i].snippet.resourceId.kind;
                            id = doc.items[i].snippet.resourceId.videoId;
                        }
                        if (doc.items[i].kind === "youtube#video") {
                            type = doc.items[i].kind;
                            id = doc.items[i].id;
                        }
                        videoModel.append({ "title": title ,"thumbnail": thumbnail,"id": id,"type": type });
                    }	                
                
            });
        }
    }
    
    Component.onCompleted: {
      plasmoid.hideOnWindowDeactivate = !plasmoid.configuration.pinned;
      webView.url = "content/player.html?id=" + database.getRandomVideoId() + "&autoplay=" + plasmoid.configuration.autoplay
    }
    
}



