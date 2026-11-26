# Laravel API Contract

This Flutter application calls a Laravel JSON API relative to
`API_BASE_URL`. The default value is `http://127.0.0.1:8000/api`; copy
`.env.example` to `.env`, set `API_BASE_URL=https://api.example.com/api`, and
run `dart run build_runner build --delete-conflicting-outputs`.

The Dio client sends `Accept: application/json` and `Content-Type:
application/json`. Protected requests send `Authorization: Bearer
<access_token>`. IDs are opaque strings; the client does not assume integer
IDs.

## Response envelopes

Authentication sessions and refresh responses are commonly returned directly
or wrapped by a top-level `data` object. Resource list endpoints accept either
a top-level JSON array or `{ "data": [...] }`. The client currently does not
paginate resource lists.

Validation errors should use a non-2xx status, conventionally 422, and include
a string `message`. Forbidden requests should return 403 and unauthenticated
requests should return 401. The UI reads `message` directly when present.

## Authentication

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| `POST` | `/auth/login` | Public | Create a session from credentials |
| `POST` | `/auth/register` | Public | Create an account and session |
| `POST` | `/auth/refresh` | Refresh token | Rotate the token pair |
| `GET` | `/auth/me` | Access token | Return the signed-in user |
| `POST` | `/auth/logout` | Access token | Revoke the current session |

Login body:

```json
{
  "email": "student@example.test",
  "password": "example-password"
}
```

Registration body:

```json
{
  "name": "Example User",
  "email": "student@example.test",
  "password": "example-password",
  "password_confirmation": "example-password"
}
```

Login and registration may return:

```json
{
  "data": {
    "access_token": "short-lived-access-token",
    "refresh_token": "rotating-refresh-token",
    "user": {
      "id": "opaque-user-id",
      "name": "Example User",
      "email": "student@example.test",
      "roles": [{"name": "editor"}],
      "permissions": ["users.view", "roles.view", "reports.export"]
    }
  }
}
```

Both token fields are required and must be non-empty. The refresh endpoint
receives the existing refresh token:

```json
{
  "refresh_token": "current-refresh-token"
}
```

It must return the same envelope shape with a newly rotated pair:

```json
{
  "data": {
    "access_token": "new-access-token",
    "refresh_token": "new-rotating-refresh-token"
  }
}
```

`GET /auth/me` may return a user object directly or under `data`.

```json
{
  "data": {
    "id": "opaque-user-id",
    "name": "Example User",
    "email": "student@example.test",
    "roles": [{"name": "editor"}],
    "permissions": ["users.view", "roles.view"]
  }
}
```

`permissions` must contain the user's effective permissions, including
Spatie role-derived and direct permissions. `roles` must contain names. The
literal `superadmin` role enables the client-side global UI bypass through
`canAccess(...)`; Laravel must still enforce its own server-side authorization
and should grant `superadmin` a matching server-side bypass.

The login, registration, and refresh endpoints must not require an access
token. On a protected 401, the client:

1. reads the stored refresh token;
2. sends one refresh request, sharing concurrent refresh attempts;
3. stores the returned access/refresh pair;
4. retries the original request once with the new access token.

The app clears the stored pair if the refresh returns 401 or 403, if no refresh
token exists, or if the refresh response omits either token.

## Resource endpoints

Protect resource routes with authentication and the action permission.
Create/update responses should contain the saved object, but the client does
not currently require a specific create/update response shape.

| Resource | Collection | Record | Required permissions |
| --- | --- | --- | --- |
| Users | `/users` | `/users/{id}` | `users.view`, `users.create`, `users.update`, `users.delete` |
| Roles | `/roles` | `/roles/{id}` | `roles.view`, `roles.create`, `roles.update`, `roles.delete` |
| Permissions | `/permissions` | `/permissions/{id}` | `permissions.view`, `permissions.create`, `permissions.update`, `permissions.delete` |

Supported operations:

| Method | Path | Payload |
| --- | --- | --- |
| `GET` | Collection | None |
| `POST` | Collection | Create fields |
| `PUT` | Record | Update fields |
| `DELETE` | Record | None |

Editable fields:

* Users: `name`, `email`, and optional `password`
* Roles: `name`
* Permissions: `name`

User creation is expected to require `password`. On update, omit `password`
entirely when the form leaves it blank; the API must retain the existing
password in that case. Do not accept `roles` or `direct_permissions` in general
user create/update payloads. Do not accept `permissions` in general role
create/update payloads. Relationship changes are only supported through the
dedicated assignment routes below.

## Resource response shapes

### Users

`GET /users` must return a list where every user includes its assigned roles
and direct permissions separately:

```json
[
  {
    "id": "opaque-user-id",
    "name": "Example User",
    "email": "student@example.test",
    "roles": [{"name": "editor"}],
    "direct_permissions": [{"name": "reports.export"}]
  }
]
```

Both `roles` and `direct_permissions` are required lists. Do not merge direct
permissions into `roles`, and do not return only the effective permission set
for `direct_permissions`.

### Roles

`GET /roles` must eager-load assigned permissions:

```json
[
  {
    "id": "opaque-role-id",
    "name": "editor",
    "permissions": [{"name": "users.view"}]
  }
]
```

The `permissions` field is required and must be a list.

### Permissions

```json
[
  {
    "id": "opaque-permission-id",
    "name": "users.view",
    "guard_name": "web"
  }
]
```

All permission records must include `id`, `name`, and `guard_name`.

## Relationship assignment endpoints

POST adds assignments and DELETE removes assignments. Both accept a list of
names and leave unrelated assignments unchanged. The Flutter UI sends one name
per request whenever a checkbox changes.

| Method | Path | Body | Required permission |
| --- | --- | --- | --- |
| `POST`, `DELETE` | `/roles/{role}/permissions` | `{"permissions":["users.view"]}` | `roles.assign_permissions` |
| `POST`, `DELETE` | `/users/{user}/roles` | `{"roles":["editor"]}` | `users.assign_roles` |
| `POST`, `DELETE` | `/users/{user}/permissions` | `{"permissions":["reports.export"]}` | `users.assign_permissions` |

Assignment pages additionally require catalog view access:

* Role permissions: `roles.assign_permissions` and `permissions.view`
* User roles: `users.assign_roles` and `roles.view`
* User direct permissions: `users.assign_permissions` and `permissions.view`

These view permissions control loading and rendering choices; they do not
replace the mutation permission. `superadmin` satisfies these UI checks only
through the client-side `canAccess(...)` behavior.

Validate that submitted names exist and use Spatie assignment APIs. The API
must apply authorization and validation independently of the Flutter UI.

## Required permissions

Seed these permission names for the three administration modules:

```text
users.view
users.create
users.update
users.delete
users.assign_roles
users.assign_permissions

roles.view
roles.create
roles.update
roles.delete
roles.assign_permissions

permissions.view
permissions.create
permissions.update
permissions.delete
```

Grant a `superadmin` role server-side access to bypass permission checks. Grant
assignment permissions only to administrators who should manage relationships.

## Laravel middleware example

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/users', [UserController::class, 'index'])
        ->middleware('permission:users.view');
    Route::post('/users', [UserController::class, 'store'])
        ->middleware('permission:users.create');
    Route::put('/users/{user}', [UserController::class, 'update'])
        ->middleware('permission:users.update');
    Route::delete('/users/{user}', [UserController::class, 'destroy'])
        ->middleware('permission:users.delete');

    Route::get('/roles', [RoleController::class, 'index'])
        ->middleware('permission:roles.view');
    Route::post('/roles', [RoleController::class, 'store'])
        ->middleware('permission:roles.create');
    Route::put('/roles/{role}', [RoleController::class, 'update'])
        ->middleware('permission:roles.update');
    Route::delete('/roles/{role}', [RoleController::class, 'destroy'])
        ->middleware('permission:roles.delete');

    Route::get('/permissions', [PermissionController::class, 'index'])
        ->middleware('permission:permissions.view');
    Route::post('/permissions', [PermissionController::class, 'store'])
        ->middleware('permission:permissions.create');
    Route::put('/permissions/{permission}', [PermissionController::class, 'update'])
        ->middleware('permission:permissions.update');
    Route::delete('/permissions/{permission}', [PermissionController::class, 'destroy'])
        ->middleware('permission:permissions.delete');

    Route::post('/roles/{role}/permissions', [RoleAccessController::class, 'grantPermissions'])
        ->middleware('permission:roles.assign_permissions');
    Route::delete('/roles/{role}/permissions', [RoleAccessController::class, 'revokePermissions'])
        ->middleware('permission:roles.assign_permissions');
    Route::post('/users/{user}/roles', [UserAccessController::class, 'assignRoles'])
        ->middleware('permission:users.assign_roles');
    Route::delete('/users/{user}/roles', [UserAccessController::class, 'unassignRoles'])
        ->middleware('permission:users.assign_roles');
    Route::post('/users/{user}/permissions', [UserAccessController::class, 'grantPermissions'])
        ->middleware('permission:users.assign_permissions');
    Route::delete('/users/{user}/permissions', [UserAccessController::class, 'revokePermissions'])
        ->middleware('permission:users.assign_permissions');
});
```

Configure Laravel Sanctum CORS for every web origin used by Flutter web, and
use HTTPS or localhost for `flutter_secure_storage` in browsers.
