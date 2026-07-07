// MouseStudioShared
// Foundation module: pure data models, enums, and IPC contracts.
// This module has ZERO internal dependencies so both the GUI and the
// Core/Service can share type definitions without depending on each other.
//
// Contents (see docs/TechnicalDesignDocument.md §4, §9, §10):
//   Models/  — Rule, Trigger, Condition, ActionSpec, Profile, DeviceProfile, Config
//   IPC/     — IPCRequest, IPCResponse, IPCEvent, TestResult
//   Enums/   — ButtonID, GestureKind, ScrollDirection, LogLevel, EngineStatus

import Foundation

public enum MouseStudio {
    /// Semantic version of the Mouse Studio platform.
    public static let version = "0.1.0"
    /// Config schema version currently supported.
    public static let schemaVersion = 1
}
