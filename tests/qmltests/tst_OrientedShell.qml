/*
 * Copyright (C) 2015-2017 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtTest 1.0
import GSettings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Unity.Application 0.1
import Unity.Test 0.1
import LightDMController 0.1
import LightDM.FullLightDM 0.1 as LightDM
import Powerd 0.1
import Unity.InputInfo 0.1
import Utils 0.1

import "../../qml"
import "../../qml/Components"
import "../../qml/Components/PanelState"
import "Stage"

Rectangle {
    id: root
    color: "grey"
    width:  units.gu(160) + controls.width
    height: units.gu(100)

    property var tryShell: null
    property string ldmUserMode: "single"

    Binding {
        target: LightDMController
        property: "userMode"
        value: ldmUserMode
    }

    QtObject {
        id: applicationArguments
        property string deviceName: "mako"
        property string mode: "full-greeter"
    }

    QtObject {
        id: mockOrientationLock
        property int savedOrientation
    }

    GSettings {
        id: unity8Settings
        schema.id: "com.canonical.Unity8"
        onUsageModeChanged: {
            usageModeSelector.selectedIndex = usageModeSelector.model.indexOf(usageMode)
        }
    }

    GSettings {
        id: oskSettings
        schema.id: "com.canonical.keyboard.maliit"
    }

    InputDeviceModel {
        id: miceModel
        deviceFilter: InputInfo.Mouse
    }
    InputDeviceModel {
        id: touchpadModel
        deviceFilter: InputInfo.TouchPad
    }
    InputDeviceModel {
        id: keyboardsModel
        deviceFilter: InputInfo.Keyboard
    }

    property int physicalOrientation0
    property int physicalOrientation90
    property int physicalOrientation180
    property int physicalOrientation270
    property real primaryOrientationAngle

    state: applicationArguments.deviceName
    states: [
        State {
            name: "mako"
            PropertyChanges {
                target: shellRect
                width: units.gu(40)
                height: units.gu(71)
            }
            PropertyChanges {
                target: root
                physicalOrientation0: Qt.PortraitOrientation
                physicalOrientation90: Qt.InvertedLandscapeOrientation
                physicalOrientation180: Qt.InvertedPortraitOrientation
                physicalOrientation270: Qt.LandscapeOrientation
                primaryOrientationAngle: 0
            }
        },
        State {
            name: "manta"
            PropertyChanges {
                target: shellRect
                width: units.gu(160)
                height: units.gu(60)
            }
            PropertyChanges {
                target: root
                physicalOrientation90: Qt.PortraitOrientation
                physicalOrientation180: Qt.InvertedLandscapeOrientation
                physicalOrientation270: Qt.InvertedPortraitOrientation
                physicalOrientation0: Qt.LandscapeOrientation
                primaryOrientationAngle: 0
            }
        },
        State {
            name: "flo"
            PropertyChanges {
                target: shellRect
                width: units.gu(60)
                height: units.gu(100)
            }
            PropertyChanges {
                target: root
                physicalOrientation270: Qt.PortraitOrientation
                physicalOrientation0: Qt.InvertedLandscapeOrientation
                physicalOrientation90: Qt.InvertedPortraitOrientation
                physicalOrientation180: Qt.LandscapeOrientation
                primaryOrientationAngle: 90
            }
        },
        State {
            name: "desktop"
            PropertyChanges {
                target: shellRect
                width: units.gu(100)
                height: units.gu(65)
            }
            PropertyChanges {
                target: root
                physicalOrientation270: Qt.InvertedPortraitOrientation
                physicalOrientation0:  Qt.LandscapeOrientation
                physicalOrientation90: Qt.PortraitOrientation
                physicalOrientation180: Qt.InvertedLandscapeOrientation
                primaryOrientationAngle: 0
            }
        }
    ]

    Component {
        id: shellComponent
        OrientedShell {
            anchors.fill: parent
            physicalOrientation: root.physicalOrientation0
            orientationLocked: orientationLockedCheckBox.checked
            orientationLock: mockOrientationLock
            lightIndicators: true
        }
    }

    Rectangle {
        id: shellRect
        color: "black"
        x: ((root.width - controls.width) - width) / 2
        y: (root.height - height) / 2
    }

    function orientationsToStr(orientations) {
        if (orientations === Qt.PrimaryOrientation) {
            return "Primary";
        } else {
            var str = "";
            if (orientations & Qt.PortraitOrientation) {
                str += " Portrait";
            }
            if (orientations & Qt.InvertedPortraitOrientation) {
                str += " InvertedPortrait";
            }
            if (orientations & Qt.LandscapeOrientation) {
                str += " Landscape";
            }
            if (orientations & Qt.InvertedLandscapeOrientation) {
                str += " InvertedLandscape";
            }
            return str;
        }
    }

    Rectangle {
        width: controls.width
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        color: "darkgrey"
    }
    Flickable {
        id: controls
        width: units.gu(30)
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        boundsBehavior: Flickable.StopAtBounds
        contentHeight: controlsColumn.height

        Column {
            id: controlsColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)

            Button {
                text: "Load shell"
                onClicked: {
                    createTryShell();
                }
            }

            Button {
                text: "Show Greeter"
                activeFocusOnPress: false
                onClicked: {
                    if (tryShell === null)
                        return;

                    LightDM.Greeter.showGreeter();
                }
            }


            Label {
                text: "LightDM mock mode"
            }

            ListItem.ItemSelector {
                anchors { left: parent.left; right: parent.right }
                activeFocusOnPress: false
                model: ["single", "single-passphrase", "single-pin", "full"]
                onSelectedIndexChanged: {
                    testCase.tearDown();
                    ldmUserMode = model[selectedIndex];
                    testCase.init();
                }
            }

            Label {
                text: "Physical Orientation:"
            }
            Button {
                id: rotate0Button
                text: root.orientationsToStr(root.physicalOrientation0) + " (0)"
                activeFocusOnPress: false
                onClicked: rotate0(tryShell)
                color: tryShell && tryShell.physicalOrientation === root.physicalOrientation0 ?
                                                                                                    UbuntuColors.green :
                                                                                                    __styleInstance.defaultColor
            }
            Button {
                id: rotate90Button
                text: root.orientationsToStr(root.physicalOrientation90) + " (90)"
                activeFocusOnPress: false
                onClicked: rotate90(tryShell)
                color: tryShell && tryShell.physicalOrientation === root.physicalOrientation90 ?
                                                                                                     UbuntuColors.green :
                                                                                                     __styleInstance.defaultColor
            }
            Button {
                id: rotate180Button
                text: root.orientationsToStr(root.physicalOrientation180) + " (180)"
                activeFocusOnPress: false
                onClicked: rotate180(tryShell)
                color: tryShell && tryShell.physicalOrientation === root.physicalOrientation180 ?
                                                                                                      UbuntuColors.green :
                                                                                                      __styleInstance.defaultColor
            }
            Button {
                id: rotate270Button
                text: root.orientationsToStr(root.physicalOrientation270) + " (270)"
                activeFocusOnPress: false
                onClicked: rotate270(tryShell)
                color: tryShell && tryShell.physicalOrientation === root.physicalOrientation270 ?
                                                                                                      UbuntuColors.green :
                                                                                                      __styleInstance.defaultColor
            }
            RowLayout {
                Layout.fillWidth: true
                CheckBox {
                    id: orientationLockedCheckBox
                    checked: false
                    activeFocusOnPress: false
                }
                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Orientation Locked"
                }
            }
            Button {
                text: "Power dialog"
                activeFocusOnPress: false
                onClicked: { testCase.showPowerDialog(tryShell); }
            }
            ListItem.ItemSelector {
                id: deviceNameSelector
                anchors { left: parent.left; right: parent.right }
                activeFocusOnPress: false
                text: "Device Name"
                model: ["mako", "manta", "flo", "desktop"]
                onSelectedIndexChanged: {
                    destroyShell();
                    applicationArguments.deviceName = model[selectedIndex];
                    createTryShell();
                }
            }
            ListItem.ItemSelector {
                id: usageModeSelector
                anchors { left: parent.left; right: parent.right }
                activeFocusOnPress: false
                text: "Usage Mode"
                model: ["Staged", "Windowed", "Automatic"]
                function selectStaged() {selectedIndex = 0;}
                function selectWindowed() {selectedIndex = 1;}
                function selectAutomatic() {selectedIndex = 2;}
                onSelectedIndexChanged: {
                    GSettingsController.setUsageMode(usageModeSelector.model[usageModeSelector.selectedIndex]);
                }
            }
            MouseTouchEmulationCheckbox {
                checked: true
                color: "white"
            }
            Button {
                text: "Switch fullscreen"
                activeFocusOnPress: false
                onClicked: {
                    var app = ApplicationManager.findApplication(ApplicationManager.focusedApplicationId);
                    app.fullscreen = !app.fullscreen;
                }
            }
            RowLayout {
                Layout.fillWidth: true
                CheckBox {
                    checked: false
                    activeFocusOnPress: false
                    onCheckedChanged: {
                        var surface = SurfaceManager.inputMethodSurface;
                        if (checked) {
                            surface.setState(Mir.RestoredState);
                        } else {
                            surface.setState(Mir.MinimizedState);
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Input Method"
                }
            }

            Button {
                text: Powerd.status === Powerd.On ? "Display ON" : "Display OFF"
                activeFocusOnPress: false
                onClicked: {
                    if (Powerd.status === Powerd.On) {
                        Powerd.setStatus(Powerd.Off, Powerd.Unknown);
                    } else {
                        Powerd.setStatus(Powerd.On, Powerd.Unknown);
                    }
                }
            }

            Row {
                Button {
                    text: "Add mouse"
                    activeFocusOnPress: false
                    onClicked: {
                        MockInputDeviceBackend.addMockDevice("/mouse" + miceModel.count, InputInfo.Mouse)
                    }
                }
                Button {
                    text: "Remove mouse"
                    activeFocusOnPress: false
                    onClicked: {
                        MockInputDeviceBackend.removeDevice("/mouse" + (miceModel.count - 1))
                    }
                }
            }
            Row {
                Button {
                    text: "Add touchpad"
                    activeFocusOnPress: false
                    onClicked: {
                        MockInputDeviceBackend.addMockDevice("/touchpad" + touchpadModel.count, InputInfo.TouchPad)
                    }
                }
                Button {
                    text: "Remove touchpad"
                    activeFocusOnPress: false
                    onClicked: {
                        MockInputDeviceBackend.removeDevice("/touchpad" + (touchpadModel.count - 1))
                    }
                }
            }

            Row {
                Button {
                    text: "Add kbd"
                    activeFocusOnPress: false
                    onClicked: {
                        MockInputDeviceBackend.addMockDevice("/kbd" + keyboardsModel.count, InputInfo.Keyboard)
                    }
                }
                Button {
                    activeFocusOnPress: false
                    text: "Remove kbd"
                    onClicked: {
                        MockInputDeviceBackend.removeDevice("/kbd" + (keyboardsModel.count - 1))
                    }
                }
            }

            // Simulates what happens when the shell is moved to an external monitor and back
            Button {
                id: moveToFromMonitorButton
                text: applicationArguments.deviceName === "desktop" ? "Move to " + prevDevName + " screen" : "Move to desktop screen"
                activeFocusOnPress: false
                property string prevDevName: "mako"
                onClicked: {
                    usageModeSelector.selectAutomatic();

                    if (applicationArguments.deviceName === "desktop") {
                        applicationArguments.deviceName = prevDevName;
                    } else {
                        prevDevName = applicationArguments.deviceName;
                        applicationArguments.deviceName = "desktop"
                    }
                }
            }

            SurfaceManagerControls { }
        }
    }

    function createTryShell() {
        if (root.tryShell === null) {
            root.tryShell = shellComponent.createObject(shellRect);
        }
    }

    function destroyShell() {
        if (root.tryShell === null) {
            return;
        }
        tryShell.destroy();
        testCase.wait(100); // Need to wait for things like the SurfaceManager to be destroyed

        testCase.tearDown();
    }

    function rotate0(orientedShell) {
        orientedShell.physicalOrientation = root.physicalOrientation0;
    }

    function rotate90(orientedShell) {
        orientedShell.physicalOrientation = root.physicalOrientation90;
    }

    function rotate180(orientedShell) {
        orientedShell.physicalOrientation = root.physicalOrientation180;
    }

    function rotate270(orientedShell) {
        orientedShell.physicalOrientation = root.physicalOrientation270;
    }

    UnityTestCase {
        id: testCase
        name: "OrientedShell"
        when: windowShown

        SignalSpy { id: signalSpy }
        SignalSpy { id: signalSpy2 }

        Connections {
            id: appRepeaterConnections
            ignoreUnknownSignals : true
            property var itemAddedCallback: null
            onItemAdded: {
                if (itemAddedCallback) {
                    itemAddedCallback(item);
                }
            }
        }

        function init() {
            while (miceModel.count > 0)
                MockInputDeviceBackend.removeDevice("/mouse" + (miceModel.count - 1));
            while (touchpadModel.count > 0)
                MockInputDeviceBackend.removeDevice("/touchpad" + (touchpadModel.count - 1));
            while (keyboardsModel.count > 0)
                MockInputDeviceBackend.removeDevice("/kbd" + (keyboardsModel.count - 1))
            usageModeSelector.selectStaged();
        }

        function tearDown() {
            // kill all (fake) running apps
            testCase.killApps();
            LightDM.Greeter.authenticate(""); // reset greeter
        }

        function cleanup() {
            appRepeaterConnections.target = null;
            appRepeaterConnections.itemAddedCallback = null;
            signalSpy.target = null;
            signalSpy.signalName = "";

            tearDown();
        }

        function test_appSupportingOnlyPrimaryOrientationMakesPhoneShellStayPut() {
            var orientedShell = loadShell("mako");
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            var shell = findChild(orientedShell, "shell");

            var primarySurfaceId = topLevelSurfaceList.nextId;
            var primaryApp = ApplicationManager.startApplication("primary-oriented-app");
            verify(primaryApp);
            waitUntilAppWindowIsFullyLoaded(primarySurfaceId, orientedShell);

            var primaryAppWindow = findAppWindowForSurfaceId(primarySurfaceId, orientedShell);
            verify(primaryAppWindow)
            var primaryDelegate = findChild(shell, "appDelegate_" + primarySurfaceId);

            compare(primaryDelegate.focus, true);
            compare(primaryApp.rotatesWindowContents, false);
            compare(primaryApp.supportedOrientations, Qt.PrimaryOrientation);

            tryVerify(function(){return primaryDelegate.surface});
            verify(checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle, orientedShell));

            compare(shell.transformRotationAngle, root.primaryOrientationAngle);
            rotateTo(90, orientedShell);

            verify(checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle, orientedShell));
            compare(shell.transformRotationAngle, root.primaryOrientationAngle);

            rotateTo(180, orientedShell);

            verify(checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle, orientedShell));
            compare(shell.transformRotationAngle, root.primaryOrientationAngle);

            rotateTo(270, orientedShell);

            verify(checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle, orientedShell));
            compare(shell.transformRotationAngle, root.primaryOrientationAngle);
        }

        function test_appSupportingOnlyPrimaryOrientationWillOnlyRotateInLandscape_data() {
            return [
                {tag: "manta", deviceName: "manta"},
                {tag: "flo", deviceName: "flo"}
            ];
        }
        function test_appSupportingOnlyPrimaryOrientationWillOnlyRotateInLandscape(data) {
            var orientedShell = loadShell(data.deviceName);
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");

            var primarySurfaceId = topLevelSurfaceList.nextId;
            var primaryApp = ApplicationManager.startApplication("primary-oriented-app");
            verify(primaryApp);
            waitUntilAppWindowIsFullyLoaded(primarySurfaceId, orientedShell);

            var primaryAppWindow = findAppWindowForSurfaceId(primarySurfaceId, orientedShell);
            verify(primaryAppWindow)

            // primary-oriented-app supports only primary orientation

            compare(ApplicationManager.focusedApplicationId, "primary-oriented-app");
            compare(primaryApp.rotatesWindowContents, false);
            compare(primaryApp.supportedOrientations, Qt.PrimaryOrientation);
            var primaryDelegate = findChild(shell, "appDelegate_" + primarySurfaceId);
            compare(primaryDelegate.stage, ApplicationInfoInterface.MainStage);

            tryCompareFunction(function(){return primaryApp.surfaceList.count > 0;}, true);

            tryCompareFunction(function(){return checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle, orientedShell)}, true);
            compare(shell.transformRotationAngle, root.primaryOrientationAngle);

            rotateTo(90, orientedShell);

            tryCompareFunction(function(){return checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle, orientedShell)}, true);
            compare(shell.transformRotationAngle, root.primaryOrientationAngle);

            rotateTo(180, orientedShell);

            tryCompareFunction(function(){return checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle + 180, orientedShell)}, true);
            compare(shell.transformRotationAngle, root.primaryOrientationAngle + 180);

            rotateTo(270, orientedShell);

            tryCompareFunction(function(){return checkAppSurfaceOrientation(primaryAppWindow, primaryApp, root.primaryOrientationAngle + 180, orientedShell)}, true);
            compare(shell.transformRotationAngle, root.primaryOrientationAngle + 180);
        }

        function test_appRotatesWindowContents_data() {
            return [
                {tag: "mako", deviceName: "mako", orientationAngleAfterRotation: 90},
                {tag: "mako_windowed", deviceName: "mako", orientationAngleAfterRotation: 90, windowed: true},
                {tag: "manta", deviceName: "manta", orientationAngleAfterRotation: 90},
                {tag: "manta_windowed", deviceName: "manta", orientationAngleAfterRotation: 90, windowed: true},
                {tag: "flo", deviceName: "flo", orientationAngleAfterRotation: 180},
                {tag: "flo_windowed", deviceName: "flo", orientationAngleAfterRotation: 180, windowed: true}
            ];
        }
        function test_appRotatesWindowContents(data) {
            var orientedShell = loadShell(data.deviceName);
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");

            if (data.windowed) {
                usageModeSelector.selectWindowed();
            } else {
                usageModeSelector.selectStaged();
            }

            var cameraSurfaceId = topLevelSurfaceList.nextId;
            var cameraApp = ApplicationManager.startApplication("camera-app");
            verify(cameraApp);
            tryVerify(function() {return cameraApp.surfaceList.get(0)});
            var cameraSurface = cameraApp.surfaceList.get(0);

            // ensure the mock camera-app is as we expect
            tryCompare(cameraSurface, "state", Mir.FullscreenState, 1000);
            compare(cameraApp.rotatesWindowContents, true);
            compare(cameraApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);

            waitUntilAppWindowIsFullyLoaded(cameraSurfaceId, orientedShell);

            var focusChangedSpy = signalSpy;
            focusChangedSpy.clear();
            focusChangedSpy.target = cameraSurface;
            focusChangedSpy.signalName = "activeFocusChanged";
            verify(focusChangedSpy.valid);

            verify(cameraSurface.activeFocus);

            tryCompare(shell, "orientationChangesEnabled", true);

            var rotationStates = findInvisibleChild(orientedShell, "rotationStates");
            verify(rotationStates);
            var immediateTransition = null
            for (var i = 0; i < rotationStates.transitions.length && !immediateTransition; ++i) {
                var transition = rotationStates.transitions[i];
                if (transition.objectName == "immediateTransition") {
                    immediateTransition = transition;
                }
            }
            verify(immediateTransition);
            var transitionSpy = signalSpy2;
            transitionSpy.clear();
            transitionSpy.target = immediateTransition;
            transitionSpy.signalName = "runningChanged";
            verify(transitionSpy.valid);

            rotateTo(90, orientedShell);

            tryCompare(cameraSurface, "orientationAngle", data.orientationAngleAfterRotation);

            // the rotation should have been immediate
            // false -> true -> false
            compare(transitionSpy.count, 2);

            if (!data.windowed) { // subject to shell-chrome policies
                // It should retain native dimensions regardless of its rotation/orientation
                tryCompare(cameraSurface, "width", orientedShell.width);
                tryCompare(cameraSurface, "height", orientedShell.height);
            }

            // Surface focus shouldn't have been touched because of the rotation
            compare(focusChangedSpy.count, 0);
        }

        /*
            Preconditions:
            Shell orientation angle matches the screen one.

            Use case:
            User switches to an app that has an orientation angle different from the
            shell one but that also happens to support the current shell orientation
            angle.

            Expected outcome:
            The app should get rotated to match shell's orientation angle
         */
        function test_switchingToAppWithDifferentRotation_data() {
            return [
                {tag: "mako", deviceName: "mako", shellAngleAfterRotation: 90},
                {tag: "manta", deviceName: "manta", shellAngleAfterRotation: 90},
                {tag: "flo", deviceName: "flo", shellAngleAfterRotation: 180}
            ];
        }
        function test_switchingToAppWithDifferentRotation(data) {
            var orientedShell = loadShell(data.deviceName);
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");
            var gmailSurfaceId = topLevelSurfaceList.nextId;
            var gmailApp = ApplicationManager.startApplication("gmail-webapp");
            verify(gmailApp);

            // ensure the mock gmail-webapp is as we expect
            compare(gmailApp.rotatesWindowContents, false);
            compare(gmailApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);

            waitUntilAppWindowIsFullyLoaded(gmailSurfaceId, orientedShell);

            var musicSurfaceId = topLevelSurfaceList.nextId;
            var musicApp = ApplicationManager.startApplication("music-app");
            verify(musicApp);

            // ensure the mock music-app is as we expect
            compare(musicApp.rotatesWindowContents, false);
            compare(musicApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);
            if (data.deviceName === "manta" || data.deviceName === "flo") {
                var musicDelegate = findChild(shell, "appDelegate_" + musicSurfaceId);
                compare(musicDelegate.stage, ApplicationInfoInterface.MainStage);
            }

            waitUntilAppWindowIsFullyLoaded(musicSurfaceId, orientedShell);
            tryCompare(shell, "orientationChangesEnabled", true);

            rotateTo(90, orientedShell);
            tryCompare(shell, "transformRotationAngle", data.shellAngleAfterRotation);

            performEdgeSwipeToSwitchToPreviousApp(orientedShell);

            tryCompare(shell, "mainAppWindowOrientationAngle", data.shellAngleAfterRotation);
            compare(shell.transformRotationAngle, data.shellAngleAfterRotation);
        }

        /*
            Preconditions:
            - Device supports portrait, landscape and inverted-landscape

            Steps:
            1 - Launch app that supports all orientations
            2 - Rotate device to inverted-landscape
            3 - See that shell gets rotated to inverted-landscape accordingly
            4 - Rotate device to inverted-portrait

            Expected outcome:
            Shell stays at inverted-landscape

            Actual outcome:
            Shell rotates to landscape

            Comments:
            Rationale being that shell should be rotated to the closest supported orientation.
            In that case, landscape and inverted-landscape are both 90 degrees away from the physical
            orientation (Screen.orientation), so they are both equally good alternatives
         */
        function test_rotateToUnsupportedDeviceOrientation(data) {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");
            var twitterSurfaceId = topLevelSurfaceList.nextId;
            var twitterApp = ApplicationManager.startApplication("twitter-webapp");
            verify(twitterApp);

            // ensure the mock twitter-webapp is as we expect
            compare(twitterApp.rotatesWindowContents, false);
            compare(twitterApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);

            waitUntilAppWindowIsFullyLoaded(twitterSurfaceId, orientedShell);

            rotateTo(data.rotationAngle, orientedShell);
            tryCompare(shell, "transformRotationAngle", data.rotationAngle);

            rotateTo(180, orientedShell);
            tryCompare(shell, "transformRotationAngle", data.rotationAngle);
        }
        function test_rotateToUnsupportedDeviceOrientation_data() {
            return [
                {tag: "90", rotationAngle: 90},
                {tag: "270", rotationAngle: 270}
            ];
        }

        function test_launchLandscapeOnlyAppFromPortrait() {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            var weatherSurfaceId = topLevelSurfaceList.nextId;
            var weatherApp = ApplicationManager.startApplication("ubuntu-weather-app");
            verify(weatherApp);

            // ensure the mock app is as we expect
            compare(weatherApp.supportedOrientations, Qt.LandscapeOrientation | Qt.InvertedLandscapeOrientation);

            waitUntilAppWindowIsFullyLoaded(weatherSurfaceId, orientedShell);

            var rotationStates = findInvisibleChild(orientedShell, "rotationStates");
            waitUntilTransitionsEnd(rotationStates);

            tryCompareFunction(function (){return shell.transformRotationAngle === 90
                                               || shell.transformRotationAngle === 270;}, true);
        }

        /*
            - launch an app that only supports the primary orientation
            - launch an app that supports all orientations, such as twitter-webapp
            - wait a bit until that app is considered to have finished initializing and is thus
              ready to get resized/rotated
            - switch back to previous app (only supporting primary
            - rotate device to 90 degrees
            - Physical orientation is 90 but Shell orientation is kept at 0 because the app
              doesn't support such orientation
            - do a long right-edge drag to show the apps spread
            - tap on twitter-webapp

            Shell will rotate to match the physical orientation.

            This is a kind of tricky case as there are a few things happening at the same time:
              1 - Stage switching from apps spread (phase 2) to showing the focused app (phase 0)
              2 - orientation and aspect ratio (ie size) changes

            This may trigger some corner case bugs. such as one were
            the greeter is not kept completely outside the shell, causing the black rect in Shell.qml
            have an opacity > 0.
         */
        function test_greeterStaysAwayAfterRotation() {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");

            // Load an app which only supports primary
            var primarySurfaceId = topLevelSurfaceList.nextId;
            var primaryApp = ApplicationManager.startApplication("primary-oriented-app");
            verify(primaryApp);
            waitUntilAppWindowIsFullyLoaded(primarySurfaceId, orientedShell);

            var twitterSurfaceId = topLevelSurfaceList.nextId;
            var twitterApp = ApplicationManager.startApplication("twitter-webapp");
            verify(twitterApp);

            // ensure the mock twitter-webapp is as we expect
            compare(twitterApp.rotatesWindowContents, false);
            compare(twitterApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);

            waitUntilAppWindowIsFullyLoaded(twitterSurfaceId, orientedShell);
            waitUntilAppWindowCanRotate(twitterSurfaceId, orientedShell);

            // go back to primary-oriented-app
            performEdgeSwipeToSwitchToPreviousApp(orientedShell);

            rotateTo(90, orientedShell);
            wait(1); // spin the event loop to let all bindings do their thing
            tryCompare(shell, "transformRotationAngle", 0);

            performEdgeSwipeToShowAppSpread(shell);

            // wait until things have settled
            var greeter = findChild(shell, "greeter");
            tryCompare(greeter, "animating", false);

            var twitterDelegate = findChild(shell, "appDelegate_" + topLevelSurfaceList.idAt(1));
            compare(twitterDelegate.application.appId, "twitter-webapp");
            tap(twitterDelegate, 1, 1);

            // now it should finally follow the physical orientation
            tryCompare(shell, "transformRotationAngle", 90);

            // greeter should remaing completely hidden
            tryCompare(greeter, "shown", false);
        }

        function test_appInSideStageDoesntRotateOnStartUp_data() {
            return [
                {tag: "manta", deviceName: "manta"},
                {tag: "flo", deviceName: "flo"}
            ];
        }
        function test_appInSideStageDoesntRotateOnStartUp(data) {
            WindowStateStorage.saveStage("twitter-webapp", ApplicationInfoInterface.SideStage)
            var orientedShell = loadShell(data.deviceName);
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");

            var twitterSurfaceId = topLevelSurfaceList.nextId;
            var twitterApp = ApplicationManager.startApplication("twitter-webapp");
            verify(twitterApp);
            var twitterDelegate = findChild(shell, "appDelegate_" + twitterSurfaceId);
            compare(twitterDelegate.stage, ApplicationInfoInterface.SideStage);

            // ensure the mock twitter-webapp is as we expect
            compare(twitterApp.rotatesWindowContents, false);
            compare(twitterApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);

            tryCompare(twitterDelegate, "orientationChangesEnabled", true);

            var decoratedWindow = findChild(twitterDelegate, "decoratedWindow");
            verify(decoratedWindow);
            tryCompare(decoratedWindow, "counterRotate", false);

            // no reason for any rotation animation to have taken place
            compare(signalSpy.count, 0);
        }

        function test_portraitOnlyAppInSideStage_data() {
            return [
                {tag: "manta", deviceName: "manta"},
                {tag: "flo", deviceName: "flo"}
            ];
        }
        function test_portraitOnlyAppInSideStage(data) {
            var orientedShell = loadShell(data.deviceName);
            var shell = findChild(orientedShell, "shell");

            var dialerDelegate = null;
            verify(appRepeaterConnections.target);
            appRepeaterConnections.itemAddedCallback = function(item) {
                dialerDelegate = item;
                verify(item.application.appId, "dialer-app");
            }

            WindowStateStorage.saveStage("dialer-app", ApplicationInfoInterface.SideStage)
            var dialerApp = ApplicationManager.startApplication("dialer-app");
            verify(dialerApp);

            // ensure the mock dialer-app is as we expect
            compare(dialerApp.rotatesWindowContents, false);
            compare(dialerApp.supportedOrientations, Qt.PortraitOrientation | Qt.InvertedPortraitOrientation);

            tryCompareFunction(function(){ return dialerDelegate != null; }, true);
            tryCompare(dialerDelegate, "orientationChangesEnabled", true);

            var decoratedWindow = findChild(dialerDelegate, "decoratedWindow");
            verify(decoratedWindow);
            tryCompare(decoratedWindow, "counterRotate", false);

            // app must have portrait aspect ratio
            verify(decoratedWindow.width < decoratedWindow.height);

            // shell should remain in its primary orientation as the app in the main stage
            // is the one that dictates its orientation. In this case it's unity8-dash
            // which supports only primary orientation
            compare(shell.orientation, orientedShell.orientations.primary);
        }

        function test_launchedAppHasActiveFocus_data() {
            return [
                {tag: "mako", deviceName: "mako"},
                {tag: "manta", deviceName: "manta"},
                {tag: "flo", deviceName: "flo"}
            ];
        }
        function test_launchedAppHasActiveFocus(data) {
            var orientedShell = loadShell(data.deviceName);
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");

            var gmailSurfaceId = topLevelSurfaceList.nextId;
            var gmailApp = ApplicationManager.startApplication("gmail-webapp");
            verify(gmailApp);
            waitUntilAppWindowIsFullyLoaded(gmailSurfaceId, orientedShell);

            var gmailSurface = gmailApp.surfaceList.get(0);
            verify(gmailSurface);

            tryCompare(gmailSurface, "activeFocus", true);
        }

        function test_launchLandscapeOnlyAppOverPortraitOnlyDashThenSwitchToDash() {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");
            var topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");

            var dashSurfaceId = topLevelSurfaceList.nextId;
            var dashApp = ApplicationManager.startApplication("unity8-dash");
            verify(dashApp);
            waitUntilAppWindowIsFullyLoaded(dashSurfaceId, orientedShell);

            // starts as portrait, as unity8-dash is portrait only
            tryCompare(shell, "transformRotationAngle", 0);

            var weatherSurfaceId = topLevelSurfaceList.nextId;
            var weatherApp = ApplicationManager.startApplication("ubuntu-weather-app");
            verify(weatherApp);

            // ensure the mock app is as we expect
            compare(weatherApp.supportedOrientations, Qt.LandscapeOrientation | Qt.InvertedLandscapeOrientation);

            waitUntilAppWindowIsFullyLoaded(weatherSurfaceId, orientedShell);

            // should have rotated to landscape
            tryCompareFunction(function () { return shell.transformRotationAngle == 270
                                                 || shell.transformRotationAngle == 90; }, true);

            var rotationStates = findInvisibleChild(orientedShell, "rotationStates");
            waitUntilTransitionsEnd(rotationStates);

            ApplicationManager.requestFocusApplication("unity8-dash");

            // Should be back to portrait
            tryCompare(shell, "transformRotationAngle", 0);
        }

        function  test_attachRemoveInputDevices_data() {
            return [
                { tag: "small screen, no devices", screenWidth: units.gu(50), mouse: false, kbd: false, expectedMode: "phone", oskExpected: true },
                { tag: "medium screen, no devices", screenWidth: units.gu(100), mouse: false, kbd: false, expectedMode: "phone", oskExpected: true },
                { tag: "big screen, no devices", screenWidth: units.gu(200), mouse: false, kbd: false, expectedMode: "phone", oskExpected: true },
                { tag: "small screen, mouse", screenWidth: units.gu(50), mouse: true, kbd: false, expectedMode: "phone", oskExpected: true },
                { tag: "medium screen, mouse", screenWidth: units.gu(100), mouse: true, kbd: false, expectedMode: "desktop", oskExpected: true },
                { tag: "big screen, mouse", screenWidth: units.gu(200), mouse: true, kbd: false, expectedMode: "desktop", oskExpected: true },
                { tag: "small screen, kbd", screenWidth: units.gu(50), mouse: false, kbd: true, expectedMode: "phone", oskExpected: false },
                { tag: "medium screen, kbd", screenWidth: units.gu(100), mouse: false, kbd: true, expectedMode: "phone", oskExpected: false },
                { tag: "big screen, kbd", screenWidth: units.gu(200), mouse: false, kbd: true, expectedMode: "phone", oskExpected: false },
                { tag: "small screen, mouse & kbd", screenWidth: units.gu(50), mouse: true, kbd: true, expectedMode: "phone", oskExpected: false },
                { tag: "medium screen, mouse & kbd", screenWidth: units.gu(100), mouse: true, kbd: true, expectedMode: "desktop", oskExpected: false },
                { tag: "big screen, mouse & kbd", screenWidth: units.gu(200), mouse: true, kbd: true, expectedMode: "desktop", oskExpected: false },
            ]
        }

        function test_attachRemoveInputDevices(data) {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");
            MockInputDeviceBackend.removeDevice("/indicator_kbd0");
            var inputMethod = findChild(shell, "inputMethod");

            var oldWidth = shellRect.width;
            shellRect.width = data.screenWidth;

            tryCompare(shell, "usageScenario", "phone");
            tryCompare(inputMethod, "enabled", true);
            tryCompare(oskSettings, "disableHeight", false);

            if (data.kbd) {
                MockInputDeviceBackend.addMockDevice("/kbd0", InputInfo.Keyboard);
            }
            if (data.mouse) {
                MockInputDeviceBackend.addMockDevice("/mouse0", InputInfo.Mouse);
            }

            tryCompare(shell, "usageScenario", data.expectedMode);
            tryCompare(inputMethod, "enabled", data.oskExpected);
            tryCompare(oskSettings, "disableHeight", data.expectedMode == "desktop" || data.kbd);

            // Restore width
            shellRect.width = oldWidth;
        }

        function test_screenSizeChanges() {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");

            tryCompare(shell, "usageScenario", "phone");

            // make screen larger
            shellRect.width = units.gu(90);
            tryCompare(shell, "usageScenario", "phone");

            // plug a mouse
            MockInputDeviceBackend.addMockDevice("/mouse0", InputInfo.Mouse);
            tryCompare(shell, "usageScenario", "desktop");

            // make the screen smaller again, it should go back to staged even though there's still a mouse around
            shellRect.width = units.gu(40);

            tryCompare(shell, "usageScenario", "phone");
        }

        function test_overrideStaged() {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");

            // make sure we're big enough so that the automatism starts working
            var oldWidth = shellRect.width;
            shellRect.width = units.gu(100);

            // start off by plugging a mouse, we should switch to windowed
            MockInputDeviceBackend.addMockDevice("/mouse0", InputInfo.Mouse);
            tryCompare(shell, "usageScenario", "desktop");

            // Use the toggle to go back to Staged
            usageModeSelector.selectStaged();
            tryCompare(shell, "usageScenario", "phone");

            // attach a second mouse, we should switch again
            MockInputDeviceBackend.addMockDevice("/mouse1", InputInfo.Mouse);
            tryCompare(shell, "usageScenario", "desktop");

            // Remove one mouse again, stay in windowed as there is another
            MockInputDeviceBackend.removeDevice("/mouse1");
            tryCompare(shell, "usageScenario", "desktop");

            // use the toggle again
            usageModeSelector.selectStaged();
            tryCompare(shell, "usageScenario", "phone");

            // Remove the other mouse again, stay in staged
            MockInputDeviceBackend.removeDevice("/mouse0");
            tryCompare(shell, "usageScenario", "phone");

            // Restore width
            shellRect.width = oldWidth;
        }

        function test_setsUsageModeOnStartup() {
            // Prepare inconsistent beginning (mouse & staged mode)
            MockInputDeviceBackend.addMockDevice("/mouse0", InputInfo.Mouse);
            usageModeSelector.selectStaged();
            compare(unity8Settings.usageMode, "Staged");

            // Load shell, and have it pick desktop
            var orientedShell = loadShell("desktop");
            var shell = findChild(orientedShell, "shell");
            compare(shell.usageScenario, "desktop");
            compare(unity8Settings.usageMode, "Windowed");
        }

        function test_overrideWindowed() {
            var orientedShell = loadShell("mako")
            var shell = findChild(orientedShell, "shell");

            // make sure we're big enough so that the automatism starts working
            var oldWidth = shellRect.width;
            shellRect.width = units.gu(100);

            // No mouse attached... we should be in staged
            tryCompare(shell, "usageScenario", "phone");

            // use the toggle to go to windowed
            usageModeSelector.selectWindowed();
            tryCompare(shell, "usageScenario", "desktop");

            // Connect a mouse, stay in windowed
            MockInputDeviceBackend.addMockDevice("/mouse0", InputInfo.Mouse);
            tryCompare(shell, "usageScenario", "desktop");

            // Remove the mouse again, we should go to staged
            MockInputDeviceBackend.removeDevice("/mouse0");
            tryCompare(shell, "usageScenario", "phone");

            // Restore width
            shellRect.width = oldWidth;
        }

        /*
            Regression test for https://bugs.launchpad.net/ubuntu/+source/unity8/+bug/1471609

            Steps:
             - Open an app which can rotate
             - Rotate the phone to landscape
             - Open the app spread
             - Press the power button while the app spread is open
             - Wait a bit and press power button again

            Expected outcome:
             You see greeter in portrat (ie, primary orientation)

            Actual outcome:
             You see greeter in landscape

            Comments:
             Greeter supports only the primary orientation (portrait in phones) but
             the stage doesn't allow orientation changes while the apps spread is open,
             hence the bug.
         */
        function test_phoneWithSpreadInLandscapeWhenGreeterShowsUp() {
            var orientedShell = loadShell("mako");
            var shell = findChild(orientedShell, "shell");

            var gmailApp = ApplicationManager.startApplication("gmail-webapp");
            verify(gmailApp);

            // ensure the mock gmail-webapp is as we expect
            compare(gmailApp.rotatesWindowContents, false);
            compare(gmailApp.supportedOrientations, Qt.PortraitOrientation | Qt.LandscapeOrientation
                    | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation);

            // wait until it's able to rotate
            tryCompare(shell, "orientationChangesEnabled", true);

            rotateTo(90, orientedShell);
            tryCompare(shell, "transformRotationAngle", root.primaryOrientationAngle + 90);

            performEdgeSwipeToShowAppSpread(shell);

            showGreeter(orientedShell);

            tryCompare(shell, "transformRotationAngle", root.primaryOrientationAngle + 90);
        }

        /*
           Regression test for https://bugs.launchpad.net/ubuntu/+source/unity8/+bug/1476757

           Steps:
           1- have a portrait-only app in foreground (eg primary-oriented-app)
           2- launch or switch to some other application
           3- right-edge swipe to show the apps spread
           4- swipe up to close the current app (the one from step 2)
           5- lock the phone (press the power button)
           6- unlock the phone (press power button again and swipe greeter away)
               * app from step 1 should be on foreground and focused
           7- rotate phone

           Expected outcome:
           - The portrait-only application stays put

           Actual outcome:
           - The portrait-only application rotates freely
         */
        function test_lockPhoneAfterClosingAppInSpreadThenUnlockAndRotate() {
            var orientedShell = loadShell("mako");
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            var shell = findChild(orientedShell, "shell");

            var primarySurfaceId = topLevelSurfaceList.nextId;
            var primaryApp = ApplicationManager.startApplication("primary-oriented-app");
            verify(primaryApp);
            waitUntilAppWindowIsFullyLoaded(primarySurfaceId, orientedShell);

            var gmailSurfaceId = topLevelSurfaceList.nextId;
            var gmailApp = ApplicationManager.startApplication("gmail-webapp");
            verify(gmailApp);

            waitUntilAppWindowIsFullyLoaded(gmailSurfaceId, orientedShell);

            performEdgeSwipeToShowAppSpread(shell);

            swipeToCloseCurrentAppInSpread(orientedShell);

            // press the power key once
            Powerd.setStatus(Powerd.Off, Powerd.Unknown);
            var greeter = findChild(shell, "greeter");
            tryCompare(greeter, "fullyShown", true);

            // and a second time to turn the display back on
            Powerd.setStatus(Powerd.On, Powerd.Unknown);

            swipeAwayGreeter(orientedShell);

            tryCompareFunction(function() { return isAppSurfaceFocused(topLevelSurfaceList, primarySurfaceId)}, true, 10000)

            signalSpy.clear();
            signalSpy.target = shell;
            signalSpy.signalName = "widthChanged";
            verify(signalSpy.valid);

            rotateTo(90, orientedShell);

            // shell shouldn't have change its orientation at any moment
            compare(signalSpy.count, 0);
        }

        function test_moveToExternalMonitor() {
            var orientedShell = loadShell("flo");
            var shell = findChild(orientedShell, "shell");

            compare(orientedShell.orientation, Qt.InvertedLandscapeOrientation);
            compare(shell.transformRotationAngle, 90);

            moveToFromMonitorButton.clicked();

            tryCompare(orientedShell, "orientation", Qt.LandscapeOrientation);
            tryCompare(shell, "transformRotationAngle" , 0);
        }

        /*
            Regression test for https://launchpad.net/bugs/1515977

            Preconditions:
            UI in Desktop mode and landscape

            Steps:
            - Launch a portrait-only application

            Expected outcome:
            - Shell stays in landscape

            Buggy outcome:
            - Shell would rotate to portrait as the newly-focused app doesn't support landscape
         */
        function test_portraitOnlyAppInLandscapeDesktop_data() {
            return [
                {tag: "mako", deviceName: "mako"},
                {tag: "manta", deviceName: "manta"},
                {tag: "flo", deviceName: "flo"}
            ];
        }
        function test_portraitOnlyAppInLandscapeDesktop(data) {
            var orientedShell = loadShell(data.deviceName);
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            var shell = findChild(orientedShell, "shell");

            ////
            // setup preconditions (put shell in Desktop mode and landscape)

            usageModeSelector.selectWindowed();

            orientedShell.physicalOrientation = orientedShell.orientations.landscape;
            waitUntilShellIsInOrientation(orientedShell.orientations.landscape, orientedShell);
            waitForRotationAnimationsToFinish(orientedShell);

            ////
            // Launch a portrait-only application

            var dialerSurfaceId = topLevelSurfaceList.nextId;
            var dialerApp = ApplicationManager.startApplication("dialer-app");
            verify(dialerApp);

            // ensure the mock dialer-app is as we expect
            compare(dialerApp.rotatesWindowContents, false);
            compare(dialerApp.supportedOrientations, Qt.PortraitOrientation | Qt.InvertedPortraitOrientation);

            waitUntilAppWindowIsFullyLoaded(dialerSurfaceId, orientedShell);
            waitUntilAppWindowCanRotate(dialerSurfaceId, orientedShell);
            verify(isAppSurfaceFocused(topLevelSurfaceList, dialerSurfaceId));

            ////
            // check outcome (shell should stay in landscape)

            waitForRotationAnimationsToFinish(orientedShell);
            compare(shell.orientation, orientedShell.orientations.landscape);
        }

        //  angle - rotation angle in degrees clockwise, relative to the primary orientation.
        function rotateTo(angle, orientedShell) {
            switch (angle) {
            case 0:
                root.rotate0(orientedShell);
                break;
            case 90:
                root.rotate90(orientedShell);
                break;
            case 180:
                root.rotate180(orientedShell);
                break;
            case 270:
                root.rotate270(orientedShell);
                break;
            default:
                verify(false);
            }
            waitForRotationAnimationsToFinish(orientedShell);
        }

        function waitForRotationAnimationsToFinish(orientedShell) {
            var rotationStates = findInvisibleChild(orientedShell, "rotationStates");
            verify(rotationStates.d);
            verify(rotationStates.d.stateUpdateTimer);

            // wait for the delayed state update to take place, if any
            tryCompare(rotationStates.d.stateUpdateTimer, "running", false);

            waitUntilTransitionsEnd(rotationStates);
        }

        function waitUntilAppDelegateIsFullyInit(spreadDelegate) {
            tryCompare(spreadDelegate, "orientationChangesEnabled", true);

            var decoratedWindow = findChild(spreadDelegate, "decoratedWindow");
            tryCompare(decoratedWindow, "counterRotate", false);

            var appWindowStates = findInvisibleChild(decoratedWindow, "applicationWindowStateGroup");
            verify(appWindowStates);
            tryCompare(appWindowStates, "state", "surface");
        }

        function findAppWindowForSurfaceId(surfaceId, orientedShell) {
            var delegate = findChild(orientedShell, "appDelegate_" + surfaceId);
            verify(delegate);
            var appWindow = findChild(delegate, "appWindow");
            return appWindow;
        }

        // Wait until the ApplicationWindow for the given Application object is fully loaded
        // (ie, the real surface has replaced the splash screen)
        function waitUntilAppWindowIsFullyLoaded(surfaceId, orientedShell) {
            var appWindow = findAppWindowForSurfaceId(surfaceId, orientedShell);
            var appWindowStateGroup = findInvisibleChild(appWindow, "applicationWindowStateGroup");
            tryCompareFunction(function() { return appWindowStateGroup.state === "surface" }, true);
            waitUntilTransitionsEnd(appWindowStateGroup);
        }

        function waitUntilAppWindowCanRotate(surfaceId, orientedShell) {
            var appWindow = findAppWindowForSurfaceId(surfaceId, orientedShell);
            tryCompare(appWindow, "orientationChangesEnabled", true);
        }

        function waitUntilShellIsInOrientation(orientation, orientedShell) {
            var shell = findInvisibleChild(orientedShell, "shell");
            tryCompare(shell, "orientation", orientation);
            var rotationStates = findInvisibleChild(orientedShell, "rotationStates");
            waitUntilTransitionsEnd(rotationStates);
        }

        function performEdgeSwipeToSwitchToPreviousApp(orientedShell) {
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            var shell = findChild(orientedShell, "shell");
            // swipe just enough to ensure an app switch action.
            // If we swipe too much we will trigger the spread mode
            // and we don't want that.
            verify(topLevelSurfaceList.count >= 2);
            var previousSurfaceId = topLevelSurfaceList.idAt(1);

            var touchStartX = shell.width - 1;
            var touchStartY = shell.height / 2;

            touchFlick(shell, touchStartX, touchStartY, touchStartX - units.gu(8), touchStartY, units.gu(4), 10);

            tryCompareFunction(function(){ return topLevelSurfaceList.idAt(0); }, previousSurfaceId);
        }

        function performEdgeSwipeToShowAppSpread(orientedShell) {
            var touchStartY = orientedShell.height / 2;
            touchFlick(orientedShell,
                       orientedShell.width - 1, touchStartY,
                       0, touchStartY);

            var stage = findChild(orientedShell, "stage");
            tryCompare(stage, "state", "spread");
            waitForRendering(stage);
        }

        function showPowerDialog(orientedShell) {
            var dialogs = findChild(orientedShell, "dialogs");
            var dialogsPrivate = findInvisibleChild(dialogs, "dialogsPrivate");
            dialogsPrivate.showPowerDialog();
        }

        function swipeAwayGreeter(orientedShell) {
            var shell = findChild(orientedShell, "shell");
            var greeter = findChild(shell, "greeter");
            verify(greeter);
            tryCompare(greeter, "fullyShown", true);
            waitForRendering(greeter)

            var touchX = shell.width * .75;
            var touchY = shell.height / 2;
            touchFlick(shell, touchX, touchY, orientedShell.width * 0.1, touchY);

            // wait until the animation has finished
            if (LightDMController.userMode == "single")
                tryCompare(greeter, "shown", false);
            waitForRendering(greeter);
        }

        function showGreeter(orientedShell) {
            LightDM.Greeter.showGreeter();
            // wait until the animation has finished
            var greeter = findChild(orientedShell, "greeter");
            tryCompare(greeter, "fullyShown", true);
        }

        function loadShell(deviceName, userMode = "single") {
            applicationArguments.deviceName = deviceName;

            ldmUserMode = userMode; // Set the mode for LightDM ( default is "single" )

            // reload our test subject to get it in a fresh state once again
            var orientedShell = createTemporaryObject(shellComponent, shellRect);

            removeTimeConstraintsFromSwipeAreas(orientedShell);

            var shell = findChild(orientedShell, "shell");

            tryCompare(shell, "waitingOnGreeter", false); // reset by greeter when ready

            waitUntilShellIsInOrientation(root.physicalOrientation0, orientedShell);

            waitForGreeterToStabilize(orientedShell);

            swipeAwayGreeter(orientedShell);

            var appRepeater = findChild(shell, "appRepeater");
            if (appRepeater) {
                appRepeaterConnections.target = appRepeater;
            }
            return orientedShell;
        }

        function waitForGreeterToStabilize(orientedShell) {
            var greeter = findChild(orientedShell, "greeter");
            verify(greeter);

            var loginList = findChild(greeter, "loginList");
            // Only present in WideView
            if (loginList) {
                var userList = findChild(loginList, "userList");
                verify(userList);
                tryCompare(userList, "movingInternally", false);
            }
        }

        // expectedAngle is in orientedShell's coordinate system
        function checkAppSurfaceOrientation(item, app, expectedAngle, orientedShell) {
            var surface = app.surfaceList.get(0);
            if (!surface) {
                console.warn("no surface");
                return false;
            }

            var surfaceItem = findSurfaceItem(item, surface);
            if (!surfaceItem) {
                console.warn("no surfaceItem rendering app surface");
                return false;
            }
            var point = surfaceItem.mapToItem(orientedShell, 0, 0);

            switch (expectedAngle) {
            case 0:
                return point.x === 0 && point.y === PanelState.panelHeight;
            case 90:
                return point.x === orientedShell.width - PanelState.panelHeight && point.y === 0;
            case 180:
                return point.x === orientedShell.width && point.y === orientedShell.height - PanelState.panelHeight;
            default: // 270
                return point.x === PanelState.panelHeight && point.y === orientedShell.height;
            }
        }

        function findSurfaceItem(obj, surface) {
            var childs = new Array(0);
            childs.push(obj)
            while (childs.length > 0) {
                if (childs[0].objectName === "surfaceItem"
                        && childs[0].surface !== undefined
                        && childs[0].surface === surface) {
                    return childs[0];
                }
                for (var i in childs[0].children) {
                    childs.push(childs[0].children[i])
                }
                childs.splice(0, 1);
            }
            return null;
        }

        function swipeToCloseCurrentAppInSpread(orientedShell) {
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            var delegateToClose = findChild(orientedShell, "appDelegate_" + topLevelSurfaceList.idAt(0));
            verify(delegateToClose);

            var appIdToClose = ApplicationManager.get(0).appId;
            var appCountBefore = ApplicationManager.count;

            // Swipe up close to its left edge, as it is the only area of it guaranteed to be exposed
            // in the spread. Eg: its center could be covered by some other delegate.
            touchFlick(delegateToClose,
                1, delegateToClose.height / 2,
                1, - delegateToClose.height / 4);

            // ensure it got closed
            tryCompare(ApplicationManager, "count", appCountBefore - 1);
            compare(ApplicationManager.findApplication(appIdToClose), null);
        }

        function isAppSurfaceFocused(topLevelSurfaceList, surfaceId) {
            var index = topLevelSurfaceList.indexForId(surfaceId);
            var surface = topLevelSurfaceList.surfaceAt(index);
            verify(surface);
            return surface.activeFocus;
        }

        function test_tabCyclyingInShutdownDialog_data() {
            return [
                {tag: "TAB", key: Qt.Key_Tab},
                {tag: "DOWN", key: Qt.Key_Down}
            ];
        }

        function test_tabCyclyingInShutdownDialog(data) {
            var orientedShell = loadShell("mako");

            testCase.showPowerDialog(orientedShell);

            var dialogs = findChild(orientedShell, "dialogs");
            var buttons = findChildsByType(dialogs, "Button");

            tryCompare(buttons[0], "activeFocus", true);

            keyClick(data.key);
            tryCompare(buttons[1], "activeFocus", true);

            keyClick(data.key);
            tryCompare(buttons[2], "activeFocus", true);

            keyClick(data.key);
            tryCompare(buttons[3], "activeFocus", true);

            keyClick(data.key);
            tryCompare(buttons[0], "activeFocus", true);

            keyClick(Qt.Key_Escape);

            var dialogLoader = findChild(orientedShell, "dialogLoader");
            tryCompare(dialogLoader, "item", null);
        }

        function test_escClosesShutdownDialog() {
            var orientedShell = loadShell("mako");

            testCase.showPowerDialog(orientedShell);

            var dialogLoader = findChild(orientedShell, "dialogLoader");
            tryCompareFunction(function() { return dialogLoader.item !== null }, true);

            keyClick(Qt.Key_Escape);

            tryCompare(dialogLoader, "item", null);
        }

        function test_focusOnShutdownDialogClose() {
            var orientedShell = loadShell("manta");
            var topLevelSurfaceList = findInvisibleChild(orientedShell, "topLevelSurfaceList");
            usageModeSelector.selectWindowed();

            var surfaceId = topLevelSurfaceList.nextId;
            var app = ApplicationManager.startApplication("twitter-webapp");
            waitUntilAppWindowIsFullyLoaded(surfaceId, orientedShell);

            var primaryAppWindow = findAppWindowForSurfaceId(surfaceId, orientedShell);
            var surface = app.surfaceList.get(0);
            var surfaceItem = findSurfaceItem(primaryAppWindow, surface);

            compare(window.activeFocusItem, surfaceItem);

            testCase.showPowerDialog(orientedShell);

            var dialogLoader = findChild(orientedShell, "dialogLoader");
            tryVerify(function() { return dialogLoader.item !== null });

            keyClick(Qt.Key_Escape);

            tryCompare(dialogLoader, "item", null);
            compare(window.activeFocusItem, surfaceItem);

            // Do it twice, our previous solution failed the second time ^_^
            testCase.showPowerDialog(orientedShell);

            tryVerify(function() { return dialogLoader.item !== null });

            keyClick(Qt.Key_Escape);

            tryCompare(dialogLoader, "item", null);
            compare(window.activeFocusItem, surfaceItem);
        }

        function test_tutorialDisabledWithNoTouchscreen() {
            var orientedShell = loadShell("desktop");
            var shell = findChild(orientedShell, "shell");
            usageModeSelector.selectWindowed();

            MockInputDeviceBackend.addMockDevice("/touchscreen", InputInfo.TouchScreen);
            var tutorial = findChild(shell, "tutorial");
            tryCompare(tutorial, "paused", false);

            MockInputDeviceBackend.removeDevice("/touchscreen");
            tryCompare(tutorial, "paused", true);
        }

        /* Check if the keyboard icon on the greeter screen
         * is only shown when an external keyboard is attached
         * and if it is hidden when no keyboard is attached.
         */
        function test_greeterKeyboardDetection() {
            var orientedShell = loadShell("mako", "single-passphrase");
            MockInputDeviceBackend.removeDevice("/indicator_kbd0");

            var greeterPrompt = findChild(orientedShell, "greeterPrompt0");
            verify(greeterPrompt);

            var promptKeyboard = findChild(greeterPrompt, "greeterPromptKeyboardButton");

            tryCompare(promptKeyboard, "visible", false);

            MockInputDeviceBackend.addMockDevice("/kbd0", InputInfo.Keyboard);

            tryCompare(promptKeyboard, "visible", true);
        }
    }
}
