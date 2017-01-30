import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0

GroupBox {
    id: shownv
    title: "Nuklidvektor"
    Layout.preferredWidth: area.width

    ColumnLayout {

       Component {
           id: columnComponent
           TableViewColumn { width: 60 }
       }

        TableView {
            id: view
            height: 400
            Layout.preferredWidth: area.width - 15
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            model: nuclidesModel

            function update_columns() {
                var savedModel = model;
                model = null; // avoid model updates during reset
                while(columnCount != 0) { // remove existing columns first
                    removeColumn(0);
                }
                addColumn(columnComponent.createObject(view, { "role": "name", "title": "Nuklid", "width": 100 }));
                for(var i=0; i<years.length; i++) {
                    var role = years[i]
                    addColumn(columnComponent.createObject(view, { "role": role, "title": role}))
                }
                model = savedModel;
            }

            // update on role change
            Connections {
                target: nuclidesModel
                onRolesChanged: view.update_columns()
            }

            // first time init
            Component.onCompleted: update_columns()
        }

    }

}
