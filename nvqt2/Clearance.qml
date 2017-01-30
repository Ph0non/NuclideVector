import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0

Window {
    width: 800
    height: 400
    title: "Freigabewerte"
    id: clearance

    MouseArea {
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0
        anchors.fill: parent

        Column {
            Button {
                text: qsTr("Kopiere in Zwischenablage")
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredHeight: 40
                Layout.preferredWidth: 100

                onClicked: Julia.copy2clipboard_clearance()
            }

            TableView {
                id: view_clearance
                height: 350
                width: 780
                model: clearanceModel

                function update_columns() {
                    while(columnCount != 0) { // remove existing columns first
                        removeColumn(0);
                    }
                    addColumn(columnComponent.createObject(view_clearance, { "role": "name", "title": "Pfad", "width": 100 }));
                    for(var i=0; i<years_clearance.length; i++) {
                        var role = years_clearance[i]
                        addColumn(columnComponent.createObject(view_clearance, { "role": role, "title": role}))
                    }
                }

                 onModelChanged: view_clearance.update_columns()


            }

            Component
            {
                id: columnComponent_clearance
                TableViewColumn { width: 60 }
            }
        }
    }
}

