import QtQuick.LocalStorage 2.0
import QtQuick 2.15
import QtQml 2.15

Item {
    id: root
    property var  db: LocalStorage.openDatabaseSync("kde.plasmatubeDB", "1.0", "Database storing your links to your favorite videos!", 1000000)
    Component.onCompleted: {
       init();
    }



    function init() {
            root.db.transaction(
                function(tx) {
                    tx.executeSql('CREATE TABLE IF NOT EXISTS folders([id] INTEGER PRIMARY KEY, [name] TEXT, [sort] INTEGER)');
                    tx.executeSql('CREATE TABLE IF NOT EXISTS videos([id] INTEGER PRIMARY KEY, [title] TEXT, [thumbnail] TEXT, [type] TEXT, [videoid] TEXT, [totalcount] INTEGER, [lastupdated] DATE, [rating] INTEGER, [folderid] INTEGER, [sort] INTEGER, FOREIGN KEY(folderid) REFERENCES folders(id))');
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
                        if(folders.rows.length === 0 ) {
                            return;
                        }
                    for (var i = 0; i < folders.rows.length; i++) {
                        deleteFolder(folders.rows.item(i).id);
                    }
                }
            )
    }

    function setFolder(folderId, videoId) {
            root.db.transaction(
               function(tx) {
                if (folderId === null || folderId === 0){
                    tx.executeSql('UPDATE videos SET folderid = NULL WHERE id = ?', [ videoId ]);
                } else {
                    tx.executeSql('UPDATE videos SET folderid = ? WHERE id = ?', [ folderId, videoId ]);
                }
               }
            )
    }

    function getFolderName(folderId) {
        if(folderId === null || folderId === 0) {
            return null;
        }
        var folderName;
        root.db.transaction(
             function(tx) {
                    var folders = tx.executeSql('SELECT name FROM folders WHERE id = ?', [ folderId ]);
                   if(folders.rows.length === 0 ) {
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
                    folders = tx.executeSql('SELECT id, name FROM folders ORDER BY sort ASC');
                }
            )
            return folders;
    }

    function getVideos(folderId) {
            var videos;
            root.db.transaction(
               function(tx) {
                if (folderId === null || folderId === 0){
                    videos = tx.executeSql('SELECT * FROM videos WHERE folderid IS NULL ORDER BY sort ASC');
                } else {
                    videos = tx.executeSql('SELECT * FROM videos WHERE folderid = ? ORDER BY sort ASC', [ folderId ]);
                }
               }
            )
            return videos;
    }

    function addVideo(video, folderId) {
            root.db.transaction(
                function(tx) {
                    var rs;
                   if (folderId === null || folderId === 0) {
                   rs = tx.executeSql('SELECT MAX(sort) as maxsort FROM videos WHERE folderId IS NULL');
                   } else
                   {
                   rs = tx.executeSql('SELECT MAX(sort) as maxsort FROM videos WHERE folderId = ?', [ folderId ]);
                   }
                   var sortValue = rs.rows.item(0).maxsort + 1;

                var currentDate = new Date();
                     tx.executeSql('INSERT INTO videos (title, thumbnail, type, videoId, totalcount, lastupdated, rating, folderId, sort)  VALUES(?,?,?,?,?,?,?,?,?)',
                     [ video.title, video.thumbnail, video.type, video.id, 0, currentDate, 0, folderId, sortValue ]);

                }
            )
    }

    function deleteVideo(videoId) {
            root.db.transaction(
                function(tx) {
                    tx.executeSql('DELETE FROM videos WHERE id = ?', [ videoId ]);
                }
            )
    }

    function setSortVideo(videoId, sortValue) {
            root.db.transaction(
               function(tx) {
                    tx.executeSql('UPDATE videos SET sort = ? WHERE id = ?', [ sortValue, videoId ]);
               }
            )
    }

    function getRandomVideoId() {
                var videos;
                var videoId = "5fzYJtuhueU";
                root.db.transaction(
                    function(tx) {
                       videos = tx.executeSql('SELECT * FROM videos WHERE type = "youtube#video" ORDER BY RANDOM() LIMIT 1;');
                    }
                )
                if(videos.rows.length !== 0 ) {
                  videoId = videos.rows.item(0).videoid;

                }
                return videoId;
    }

}
