library;

export 'src/eventide_platform_interface.dart' show EventidePlatformInterface;
export 'src/calendar.dart' show ETCalendar;
export 'src/event.dart' show ETEvent, ETSpan;
export 'src/account.dart' show ETAccount;
export 'src/attendance.dart' show ETAttendeeType, ETAttendanceStatus, ETAttendee;
export 'src/exceptions.dart'
    show
        ETException,
        ETPermissionException,
        ETNotEditableException,
        ETNotFoundException,
        ETGenericException,
        ETNotSupportedByPlatform,
        ETUserCanceledException,
        ETPresentationException,
        PlatformExceptionToETCalendarException;
