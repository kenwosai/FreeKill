// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Fk.LobbyElement
import Fk.Common
import "Logic.js" as Logic

Item {
  id: root
  property alias roomModel: roomModel

  property string password

  Rectangle {
    width: parent.width / 2 - roomListLayout.width / 2
    height: parent.height * 0.7
    anchors.top: exitButton.bottom
    anchors.bottom: createRoomButton.top
    anchors.right: parent.right
    anchors.rightMargin: 20
    color: "#88EEEEEE"
    radius: 6

    Flickable {
      id: flickableContainer
      ScrollBar.vertical: ScrollBar {}
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 10
      flickableDirection: Flickable.VerticalFlick
      width: parent.width - 10
      height: parent.height - 10
      contentWidth: flickableContainer.width
      contentHeight: flickableContainer.height
      clip: true

      Text {
        anchors.fill: parent
        wrapMode: TextEdit.WrapAnywhere
        text: Backend.translate('Bulletin Info')
      }
    }
  }

  Component {
    id: roomDelegate

    Item {
      height: 48
      width: roomList.width

      RowLayout {
        anchors.fill: parent
        spacing: 16
        Text {
          text: roomId
          color: "grey"
        }

        Text {
          horizontalAlignment: Text.AlignLeft
          Layout.fillWidth: true
          text: roomName + (hasPassword ? "(🔒)" : "")
          font.pixelSize: 20
        }

        Text {
          text: Backend.translate(gameMode)
        }

        Text {
          color: (playerNum == capacity) ? "red" : "black"
          text: playerNum + "/" + capacity
          font.pixelSize: 20
          font.bold: true
        }

        Button {
          text: (playerNum < capacity) ? Backend.translate("Enter") :
          Backend.translate("Observe")

          onClicked: {
            if (hasPassword) {
              lobby_dialog.sourceComponent = enterPassword;
              lobby_dialog.item.roomId = roomId;
              lobby_dialog.item.playerNum = playerNum;
              lobby_dialog.item.capacity = capacity;
              lobby_drawer.open();
            } else {
              enterRoom(roomId, playerNum, capacity, "");
            }
          }
        }
      }
    }
  }

  ListModel {
    id: roomModel
  }

  PersonalSettings {
  }

  RowLayout {
    id: roomListLayout
    anchors.centerIn: parent
    width: childrenRect.width
    height: parent.height
    Item {
      Layout.preferredWidth: root.width * 0.6
      Layout.fillHeight: true
      Rectangle {
        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.centerIn: parent
        color: "#88EEEEEE"
        radius: 16
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: Backend.translate("Room List")
        }
        ListView {
          id: roomList
          height: parent.height * 0.9
          width: parent.width * 0.95
          contentHeight: roomDelegate.height * count
          ScrollBar.vertical: ScrollBar {}
          anchors.centerIn: parent
          delegate: roomDelegate
          model: roomModel
        }
      }
    }
  }

  Button {
    id: createRoomButton
    anchors.bottom: buttonRow.top
    anchors.right: parent.right
    width: 120
    display: AbstractButton.TextUnderIcon
    icon.name: "media-playback-start"
    text: Backend.translate("Create Room")
    onClicked: {
      lobby_dialog.sourceComponent = Qt.createComponent("../LobbyElement/CreateRoom.qml");
      lobby_drawer.open();
      config.observing = false;
    }
  }

  RowLayout {
    id: buttonRow
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    Button {
      text: Backend.translate("Generals Overview")
      onClicked: {
        mainStack.push(mainWindow.generalsOverviewPage);
        mainStack.currentItem.loadPackages();
      }
    }
    Button {
      text: Backend.translate("Cards Overview")
      onClicked: {
        mainStack.push(mainWindow.cardsOverviewPage);
        mainStack.currentItem.loadPackages();
      }
    }
    Button {
      text: Backend.translate("Scenarios Overview")
      onClicked: {
        mainStack.push(mainWindow.modesOverviewPage);
      }
    }
    Button {
      text: Backend.translate("Replay")
    }
    Button {
      text: Backend.translate("About")
      onClicked: {
        mainStack.push(mainWindow.aboutPage);
      }
    }
  }

  Button {
    id: exitButton
    anchors.right: parent.right
    text: Backend.translate("Exit Lobby")
    display: AbstractButton.TextBesideIcon
    icon.name: "application-exit"
    onClicked: {
      toast.show("Goodbye.");
      mainStack.pop();
      Backend.quitLobby();
    }
  }

  Drawer {
    id: lobby_drawer
    width: parent.width * 0.4 / mainWindow.scale
    height: parent.height / mainWindow.scale
    dim: false
    clip: true
    dragMargin: 0
    scale: mainWindow.scale
    transformOrigin: Item.TopLeft

    Loader {
      id: lobby_dialog
      anchors.fill: parent
      onSourceChanged: {
        if (item === null)
          return;
        item.finished.connect(() => {
          sourceComponent = undefined;
          lobby_drawer.close();
        });
      }
      onSourceComponentChanged: sourceChanged();
    }
  }

  Component {
    id: enterPassword
    ColumnLayout {
      property int roomId
      property int playerNum
      property int capacity
      signal finished()
      anchors.fill: parent
      anchors.margins: 16

      Text {
        text: Backend.translate("Please input room's password")
      }

      TextField {
        id: passwordEdit
        onTextChanged: root.password = text;
      }

      Button {
        text: "OK"
        onClicked: {
          enterRoom(roomId, playerNum, capacity, root.password);
          parent.finished();
        }
      }

      Component.onCompleted: {
        passwordEdit.text = "";
      }
    }
  }

  function enterRoom(roomId, playerNum, capacity, pw) {
    if (playerNum < capacity) {
      config.observing = false;
      mainWindow.busy = true;
      ClientInstance.notifyServer(
        "EnterRoom",
        JSON.stringify([roomId, pw])
      );
    } else {
      config.observing = true;
      mainWindow.busy = true;
      ClientInstance.notifyServer(
        "ObserveRoom",
        JSON.stringify([roomId, pw])
      );
    }
  }

  property int lobbyPlayerNum: 0
  property int serverPlayerNum: 0

  function updateOnlineInfo() {
  }

  onLobbyPlayerNumChanged: updateOnlineInfo();
  onServerPlayerNumChanged: updateOnlineInfo();

  Rectangle {
    id: info
    color: "#88EEEEEE"
    width: childrenRect.width + 8
    height: childrenRect.height + 4
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    radius: 4

    Text {
      x: 4; y: 2
      font.pixelSize: 16
      text: Backend.translate("$OnlineInfo")
        .arg(lobbyPlayerNum).arg(serverPlayerNum) + "\n"
        + "Powered by FreeKill " + FkVersion
    }
  }

  ChatBox {
    id: lobbyChat
    anchors.bottom: info.top
    width: info.width
    height: root.height * 0.6
    isLobby: true
    color: "#88EEEEEE"
    radius: 4
  }

  Danmaku {
    id: danmaku
    width: parent.width
  }

  function addToChat(pid, raw, msg) {
    if (raw.type !== 1) return;
    msg = msg.replace(/\{emoji([0-9]+)\}/g, '<img src="../../image/emoji/$1.png" height="24" width="24" />');
    raw.msg = raw.msg.replace(/\{emoji([0-9]+)\}/g, '<img src="../../image/emoji/$1.png" height="24" width="24" />');
    lobbyChat.append(msg);
    danmaku.sendLog("<b>" + raw.userName + "</b>: " + raw.msg);
  }

  function sendDanmaku(msg) {
    danmaku.sendLog(msg);
    lobbyChat.append(msg);
  }

  Component.onCompleted: {
    toast.show(Backend.translate("$WelcomeToLobby"));
  }
}
