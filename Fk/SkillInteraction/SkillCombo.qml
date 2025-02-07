// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk.Pages

MetroButton {
  id: root
  property string skill
  property var choices: []
  property string default_choice
  property string answer: default_choice

  function processPrompt(prompt) {
    const data = prompt.split(":");
    let raw = Backend.translate(data[0]);
    const src = parseInt(data[1]);
    const dest = parseInt(data[2]);
    if (raw.match("%src")) raw = raw.replace("%src", Backend.translate(getPhoto(src).general));
    if (raw.match("%dest")) raw = raw.replace("%dest", Backend.translate(getPhoto(dest).general));
    if (raw.match("%arg")) raw = raw.replace("%arg", Backend.translate(data[3]));
    if (raw.match("%arg2")) raw = raw.replace("%arg2", Backend.translate(data[4]));
    return raw;
  }

  text: processPrompt(answer)

  onAnswerChanged: {
    if (!answer) return;
    Backend.callLuaFunction(
      "SetInteractionDataOfSkill",
      [skill, JSON.stringify(answer)]
    );
    roomScene.dashboard.startPending(skill);
  }

  onClicked: {
    roomScene.popupBox.sourceComponent = Qt.createComponent("../RoomElement/ChoiceBox.qml");
    let box = roomScene.popupBox.item;
    box.options = choices;
    box.accepted.connect(() => {
      answer = choices[box.result];
    });
  }

}
