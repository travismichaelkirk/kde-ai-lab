# Tasker HTTP Bridge

## Purpose

The Tasker HTTP bridge provides a communication path from the Fedora
KDE AI Lab workstation to Tasker on an Android device.

The initial implementation demonstrates that Fedora can send an HTTP
request, trigger a Tasker action, and receive an HTTP response.

## Current Platform

Initial implementation and verification:

- Fedora KDE Plasma
- Android with Tasker
- ADB Wireless Debugging
- Local Wi-Fi connectivity
- HTTP using TCP port 8765

## Architecture

The communication flow is:

1. Fedora sends an HTTP GET request to the Android device.
2. Tasker's HTTP Request event receives the request.
3. Tasker evaluates the requested path.
4. The matching Tasker actions execute.
5. Tasker returns an HTTP response to Fedora.

The initial test endpoint is:

`GET /test`

## Tasker Configuration

Project: `KDE AI Lab`

Profile: `KDE AI Lab HTTP Bridge`

Task: `KDE AI Lab Test`

The task performs the following actions:

1. Flash the received HTTP request path.
2. Check whether the request path equals `/test`.
3. Flash `KDE AI Lab TEST Route`.
4. Return HTTP status 200 with the text body
   `KDE AI Lab TEST Route OK`.
5. End the conditional block.

The exported Tasker project is stored at:

`tasker/KDE_AI_Lab.prj.xml`

## Verification

The bridge was tested from an ordinary Fedora Konsole session.

The test command was:

```bash
curl -v --connect-timeout 5 \
    http://192.168.4.25:8765/test
```

The verified response included:

- HTTP status: `200 OK`
- Content-Type: `text/plain`
- Response body: `KDE AI Lab TEST Route OK`

Both expected Tasker Flash actions were also observed.

This confirms successful request delivery, Tasker route execution,
and HTTP response delivery back to Fedora.

The dedicated KDE AI Lab Konsole has not yet been independently
tested with the bridge.

## Current Limitations

- The Android device IP address may change.
- The bridge currently uses unencrypted HTTP.
- No application-level authentication has been implemented.
- Access restrictions have not been verified.
- Only the `/test` endpoint has been validated.
- Error handling and unknown-route responses have not been validated.

The bridge is a functional prototype and should not be used for
sensitive remote actions in its current configuration.

## Recovery

The verified Tasker project was exported to Android storage at:

`/sdcard/Tasker/projects/KDE_AI_Lab.prj.xml`

A copy is maintained in the KDE AI Lab Git repository.

The project XML can be imported into Tasker to restore the
configuration, subject to device-specific settings and permissions.

## Future Development

Potential improvements include:

- Endpoint authentication and access restrictions.
- Predictable handling of unknown routes.
- Android device address discovery.
- Integration with the dedicated KDE AI Lab workspace.
- Additional Tasker actions after security verification.

Changes will be implemented and tested incrementally.
