import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.1
import org.julialang 1.0


GroupBox {
    id: general
    title: qsTr("Allgemeine Einstellungen")

    Layout.preferredWidth: area.width

    RowLayout {
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        ColumnLayout {
            ///////////////
            // 1. Spalte //
            ///////////////

            //////////////
            // 1. Zeile //
            //////////////
            RowLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
                GroupBox {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.fillWidth: true
                    title: "Nuklidvektor"
                    ComboBox {
                        id: comboBox_select_nv
                        anchors.horizontalCenter: parent.horizontalCenter
                        clip: false
                        model: nv_list
                        onCurrentTextChanged: {
                            Julia.get_genSettings_name(comboBox_select_nv.currentText)
                        }
                    }
                }

                GroupBox {
                    id: groupBox1
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.fillWidth: true
                    title: "Zeitraum"

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        TextField {
                            id: year1
                            text: qsTr(year1_ctx)
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            inputMask: qsTr("0000")
                            placeholderText: qsTr("2016")
                            onTextChanged: {
                                Julia.get_genSettings_year( [text, nextItem(this, 2).text] )
                                //Julia.decay_gui(comboBox_select_nv.currentText, false)
                            }
                        }

                        Text {
                            text: "bis"
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        TextField {
                            id: year2
                            text: qsTr(year2_ctx)
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            inputMask: "0000"
                            placeholderText: qsTr("2026")
                            onTextChanged: {
                                Julia.get_genSettings_year( [nextItem(this, -2).text, text] )
                                Julia.decay_gui(comboBox_select_nv.currentText, false)
                            }
                        }
                    }
                }


            }
            //////////////
            // 2. Zeile //
            //////////////
            RowLayout {
                GroupBox {
                    id: groupBox3
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "Freigabeverfahren"


                    Column {
                      anchors.horizontalCenter: parent.horizontalCenter

                      Grid {
                        // anchors.horizontalCenter: parent.horizontalCenter
                        // anchors.verticalCenter: groupBox3.verticalCenter
                        // effectiveHorizontalItemAlignment: Grid.AlignHCenter
                        verticalItemAlignment: AlignVCenter
                        columns: 3
                        rowSpacing: 10

                        CheckBox {
                          text: "Freimessanlage"
                          checked: true
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("fma", true) : Julia.get_genSettings_co60eq("fma", false)
                          }

                        CheckBox {
                          text: "in-situ"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("is", true) : Julia.get_genSettings_co60eq("is", false)
                          }

                        Label {
                          text: " "
                        }

                        CheckBox {
                          text: "MicroCont"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("mc", true) : Julia.get_genSettings_co60eq("mc", false)
                          }

                        CheckBox {
                          text: "CoMo"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("como", true) : Julia.get_genSettings_co60eq("como", false)
                          }

                        CheckBox {
                          text: "LB124"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("lb124", true) :  Julia.get_genSettings_co60eq("lb124", false)
                          }
                        }
                      }
                  }
/*                    Column {
                      anchors.horizontalCenter: parent.horizontalCenter

                      Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        CheckBox {
                          text: "Freimessanlage"
                          checked: true
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("fma", true) : Julia.get_genSettings_co60eq("fma", false)
                        }

                        CheckBox {
                          text: "in-situ"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("is", true) : Julia.get_genSettings_co60eq("is", false)
                        }
                      }

                      Row {
                        anchors.horizontalCenter: parent.horizontalCenter

                        CheckBox {
                          text: "MicroCont"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("mc", true) : Julia.get_genSettings_co60eq("mc", false)
                        }

                        CheckBox {
                          text: "CoMo"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("como", true) : Julia.get_genSettings_co60eq("como", false)
                        }

                        CheckBox {
                          text: "LB124"
                          onCheckedChanged: checked == true ? Julia.get_genSettings_co60eq("lb", true) : Julia.get_genSettings_co60eq("lb", false)
                        }
                    }
                  }*/


                GroupBox {
                  id: groupBox4
                  Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                  Layout.fillWidth: true
                  title: "Optimierungsziel"

                  ComboBox {
                      anchors.horizontalCenter: parent.horizontalCenter
                      model: ot_list
                      onCurrentTextChanged: Julia.get_genSettings_target(currentText)
                    }
                  }
            }
        }
        ///////////////
        // 2. Spalte //
        ///////////////
        GroupBox {
            id: groupBox2
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.fillWidth: true
            title: qsTr("Freigabepfad")

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 13
                rowSpacing: 10

                Text {
                    objectName: "fma"
                    text: "Freimessanlage"
                }

                Repeater {
                    id: repeater_fma
                    model: ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c", "1a*"]
                    CheckBox {
                        text: modelData
                        onCheckedChanged: Julia.update_clearance_path(text, checked, firstItem(this).objectName )
                    }
                }

                Text {
                    text: "MicroCont"
                    objectName: "mc"
                }

                Repeater {
                    id: repeater_mc
                    model: ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c", "1a*"]
                    CheckBox {
                        text: modelData
                        onCheckedChanged: Julia.update_clearance_path(text, checked, nextItem(this, -1-index).objectName)
                    }
                }

                Text {
                    text: "CoMo"
                    objectName: "como"
                }

                Repeater {
                    id: repeater_como
                    model: ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c", "1a*"]
                    CheckBox {
                        text: modelData
                        onCheckedChanged: Julia.update_clearance_path(text, checked, nextItem(this, -1-index).objectName)
                    }
                }

                Text {
                    text: "LB124"
                    objectName: "lb124"
                }

                Repeater {
                    id: repeater_lb124
                    model: ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c", "1a*"]
                    CheckBox {
                        text: modelData
                        onCheckedChanged: Julia.update_clearance_path(text, checked, nextItem(this, -1-index).objectName)
                    }
                }

                Text {
                    text: "in-situ"
                    objectName: "is"
                }

                Repeater {
                    id: repeater_is
                    model: ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c", "1a*"]
                    CheckBox {
                        text: modelData
                        onCheckedChanged: Julia.update_clearance_path(text, checked, nextItem(this, -1-index).objectName)
                    }
                }

                // set some free release paths as standard
                Component.onCompleted: {
                    var idx_fma = [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11]
                    for (var i = 0; i < idx_fma.length; i++)
                        repeater_fma.itemAt( idx_fma[i] ).checked = true

                    var idx_mc = [0, 1, 4, 9, 10]
                    for (var i = 0; i < idx_mc.length; i++)
                        repeater_mc.itemAt( idx_mc[i] ).checked = true

                    var idx_como = [0, 1, 4, 9, 10]
                    for (var i = 0; i < idx_como.length; i++)
                        repeater_como.itemAt( idx_como[i] ).checked = true

                    var idx_lb124 = [0, 1, 4, 9, 10]
                    for (var i = 0; i < idx_lb124.length; i++)
                        repeater_lb124.itemAt( idx_lb124[i] ).checked = true

                    var idx_is = [0, 4, 9, 10]
                    for (var i = 0; i < idx_is.length; i++)
                        repeater_is.itemAt( idx_is[i] ).checked = true

                    Julia.decay_gui(comboBox_select_nv.currentText, false)
                }
            }
        }
    }
}
