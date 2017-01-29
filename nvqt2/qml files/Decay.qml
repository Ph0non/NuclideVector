import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0
import "underscore.js" as Underscore

Window {
    width: 800
    height: 600
    title: "Zerfallskorrektur"
    id: decay

    MouseArea {
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0
        anchors.fill: parent


        Column {
            RowLayout {
                ComboBox {
                    id: decay_CB_year
                    //model: Qt._.range(parseInt(year1_ctx), parseInt(year2_ctx))
                    model: ListModel {
                        id: year_items

                    }
                    Component.onCompleted: {year_items.append({"text": "2016"})}

                    onCurrentIndexChanged: Julia.decay_gui( decay_CB_year.currentText, decay_check_rel_nuc.checked )
                }
                CheckBox {
                    id: decay_check_rel_nuc
                    text: "Nur relevante Nuklide anzeigen"
                    onCheckedChanged: Julia.decay_gui( decay_CB_year.currentText, decay_check_rel_nuc.checked )
                }
            }

            Text {
                text: "Anteile in Prozent"
            }

            TableView {
                id: view_decay
                height: 550
                width: 780
                model: decayModel

                resources:
                {
                    var columns = []
                    columns.push(columnComponent_decay.createObject(view_decay, { "role": "name", "title": "Nuklid", "width": 80 }))
                    for(var i=0; i<samples_row.length; i++)
                    {
                        var role  = samples_row[i]
                        columns.push(columnComponent_decay.createObject(view_decay, { "role": role, "title": role}))
                    }
                    return columns
                }
            }

            Component
            {
                id: columnComponent_decay
                TableViewColumn { width: 60 }
            }

        }
    }
}

