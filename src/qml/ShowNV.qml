import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0
// import "TooltipCreator.js" as TooltipCreator

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
               while(columnCount != 0) { // remove existing columns first
                   removeColumn(0);
               }
               addColumn(columnComponent.createObject(view, { "role": "name", "title": "Nuklid", "width": 100 }));
               for(var i=0; i<years.length; i++) {
                   var role = years[i]
                   addColumn(columnComponent.createObject(view, { "role": role, "title": role}))
               }
           }

           onModelChanged: view.update_columns()

           itemDelegate: {
             return editableDelegate;
           }

           // first time init
           Component.onCompleted: update_columns()
       }

      //  ToolTip.create("Änderbar, um selbst eingetrage Nuklidvektoren auf Konservativität zu prüfen.", parent).show()

      //  ToolTip2 {
      //    id: tooltip1
      //    width: 200
      //    target: view
      //    text: "Änderbar, um selbst eingetrage Nuklidvektoren auf Konservativität zu prüfen."
      //    }

    }

    // editable TableView
    // code by http://stackoverflow.com/questions/23856114/in-qml-tableview-when-clicked-edit-a-data-like-excel
    Item {
        anchors.fill: parent

        Component {
            id: editableDelegate
            Item{

                Text {
                    width: parent.width
                    anchors.margins: 4
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    elide: styleData.elideMode
                    text: styleData.value !== undefined ? styleData.value : ""
                    visible: !styleData.selected
                }
                Loader {
                    id: loaderEditor
                    anchors.fill: parent
                    anchors.margins: 4
                    Connections {
                        target: loaderEditor.item
                        onEditingFinished: {
                            if (typeof styleData.value === 'number')
                                nuclidesModel.setProperty(styleData.row, styleData.role, Number(parseFloat(loaderEditor.item.text).toFixed(2)))
                            else
                                nuclidesModel.setProperty(styleData.row, styleData.role, loaderEditor.item.text)
                        }
                    }
                    sourceComponent: styleData.selected ? editor : null
                    Component {
                        id: editor
                        TextInput {
                            id: textinput
                            color: styleData.textColor
                            text: styleData.value
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: textinput.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }
    }
}
