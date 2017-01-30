import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.julialang 1.0


ApplicationWindow {
    visible: true
    width: 1200
    height: 700
    title: qsTr("Nuklidvektor berechnen")
    id: mainWindow

    function itemIndex(item) {
        if (item.parent === null)
            return -1
        var siblings = item.parent.children
        for (var i = 0; i<= siblings.length; i++)
            if (siblings[i] === item)
                return i
        return -1
    }
    function nextItem(item, offset) {
        if (item.parent === null)
            return null

        var index = itemIndex(item)
        var siblings = item.parent.children

        //return (index < siblings.length -1) ? siblings[index + offset] : null
        return siblings[index + offset]
    }
    function firstItem(item) {
        if (item.parent === null)
            return null

        var index = itemIndex(item)
        var siblings = item.parent.children

        //return (index < siblings.length -1) ? siblings[index + offset] : null
        return siblings[0]
    }

    property variant win
    property variant win2
    property variant win3
    property int nuclide_name_length: 70

    MouseArea {
        id: area
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0
        anchors.fill: parent

        /////////////////////////////////////
        //       HERE COMES THE CODE       //
        /////////////////////////////////////

        ColumnLayout {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 0
            spacing: 0

            //////////////////////////////////////
            ///// General ////////////////////////
            //////////////////////////////////////

            General {id:general }

            //////////////////////////////////////
            ///// Constraints ////////////////////
            //////////////////////////////////////

            Constraints { id: constraints }

            //////////////////////////////////////
            ///// show NV ////////////////////////
            //////////////////////////////////////

           // ShowNV { id: shownv }

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


                        // first time init
                        Component.onCompleted: update_columns()
                    }

                }

            }

            //////////////////////////////////////
            ///// Overestimation /////////////////
            //////////////////////////////////////

            Overestimation { id: overestimation }

            //////////////////////////////////////
            ///// Decay //////////////////////////
            //////////////////////////////////////

            Decay {id: decay}

            //////////////////////////////////////
            ///// Clearance //////////////////////
            //////////////////////////////////////

            Clearance {id: clearance}

            Row{
                Button {
                    text: qsTr("Berechnen")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    enabled: start_cal_ctx_button
                    onClicked: {
                        Julia.start_nv_calc()
                        overestimation_Button.enabled = true
                        clearance_Button.enabled = true
                        nv_clipboard.enabled = true
                    }
                }

                Button {
                    id: nv_clipboard
                    text: qsTr("Kopiere in Zwischenablage")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    enabled: false
                    onClicked: {
                        Julia.copy2clipboard_nv()
                    }
                }


                Button {
                    id: overestimation_Button
                    text: qsTr("Zeige Überschätzung")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    enabled: false
                    onClicked: {
                        var component = Qt.createComponent("Overestimation.qml")
                        win = component.createObject(mainWindow)
                        win.show()
                        Julia.test_nv_gui("2016", 0)
                    }
                }

                Button {
                    id: clearance_Button
                    text: qsTr("Zeige Freigabewerte")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    enabled: false
                    onClicked: {
                        var component = Qt.createComponent("Clearance.qml")
                        win = component.createObject(mainWindow)
                        win.show()
                        Julia.clearance_gui()
                    }
                }

                Button {
                    text: qsTr("Zeige Zerfallskorrektur")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    onClicked: {
                        Julia.decay_gui( "2016", false )
                        var component = Qt.createComponent("Decay.qml")
                        win2 = component.createObject(mainWindow)
                        win2.show()
                    }
                }
            }
        }

    }

    //    JuliaSignals {
    //        signal killColumn(int column_val)
    //        onKillColumn: view.removeColumn(column_val)
    //    }

}
