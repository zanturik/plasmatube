import QtQuick 2.15
import QtQuick.Controls 2.15 as QtControls
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0 as QtLayouts
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "../ajax.js" as Ajax

Item {
    id: googleSettings
    
    property alias cfg_client_id: client_id.text
    property alias cfg_client_secret: client_secret.text
    property alias cfg_access_token: access_token.text
    property alias cfg_access_token_type: access_token_type.text
    property alias cfg_access_token_expires_at: access_token_expires_at.text
    property alias cfg_refresh_token: refresh_token.text    
    property alias cfg_device_code: device_code.text
    property alias val_user_code: user_code.text
    property alias val_user_code_verification_url: user_code_verification_url.text
    property alias val_user_code_expires_at: user_code_expires_at.text
    property alias val_user_code_interval: user_code_interval.text
    
         QtLayouts.ColumnLayout {
        Column {
            Text {
                visible: false
                id: client_credentials_error
                color: theme.negativeTextColor
                text: "Client credentials are invalid!"
            }
        }


        Column {
         visible: cfg_access_token
	     QtControls.Label {
                text: i18n("Connected! You may watch videos :)")
            }
             QtControls.Button {
                text: i18n("Disconnect from google account")
                onClicked: {
                    cfg_access_token = ''
                    cfg_refresh_token = ''
                    generateUserCodeAndPoll()
                }
            }
        }
        Column {

            visible: true
            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("client_id:")
                }
                QtControls.TextField {
                    id: client_id
                    text: "Text"
                    QtLayouts.Layout.fillWidth: true
                    onTextEdited: { cfg_client_id = client_id.text.trim(); clearUserCode(); }
                }
                
            }

            QtLayouts.RowLayout {
                QtControls.Label {
                    text: i18n("client_secret:")
                }
                QtControls.TextField {
                    id: client_secret
                    QtLayouts.Layout.fillWidth: true
                    onTextEdited: { cfg_client_secret = client_secret.text.trim(); clearUserCode(); }
                }
            }    
        }

        Column {
            visible: !cfg_access_token && plasmoid.configuration.client_secret && plasmoid.configuration.client_secret === cfg_client_secret
             && plasmoid.configuration.client_id == cfg_client_id && plasmoid.configuration.client_id && client_credentials_error.visible == false
	        QtControls.Label {
                text: i18n("Please, enter the following code at the:")
		
            }
            QtControls.TextField {
                anchors.left: parent.left
                anchors.right: parent.right
                text: "https://www.google.com/device"
                maximumLength: 64
                readOnly: true
                onFocusChanged: { if(activeFocus) { selectAll() }  } 
            }            
            QtControls.TextField {
                id: userCodeInput
                placeholderText: i18n("Please, wait...")
                readOnly: true
                onFocusChanged: { if(activeFocus) { selectAll() }  } 
            }
            onVisibleChanged: { if(this.visible) { generateUserCodeAndPoll(); }}
        }	   
        Column {
            visible: false

            
            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("access_token:")
                }
                QtControls.TextField {
                    id: access_token
                    QtLayouts.Layout.fillWidth: true
                }
            }

            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("access_token_type:")
                }
                QtControls.TextField {
                    id: access_token_type
                    QtLayouts.Layout.fillWidth: true
                }
            }

            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("access_token_expires_at:")
                }
                QtControls.TextField {
                    id: access_token_expires_at
                    QtLayouts.Layout.fillWidth: true
                }
            }

            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("refresh_token:")
                }
                QtControls.TextField {
                    id: refresh_token
                    QtLayouts.Layout.fillWidth: true
                }
            } 
            
            
            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("device_code:")
                }
                QtControls.TextField {
                    id: device_code
                    QtLayouts.Layout.fillWidth: true
                }
            }

            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("user_code:")
                }
                QtControls.TextField {
                    id: user_code
                    QtLayouts.Layout.fillWidth: true
                }
            }

            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("user_code_verification_url:")
                }
                QtControls.TextField {
                    id: user_code_verification_url
                    QtLayouts.Layout.fillWidth: true
                }
            }

            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("user_code_expires_at:")
                }
                QtControls.TextField {
                    id: user_code_expires_at
                    QtLayouts.Layout.fillWidth: true
                }
            }


            QtLayouts.RowLayout {
                QtLayouts.Layout.fillWidth: true
                QtControls.Label {
                    text: i18n("user_code_interval:")
                }
                QtControls.TextField {
                    id: user_code_interval
                    QtLayouts.Layout.fillWidth: true
                }
            }            
	}
            
            
        }
        
    Timer {
        id: accessTokenTimer
        interval: 5000
        running: false
        repeat: true
        onTriggered: pollAccessToken()
    }
    
    function pollAccessToken() {    
        var url = 'https://oauth2.googleapis.com/token';
        Ajax.post({
            url: url,
            data: {
                client_id: cfg_client_id,
                client_secret: cfg_client_secret,
                code: cfg_device_code,
                grant_type: 'http://oauth.net/grant_type/device/1.0',
            },
        }, function(err, data) {
            data = JSON.parse(data);
            if (data.error) {
                if(data.error != 'authorization_pending') { client_credentials_error.visible = true; }
                return;
            }

            accessTokenTimer.stop();

            cfg_access_token = data.access_token;
            cfg_access_token_type = data.token_type;
            cfg_access_token_expires_at = Date.now() + data.expires_in * 1000;
            cfg_refresh_token = data.refresh_token;	    

        });
    }    
    
        
        
    function getUserCode(callback) {
        var url = 'https://accounts.google.com/o/oauth2/device/code';
        Ajax.post({
            url: url,
            data: {
                client_id: plasmoid.configuration.client_id,
                scope: 'https://www.googleapis.com/auth/youtube.readonly',
            },
        }, callback);
    }        
        

    function clearUserCode() {
        cfg_access_token = '';
        cfg_access_token_expires_at = '';
        cfg_access_token_type = '';
        val_user_code = '';
        val_user_code_expires_at = '';
        val_user_code_interval = '';
        val_user_code_verification_url = '';
        accessTokenTimer.stop();
        client_credentials_error.visible = false;
    }    

    function generateUserCodeAndPoll() {
        getUserCode(function(err, data) {
            if(err) {
                client_credentials_error.visible = true;
                return;
            }
            data = JSON.parse(data);
            device_code.text = data.device_code;
            val_user_code = data.user_code;
            val_user_code_verification_url = data.verification_url;
            val_user_code_expires_at = Date.now() + data.expires_in * 1000;
            val_user_code_interval = data.interval;

            userCodeInput.text = data.user_code;

            accessTokenTimer.interval = data.interval * 1000;
            accessTokenTimer.start();
        });
	
    }    	
	
    Component.onCompleted: {
        if (plasmoid.configuration.access_token) {
            //updateRecomendations();
        } else if(plasmoid.configuration.client_secret && plasmoid.configuration.client_id) {
            generateUserCodeAndPoll();
        }
    }	
    
        

}
