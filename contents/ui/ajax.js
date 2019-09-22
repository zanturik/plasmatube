function request(opt, callback) {
//    checkIsTokenExpired();
    if (typeof opt === 'string') {
        opt = {url: opt};
    }
    var req = new XMLHttpRequest();
    req.onerror = function(e) {
        console.log('XMLHttpRequest.onerror', e.status, e.statusText, e.message, e);
    }
    req.onreadystatechange = function() {
   
        if (req.readyState === 4) {
            if (200 <= req.status && req.status < 400) {

                callback(null, req.responseText, req);
            } else {
                if (req.status === 401) {
                    updateAccessToken();
                    return;
                }
                var msg = "HTTP Error " + req.status + ": " + req.statusText;
                callback(msg, req.responseText, req);
            }
        }
    }
    req.open(opt.method || "GET", opt.url, true);
    if (opt.headers) {
        for (var key in opt.headers) {
            req.setRequestHeader(key, opt.headers[key]);
        }
    }
    req.send(opt.data);
}


function post(opt, callback) {
    if (typeof opt === 'string') {
        opt = {url: opt};
    }
    opt.method = 'POST';
    opt.headers = opt.headers || {};
    opt.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    if (opt.data) {
        var s = '';
        for (var key in opt.data) {
            s += encodeURIComponent(key) + '=' + encodeURIComponent(opt.data[key]) + '&';
        }
        opt.data = s;
    }
    request(opt, callback);
}


    function fetchNewAccessToken(callback) {
        var url = 'https://www.googleapis.com/oauth2/v4/token';
        post({
            url: url,
            data: {
                client_id: plasmoid.configuration.client_id,
                client_secret: plasmoid.configuration.client_secret,
                refresh_token: plasmoid.configuration.refresh_token,
                grant_type: 'refresh_token',
            },
        }, callback);
    }

    function updateAccessToken() {
        if (plasmoid.configuration.refresh_token) {
            fetchNewAccessToken(function(err, data, xhr) {
                if (err || (!err && data && data.error)) {
                    return console.log('Error when using refreshToken:', err, data);
                }
                data = JSON.parse(data);

                plasmoid.configuration.access_token = data.access_token;
                plasmoid.configuration.access_token_type = data.token_type;
                plasmoid.configuration.access_token_expires_at = Date.now() + data.expires_in * 1000;
            });
        }
    }

    function checkIsTokenExpired()
    {
      if(plasmoid.configuration.access_token_expires_at < Date.now())
      {
	updateAccessToken();
      } 
    }
    

    function countChannelVideos(id,type) {
		      switch(type) {
			case "youtube#playlist":
			    var url = plasmoid.configuration.baseUrl + "/playlistItems?part=snippet&maxResults=0&playlistId=" + id + "&access_token="  + plasmoid.configuration.access_token
			    break;
			case "youtube#channel":
			    var url = plasmoid.configuration.baseUrl +  "/search?part=snippet&channelId=" + id + "&maxResults=0&type=video&access_token="  + plasmoid.configuration.access_token;
			    break;					
		      }	    		  
		        
	var req = new XMLHttpRequest();
	req.open("GET",url,false);
	req.send();
	var data = JSON.parse(req.responseText);
	  return(data['pageInfo']['totalResults']);

      
    }

    function deleteFolder(title, channelModel,folderModel,activityId) {
        for (var i = 0, len = channelModel.count; i < len; i++) {
		  if(channelModel.get(i) && !channelModel.get(i).folder && ((!channelModel.get(i).parentFolder && !title) || (channelModel.get(i).parentFolder !== undefined && channelModel.get(i).parentFolder == title)))
          {
              channelModel.remove(i);
          }
            
		}
        for (var j = 0, len = folderModel.count; j < len; j++) {
            if(folderModel.get(j) && folderModel.get(j).title && folderModel.get(j).title == title) {
            folderModel.remove(j);
            }
        }
        return(saveChannelsList(channelModel,folderModel,activityId));
    }
    
    
    function saveChannelsList(model,folders,activityId) {
		var channels = plasmoid.configuration.channels_list ? JSON.parse(Qt.atob(plasmoid.configuration.channels_list)) : new Object();
        var activityChannels = new Array();
        for (var i = 0, len = model.count; i < len; i++) {
		  var video = model.get(i);
          activityChannels[i] = {"title": video.title,"id": video.id,"thumbnail": video.thumbnail,"total": video.total,"type": video.type, "parentFolder": video.parentFolder };
		}
        var counter = i + 1;
        for (var j = 0, len = folders.count; j < len; j++) {
            if(folders.get(j).title) {
                activityChannels[counter] = ({"title": folders.get(j).title, "folder": true });
                counter++;
            }
        }
		channels[activityId] = activityChannels; 
		return(Qt.btoa(JSON.stringify(channels)));
    }    
        
    function addFolder(name,activityId) {
		var channels = plasmoid.configuration.channels_list ? JSON.parse(Qt.atob(plasmoid.configuration.channels_list)) : new Object();
		if (!(activityId in channels)) {
		  channels[activityId]=[];	  
		}
		var activityChannels = channels[activityId];
        for(var i=0, len = activityChannels.length; i<len; i++) {
           if(!activityChannels[i]) { continue; }
           if(activityChannels[i]["folder"] && activityChannels[i]["title"] == name) {
                    return;
           }
            
        }
		activityChannels.push({"title": name,"folder": true });
		channels[activityId] = activityChannels; 
		plasmoid.configuration.channels_list = Qt.btoa(JSON.stringify(channels));         
    }
        
    function getFolderIndexByName(folderModel, title) {
        for (var i = 0, len = folderModel.count; i < len; i++) {
            if(folderModel.get(i).title == title) {
                return(i);
            }
		}        
		return(null);
    }
        
    function addChannel(video,activityId)
    {
		var channels = plasmoid.configuration.channels_list ? JSON.parse(Qt.atob(plasmoid.configuration.channels_list)) : new Object();

		if (!(activityId in channels)) {
		  channels[activityId]=[];	  
		}
		var activityChannels = channels[activityId];
		var total = countChannelVideos(video.id,video.type);
		activityChannels.push({"title": video.title,"id": video.id,"thumbnail": video.thumbnail,"total": total,"type": video.type });
		channels[activityId] = activityChannels; 
		plasmoid.configuration.channels_list = Qt.btoa(JSON.stringify(channels));      
    }
    
    
