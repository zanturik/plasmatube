function request(opt, callback) {
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

    function countChannelVideos(id,type) {
		      switch(type) {
			case "youtube#playlist":
			    var url = plasmoid.configuration.baseUrl + "/playlistItems?part=snippet&maxResults=0&playlistId=" + id + "&key="  + plasmoid.configuration.restricted
			    break;
			case "youtube#channel":
			    var url = plasmoid.configuration.baseUrl +  "/search?part=snippet&channelId=" + id + "&maxResults=0&type=video&key="  + plasmoid.configuration.restricted;
			    break;					
		      }	    		  
		        
	var req = new XMLHttpRequest();
	req.open("GET",url,false);
	req.send();
	var data = JSON.parse(req.responseText);
	  return(data['pageInfo']['totalResults']);

      
    }


    function getFolderIndexByName(folderModel, title) {
        for (var i = 0, len = folderModel.count; i < len; i++) {
            if(folderModel.get(i).title == title) {
                return(i);
            }
		}        
		return(null);
    }
        

    
