import QtQuick.LocalStorage 2.0
import QtQuick 2.0


Item {
    id: root
    property var  db: LocalStorage.openDatabaseSync("kde.plasmatubeDB", "1.0", "Database storing your links to your favorite videos!", 1000000)
    Component.onCompleted: {
       init();
    }



    function init() {
            root.db.transaction(
                function(tx) {
                    tx.executeSql('CREATE TABLE IF NOT EXISTS folders([id] INTEGER PRIMARY KEY, [name] Text, [sort] Integer)');
                    tx.executeSql('CREATE TABLE IF NOT EXISTS videos([id] INTEGER PRIMARY KEY, [title] Text, [thumbnail] Text, [type] Text, [videoid] Text, [totalcount] Integer, [lastupdated] Date, [rating] Integer, [folderid] Integer, FOREIGN KEY(folderid) REFERENCES folders(id))');
                }
            )
        }

    function addFolder(name) {
            root.db.transaction(
                function(tx) {
                    var rs = tx.executeSql('SELECT id FROM folders WHERE name = ?', [ name ]);
                                if(rs.rows.length > 0 ) {
                                    return;
                                }
                    tx.executeSql('INSERT INTO folders (sort, name)  SELECT MAX(sort) + 1,"' + name +'" FROM folders' );
                }
            )


    }

    function clearFolder(folderId) {
            root.db.transaction(
                function(tx) {
                    tx.executeSql('DELETE FROM videos WHERE folderid = ?', [ folderId ]);
                }
            )
    }

    function deleteFolder(folderId) {
            clearFolder(folderId);
            root.db.transaction(
                function(tx) {
                    tx.executeSql('DELETE FROM folders WHERE id = ?', [ folderId ]);
                }
            )
    }

    function deleteFolderByName(name) {
            root.db.transaction(
                function(tx) {
                    var folders = tx.executeSql('SELECT id FROM folders WHERE name = ?', [ name ]);
                        if(folders.rows.length == 0 ) {
                            return;
                        }
                    for (var i = 0; i < folders.rows.length; i++) {
                        deleteFolder(folders.rows.item(i).id);
                    }
                }
            )
    }

    function getFolderName(folderId) {
        if(folderId == null) {
            return null;
        }
        var folderName;
        root.db.transaction(
             function(tx) {
                    var folders = tx.executeSql('SELECT name FROM folders WHERE id = ?', [ folderId ]);
                   if(folders.rows.length == 0 ) {
                        folderName = null;
                   } else {
                    folderName = folders.rows.item(0).name;
                   }
                }
             )
        return folderName;
    }


    function getFolders() {
            var folders;
            root.db.transaction(
                function(tx) {
                    folders = tx.executeSql('SELECT id, name FROM folders');
                }
            )
            return folders;
    }

    function getVideos(folderId) {
            var videos;
            root.db.transaction(
               function(tx) {
                if (folderId == null){
                    videos = tx.executeSql('SELECT * FROM videos WHERE folderid IS NULL');
                } else {
                    videos = tx.executeSql('SELECT * FROM videos WHERE folderid = ?', [ folderId ]);
                }
               }
            )
            return videos;
    }

    function addVideo(video, folderId) {
            root.db.transaction(
                function(tx) {
                    tx.executeSql('INSERT INTO videos (title, thumbnail, type, videoId, totalcount, lastupdated, rating, folderId)  VALUES(?,?,?,?,?,?,?,?)',
                     [ video.title, video.thumbnail, video.type, video.id, 0, '2019-01-01', 0, folderId ]);
                }
            )
    }

}
