import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0


GroupBox {

    property int nuclide_name_length: 70
    id: constraints
    title: "Relevante Nuklide und Nebenbedingungen"
    Layout.preferredWidth: area.width



    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        GroupBox {
            id: groupBox1
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
            title: "α"

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [ "U234", "U235", "U238", "Pu238", "Pu239Pu240", "Am241", "Cm242", "Cm244" ]

                    RowLayout {
                        CheckBox {
                            text: modelData
                            Layout.preferredWidth: nuclide_name_length + 25
                            onCheckedChanged: {
                                for (var i=1; i<=3; i++) (checked == true) ? nextItem(this, i).enabled = true : nextItem(this, i).enabled = false;
                                (checked == true) ? Julia.get_rel_nuc(text, nextItem(this, 1).currentText, nextItem(this, 2).text, nextItem(this, 3).text ) : Julia.rm_rel_nuc(text)
                            }
                        }

                        ComboBox {
                            enabled: false
                            Layout.preferredWidth: nuclide_name_length
                            model: ["NONE", "<=", "==", ">="]
                            onCurrentTextChanged: Julia.get_relation(nextItem(this, -1).text, currentText)
                        }

                        TextField {
                            enabled: false
                            Layout.preferredWidth: 50
                            inputMask: ""
                            placeholderText: qsTr("0%")
                            onEditingFinished: {
                                if (text.length == 0)
                                    Julia.get_limit(nextItem(this, -2).text, "0")
                                else
                                    Julia.get_limit(nextItem(this, -2).text, text)
                            }
                        }

                        TextField {
                            enabled: false
                            Layout.preferredWidth: 70
                            inputMask: ""
                            placeholderText: qsTr("Wichtung")
                            onEditingFinished: {
                                if (text.length == 0)
                                    Julia.get_weight(nextItem(this, -3).text, "1")
                                else
                                    Julia.get_weight(nextItem(this, -3).text, text)
                            }
                        }
                    }
                }
            }

        }
            GroupBox {
                id: groupBox2
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
                title: "β + ec"

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: [ "H3", "C14", "Fe55", "Ni59", "Ni63", "Sr90", "Pu241" ]

                        RowLayout {
                            CheckBox {
                                text: modelData
                                Layout.preferredWidth: nuclide_name_length
                                onCheckedChanged: {
                                    for (var i=1; i<=3; i++) (checked == true) ? nextItem(this, i).enabled = true : nextItem(this, i).enabled = false;
                                    (checked == true) ? Julia.get_rel_nuc(text, nextItem(this, 1).currentText, nextItem(this, 2).text, nextItem(this, 3).text ) : Julia.rm_rel_nuc(text)
                                }
                            }

                            ComboBox {
                                enabled: false
                                Layout.preferredWidth: nuclide_name_length
                                model: ["NONE", "<=", "==", ">="]
                                onCurrentTextChanged: Julia.get_relation(nextItem(this, -1).text, currentText)
                            }

                            TextField {
                                enabled: false
                                Layout.preferredWidth: 50
                                inputMask: ""
                                placeholderText: qsTr("0%")
                                onEditingFinished: {
                                    if (text.length == 0)
                                        Julia.get_limit(nextItem(this, -2).text, "0")
                                    else
                                        Julia.get_limit(nextItem(this, -2).text, text)
                                }
                            }

                            TextField {
                                enabled: false
                                Layout.preferredWidth: 70
                                inputMask: ""
                                placeholderText: qsTr("Wichtung")
                                onEditingFinished: {
                                    if (text.length == 0)
                                        Julia.get_weight(nextItem(this, -3).text, "1")
                                    else
                                        Julia.get_weight(nextItem(this, -3).text, text)
                                }
                            }
                        }
                    }
                }

            }
            GroupBox {
                id: groupBox3
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: true
                title: "γ"

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.rightMargin: 0
                    Repeater {
                        model: [ ["Mn54", "Co57", "Co60", "Zn65", "Nb94", "Ru106", "Ag108m", "Ag110m"], ["Sb125", "Ba133", "Cs134", "Cs137", "Ce144", "Eu152", "Eu154", "Eu155", "∑γ"] ]
                        Column {

                            Repeater {
                                model: modelData

                                RowLayout {
                                    CheckBox {
                                        text: modelData
                                        Layout.preferredWidth: nuclide_name_length
                                        onCheckedChanged: {
                                            for (var i=1; i<=3; i++) (checked == true) ? nextItem(this, i).enabled = true : nextItem(this, i).enabled = false;
                                            (checked == true) ? Julia.get_rel_nuc(text, nextItem(this, 1).currentText, nextItem(this, 2).text, nextItem(this, 3).text ) : Julia.rm_rel_nuc(text)
                                        }
                                    }

                                    ComboBox {
                                        enabled: false
                                        Layout.preferredWidth: nuclide_name_length
                                        model: ["NONE", "<=", "==", ">="]
                                        onCurrentTextChanged: Julia.get_relation(nextItem(this, -1).text, currentText)
                                    }

                                    TextField {
                                        enabled: false
                                        Layout.preferredWidth: 50
                                        inputMask: ""
                                        placeholderText: qsTr("0%")
                                        onEditingFinished: {
                                            if (text.length == 0)
                                                Julia.get_limit(nextItem(this, -2).text, "0")
                                            else
                                                Julia.get_limit(nextItem(this, -2).text, text)
                                        }
                                    }

                                    TextField {
                                        enabled: false
                                        Layout.preferredWidth: 70
                                        inputMask: ""
                                        placeholderText: qsTr("Wichtung")
                                        onEditingFinished: {
                                            if (text.length == 0)
                                                Julia.get_weight(nextItem(this, -3).text, "1")
                                            else
                                                Julia.get_weight(nextItem(this, -3).text, text)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }
