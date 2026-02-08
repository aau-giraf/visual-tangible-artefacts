# ApiProvider

**File:** `Frontend/vta_app/lib/src/utilities/api/api_provider.dart` (167 lines)

## Purpose

Low-level HTTP client wrapper around the `http` package. Provides typed methods for common HTTP verbs and handles multipart file uploads with automatic type conversion.

## Class: `ApiProvider`

### Constructor
- `ApiProvider({required String baseUrl})` — all requests are relative to this base URL

### HTTP Methods

| Method | Description |
|--------|-------------|
| `fetchAsJson(endpoint, headers)` | GET request, returns `Response?` |
| `postAsJson(endpoint, headers, body)` | POST with JSON body |
| `patchAsJson(endpoint, headers, body)` | PATCH with JSON body |
| `putAsJson(endpoint, headers, body)` | PUT with JSON body |
| `delete(endpoint, headers)` | DELETE request |
| `sendAsMultiPart(action, endpoint, headers, body)` | Multipart request (any HTTP verb) |

### Multipart Handling (`_buildMultipartRequest`)
Converts a `Map<String, dynamic>` body into multipart fields/files:
- `String`, `int`, `double`, `bool` → form fields (stringified)
- `Uint8List` → file upload (key used as filename)
- `List<String>` → comma-joined text file
- `List<Map<String, dynamic>>` → JSON file
- `Map<String, dynamic>` → JSON file
- Throws on unsupported types

### Error Handling
All methods catch exceptions, print to console, and return `null` (no exceptions propagated to callers).

## Extension: `IsOk` on `http.Response`
Adds `bool get ok` — returns `true` if status code is 2xx (`statusCode ~/ 100 == 2`).

## Design Notes
- Used by `ArtifactModel`, `AuthModel`, `DataRepository`, `ElevenLabsService`, and most other API-consuming classes.
- Swallows exceptions and returns `null` — callers must null-check responses.
- No retry logic, no interceptors, no token refresh.
