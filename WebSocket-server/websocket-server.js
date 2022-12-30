// http://ejohn.org/blog/ecmascript-5-strict-mode-json-and-more/
"use strict";

// Optional. You will see this name in eg. 'ps' or 'top' command
process.title = 'node-chat';

// Port where we'll run the websocket server
var webSocketsServerPort = 1337;

// websocket and http servers
var webSocketServer = require('websocket').server;
var http = require('http');

/**
 * Global variables
 */
// list of currently connected clients (users)
var clients = {};
var gamesInfo = {};
const maximumMessagesInChatHistory = 10;

/**
 * Helper function for escaping input strings
 */
function htmlEntities(str) {
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// Array with some colors
var colors = ['red', 'green', 'blue', 'magenta', 'purple', 'plum', 'orange'];
// ... in random order
colors.sort(function (a, b) { return Math.random() > 0.5; });

/**
 * HTTP server
 */
var server = http.createServer(function (request, response) {
    // Not important for us. We're writing WebSocket server, not HTTP server
});
server.listen(webSocketsServerPort, function () {
    console.log((new Date()) + " Server is listening on port " + webSocketsServerPort);
});

/**
 * WebSocket server
 */
var wsServer = new webSocketServer({
    // WebSocket server is tied to a HTTP server. WebSocket request is just
    // an enhanced HTTP request. For more info http://tools.ietf.org/html/rfc6455#page-6
    httpServer: server
});

// This callback function is called every time someone
// tries to connect to the WebSocket server
wsServer.on('request', function (request) {
    console.log((new Date()) + ' Connection from origin ' + request.origin + '.');

    // accept connection - you should check 'request.origin' to make sure that
    // client is connecting from your website
    // (http://en.wikipedia.org/wiki/Same_origin_policy)
    var connection = request.accept(null, request.origin);
    // we need to know client index to remove them on 'close' event
    var userName = false;
    var userColor = false;

    console.log((new Date()) + ' Connection accepted.');

    // user sent some message
    connection.on('message', function (message) {
        if (userName === false) { // first message sent by user is their name
            // remember user name
            userName = htmlEntities(message.utf8Data);
            clients[userName] = { connection };
            // get random color and send it back to the user
            userColor = colors.shift();
            connection.sendUTF(JSON.stringify({ type: 'color', data: userColor }));
            console.log((new Date()) + ' User is known as: ' + userName
                + ' with ' + userColor + ' color.');

        } else { // log and broadcast the message
            var gameID = JSON.parse(message.binaryData).gameID;
            if (message.type === 'utf8') {
                console.log((new Date()) + ' Received Message from '
                + userName + ': ' + message);
            }
            else {
                if(gameID != undefined && JSON.parse(message.binaryData).squares != undefined) {
                    if (gamesInfo[JSON.parse(message.binaryData).gameID] != undefined) {
                        gamesInfo[JSON.parse(message.binaryData).gameID].lastTurn = message.binaryData;
                    }
                    else {
                        gamesInfo[JSON.parse(message.binaryData).gameID] = {lastTurn : message.binaryData};
                    }
                }
                if(gameID != undefined && JSON.parse(message.binaryData).column != undefined) {
                    if (gamesInfo[JSON.parse(message.binaryData).gameID] != undefined) {
                        gamesInfo[JSON.parse(message.binaryData).gameID].pawnTransform = message.binaryData;
                    }
                    else {
                        gamesInfo[JSON.parse(message.binaryData).gameID] = {pawnTransform : message.binaryData};
                    }
                }
                if(gameID != undefined && JSON.parse(message.binaryData).playerType != undefined) {
                    var playerType = JSON.parse(message.binaryData).playerType;
                    if (gamesInfo[JSON.parse(message.binaryData).gameID] != undefined) {
                        gamesInfo[JSON.parse(message.binaryData).gameID][playerType] = message.binaryData;
                    }
                    else {
                        gamesInfo[JSON.parse(message.binaryData).gameID] = {[playerType] : message.binaryData};
                    }
                }
                if(gameID != undefined && JSON.parse(message.binaryData).message != undefined) {
                    var messageObject = JSON.parse(message.binaryData);
                    if (gamesInfo[messageObject.gameID].chatHistory != undefined) {
                        //we are not storing it as binary data, because array of multiple objects in binary data is not the same, as
                        //array of all of this objects in binary data, so we have to store it as object and then encode in binary data
                        //whole array of this objects
                        gamesInfo[messageObject.gameID].chatHistory.push(messageObject);
                        if (gamesInfo[messageObject.gameID].chatHistory.length > maximumMessagesInChatHistory) {
                            gamesInfo[messageObject.gameID].chatHistory = gamesInfo[messageObject.gameID].chatHistory.slice(-maximumMessagesInChatHistory);
                        }
                    }
                    else {
                        gamesInfo[messageObject.gameID] = {chatHistory : [messageObject]};
                    }
                }
                console.log((new Date()) + ' Received Message from '
                + userName + ': ' + message['binaryData']);
            }

            // broadcast message to all connected clients
            for(var key in clients) {
                var value = clients[key];
                if(gameID != undefined && JSON.parse(message.binaryData).requestLastAction == true) {
                    var lastTurn = gamesInfo[gameID].lastTurn;
                    var pawnTransform = gamesInfo[gameID].pawnTransform;
                    var creatorMessage = gamesInfo[gameID].creator;
                    var joinerMessage = gamesInfo[gameID].joiner;
                    var chatHistory = gamesInfo[gameID].chatHistory;
                    if (lastTurn != undefined) {
                        value.connection.sendBytes(Buffer.from(lastTurn));
                    }
                    if (pawnTransform != undefined) {
                        value.connection.sendBytes(Buffer.from(pawnTransform));
                    }
                    if (chatHistory != undefined) {
                        value.connection.sendBytes(Buffer.from(JSON.stringify(chatHistory)));
                    }
                    if (creatorMessage != undefined && creatorMessage != message.binaryData) {
                        value.connection.sendBytes(Buffer.from(creatorMessage));
                    }
                    if (joinerMessage != undefined && joinerMessage != message.binaryData) {
                        value.connection.sendBytes(Buffer.from(joinerMessage));
                    }
                }
                else {
                    value.connection.sendBytes(Buffer.from(message.binaryData));
                }
            }
            // }
        }
    });

    // user disconnected
    connection.on('close', function (connection) {
        if (userName !== false && userColor !== false) {
            console.log((new Date()) + " Peer "
                + connection.remoteAddress + userName + " disconnected.");
            // remove user from the list of connected clients
            delete clients[userName];
            // push back user's color to be reused by another user
            colors.push(userColor);
        }
    });

});