import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import org.julialang 1.0
import "underscore.js" as Underscore


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

    property variant win_overestimation
    property variant win_clearance
    property variant win_decay
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

            ShowNV { id: shownv }

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

                    onClicked: {
                        if (Julia.sanity_check() == true) {
                          Julia.update_year_ListModel()
                          Julia.test_nv_gui("-1", 0)
                          var component = Qt.createComponent("Overestimation.qml")
                          win_overestimation = component.createObject(mainWindow)
                          win_overestimation.show()
                        }
                    }
                }

                Button {
                    id: clearance_Button
                    text: qsTr("Zeige Freigabewerte")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100

                    onClicked: {
                        if (Julia.sanity_check() == true) {
                          var component = Qt.createComponent("Clearance.qml")
                          win_clearance = component.createObject(mainWindow)
                          win_clearance.show()
                          Julia.clearance_gui()
                        }
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
                        win_decay = component.createObject(mainWindow)
                        win_decay.show()
                    }
                }

                MessageDialog {
                    id: sanity_popup
                    icon: StandardIcon.Warning
                    title: "Summe der Nuklide ergibt nicht 100%"
                    text: Qt._.contains(sanity_string, ",") ?
                    "Die Summe der Nuklide der Jahre " + sanity_string + " ergibt nicht 100%!" :
                    "Die Summe der Nuklide des Jahres " + sanity_string + " ergibt nicht 100%!"
                }
            }
        }
    }

    MessageDialog {
        id: isNumberFail_popup
        icon: StandardIcon.Warning
        text: "Eingabe ist keine gültige Zahl!"
      }

Component.onCompleted: Julia.update_year_ListModel()

     JuliaSignals {
         signal sanityFail()
         onSanityFail: sanity_popup.open()

         signal isNumberFail()
         onIsNumberFail: isNumberFail_popup.open()
     }
}
