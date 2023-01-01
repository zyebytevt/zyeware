// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.events.application;

import zyeware.core.events.event;

/// The QuitEvent is raised when a request to quit the application is made
/// by the user. This can either be clicking the "X" button on a window,
/// sending SIGTERM etc.
class QuitEvent : Event
{
}