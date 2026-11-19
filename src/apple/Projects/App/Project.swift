// Copyright 2026 Michael F. Collins, III
// Licensed under the Naked Time license. See LICENSE.md for details.

import ProjectDescription

let project = Project(
    name: "Time",
    organizationName: "Michael Collins",
    targets: [
        .target(
            name: "Time",
            destinations: [
                .iPad,
                .iPhone
            ],
            product: .app,
            bundleId: "software.naked.time",
            deploymentTargets: .iOS("27.0"),
            infoPlist: .extendingDefault(with: [
                "NSAlarmKitUsageDescription": "This app uses timers and alarms for Pomodoros used to work activities and to track breaks between Pomodoros."
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"]
        )
    ]
)
