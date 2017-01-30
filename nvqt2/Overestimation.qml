import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0

Window {
    width: 800
    height: 600
    title: "Überschätzung"
    id: overestimation

    MouseArea {
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0
        anchors.fill: parent


        Column {
            Row {
                ComboBox {
                    id: overestimation_CB_year
                    model: years_model
                    onCurrentIndexChanged: Julia.test_nv_gui( overestimation_CB_year.currentText, overestimation_CB_fmx.currentIndex )
                }
                ComboBox {
                    id: overestimation_CB_fmx
                    model: ["Freimessanlage", "Freimessbereich", "in-situ"]
                    onCurrentIndexChanged: Julia.test_nv_gui( overestimation_CB_year.currentText, overestimation_CB_fmx.currentIndex )
                }

                Button {
                    text: qsTr("Kopiere in Zwischenablage")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    onClicked: Julia.copy2clipboard_testnv(overestimation_CB_year.currentText)
                }
            }

            Text {
                text: "01.01." + overestimation_CB_year.currentText
            }

            TableView {
                id: view_overestimate1
                height: 250
                width: 780
                model: sampleModel

                function update_columns() {
                    while(columnCount != 0) { // remove existing columns first
                        removeColumn(0);
                    }
                    addColumn(columnComponent.createObject(view_overestimate1, { "role": "name", "title": "Probe", "width": 80 }));
                    for(var i=0; i<fmx_row.length; i++) {
                        var role = fmx_row[i]
                        addColumn(columnComponent.createObject(view_overestimate1, { "role": role, "title": role}))
                    }
                }

                onModelChanged: view_overestimate1.update_columns()

            }

            Component
            {
                id: columnComponent_overestimate1
                TableViewColumn { width: 60 }
            }


            Text {
                text: "31.12." + overestimation_CB_year.currentText
            }

            TableView {
                id: view_overestimate2
                height: 250
                width: 780
                model: sampleModel_eoy

                function update_columns() {
                    while(columnCount != 0) { // remove existing columns first
                        removeColumn(0);
                    }
                    addColumn(columnComponent.createObject(view_overestimate2, { "role": "name", "title": "Probe", "width": 80 }));
                    for(var i=0; i<fmx_row.length; i++) {
                        var role = fmx_row[i]
                        addColumn(columnComponent.createObject(view_overestimate2, { "role": role, "title": role}))
                    }
                }

                onModelChanged: view_overestimate2.update_columns()
            }

            Component
            {
                id: columnComponent_overestimate2
                TableViewColumn { width: 60 }
            }
        }

    }
}
