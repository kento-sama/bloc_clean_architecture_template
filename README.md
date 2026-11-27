# Flutter Laravel Clean Architecture Template

A responsive Flutter client template for applications backed by a Laravel API.
It combines feature-first organization, Clean Architecture, flutter_bloc, GoRouter,
Bootstrap breakpoints, secure token storage, and permission-aware navigation.
Sanctum and Spatie-style role and permission data are supported by the example
auth flow.

User, role, and permission features are included as implementation
examples. They are not required for every project created from this template.
The Laravel contract is documented in
[docs/laravel-api-contract.md](docs/laravel-api-contract.md).

## Requirements

- Flutter and Dart SDK versions declared in `pubspec.yaml`
- A Laravel API that exposes the endpoints used by the project
- HTTPS in production
- A secure, CORS-configured API origin

## Setup

1. Copy `.env.example` to `.env`.
2. Set `API_BASE_URL` to the Laravel API base URL:

   ```text
   API_BASE_URL=https://api.example.com/api
   ```

3. Install packages and generate the Envied configuration:

   ```sh
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:

   ```sh
   flutter run
   ```

Envied reads `API_BASE_URL` while code is generated. Regenerate after changing
the `.env` file. Bundled environment values are not secrets.

For web deployments, secure storage requires HTTPS or localhost. Configure
Laravel CORS for every web origin that can access the API.

## Rename the project

Rename the Dart package and project metadata with the Makefile command:

```sh
make rename-project inventory_app
```

Use a lowercase snake-case name. The command:

- Updates `name:` in `pubspec.yaml`.
- Replaces package imports such as `package:bloc_clean_architecture_template/` in Dart files.
- Updates web manifest and HTML titles derived from the previous project name.
- Renames root `.iml` files, including `*_android.iml` files.
- Updates IntelliJ module references in `.idea/**/*.xml`.

The package name can also be changed directly with Dart:

```sh
dart run bin/rename_project.dart inventory_app
```

After renaming, run package generation and resolve dependencies again:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Project structure

```text
lib/
  core/
    config/          API and environment configuration
    data/            shared HTTP client and secure storage
    presentation/    shared widgets and responsive helpers
    routing/         router, authentication, and route guards
  features/
    auth/
    dashboard/
    <module>/
  app_modules.dart   feature composition registry
  main.dart          application entry point
```

Each feature belongs under `lib/features/<module>/` and follows this layout:

```text
<module>/
  <module>_config.dart
  <module>_feature.dart
  domain/
    entities/
    repositories/
    usecases/
  data/
    models/
    datasources/
    repositories/
  presentation/
    cubits/
    screens/
    widgets/
```

Dependencies point inward:

- Domain code contains entities, contracts, and use cases.
- Data code implements repositories and maps API responses to models/entities.
- Presentation code contains BLoC/Cubit classes and Flutter widgets.
- Feature entry files provide route metadata, icons, permissions, and pages.

## Learning the architecture

The codebase is arranged as a guided Clean Architecture example:

- **Entity** files are framework-independent business objects.
- **Repository interfaces** describe what the application needs, not how HTTP
  or secure storage implements it.
- **Use cases** expose one small application operation to presentation code.
- **Models** convert Laravel JSON into entities and validate required fields.
- **Remote data sources** own Dio calls, paths, request payloads, and envelopes.
- **Repository implementations** translate remote responses and persist tokens.
- **Cubits** emit loading, success, and failure states for presentation widgets.
- **Screens** render state and collect user input without implementing API rules.
- **Routers** centralize navigation and UI route guards.

Focused comments explain each boundary. Security rules and OTP validation must
still be enforced by Laravel; client-side comments, permission checks, and
route redirects are usability and defense-in-depth measures.

## Scaffold a module

Create a module using a lowercase snake-case name:

```sh
dart run bin/clean_module.dart watchlist
```

The command creates:

- Domain entity, repository contract, and use cases
- Data model, remote data source, and repository implementation
- BLoC/Cubit presentation state
- Responsive list and form screens
- Reusable action widgets
- Feature configuration and feature entry
- Addressable create and edit routes

The generator does not modify `lib/app_modules.dart` or add Laravel routes.
After generating a module:

1. The generator registers the Cubit in `lib/app.dart`, the feature in
   `lib/app_modules.dart`, and create/edit routes in
   `lib/core/routing/app_router.dart`.
2. Replace the example API paths and entity fields with the real contract.
3. Add matching Laravel routes and authorization middleware.

Remove a generated module:

```sh
dart run bin/remove_clean_module.dart watchlist
```

Removal requires confirmation and removes only
`lib/features/watchlist/`. Remove its app-module registration separately.

Package imports are generated from the `name:` value in `pubspec.yaml`, so
renaming the Flutter package does not require changing template imports.

## Navigation

GoRouter owns application routes. The app uses route redirects for:

- Restoring the signed-in session
- Redirecting unauthenticated users
- Checking feature view permissions
- Checking create and update permissions on form routes
- Handling direct URL refreshes

Create and edit forms are addressable by route:

```text
/module/create
/module/:id/edit
```

The edit route receives the selected entity through GoRouter `extra` for normal
navigation. Direct URL refreshes may not have that entity state and should
return to the module list or load the record by ID.

## Account and security

The dashboard profile action opens `/account`, which displays the signed-in
user's name, email, account ID, roles, and current 2FA state. Security settings
are intentionally one level deeper at `/account/security`.

Both account screens watch `AuthCubit` rather than duplicating session data.
After 2FA activation or deactivation, the Cubit refreshes the signed-in user
from the API so the UI reflects server-confirmed state.

The 2FA flow supports OTP login challenges, authenticator setup by QR code or
manual Base32 secret entry and confirmation, password-and-OTP deactivation,
and password confirmation for account deletion. The Flutter app does not
generate or verify OTPs; Laravel
owns challenge expiration, token issuance, secret storage, and support-led recovery.
See [docs/laravel-api-contract.md](docs/laravel-api-contract.md).

Use `AppBackButton` for pages that need a stable back action. It pops an
existing route and falls back to a module or dashboard route for direct URLs.

## Authorization

Client authorization improves navigation and usability, but is not a security
boundary.

Use `AuthUser.canAccess(permission)` for UI checks:

```dart
if (user?.canAccess(moduleCreatePermission) ?? false) {
  // Show create action.
}
```

`canAccess(permission)` grants access when:

- The user has the named permission, or
- The user has the `superadmin` role.

Apply matching checks to route redirects and form widgets for defense in depth.
The same rules must be enforced by Laravel:

- Require authentication with Sanctum or the selected auth system.
- Apply permission middleware to view, create, update, and delete routes.
- Grant `superadmin` the server-side ability to bypass permission checks.
- Validate ownership and input independently of the client.

The API should return effective permissions and role names for the signed-in
user so Flutter can render the correct features and controls.

## Responsive layouts

Layouts use available width rather than platform names. Bootstrap breakpoints
are:

| Name | Minimum logical width |
| --- | ---: |
| xs | 0 px |
| sm | 576 px |
| md | 768 px |
| lg | 992 px |
| xl | 1200 px |
| xxl | 1400 px |

The default wide layout starts at `md` (768 px). It can be overridden per
widget with `ResponsiveLayout.breakpoint`.

## Testing

Run static analysis and tests:

```sh
flutter analyze
flutter test
```

Tests should cover:

- Entity and API model parsing
- Repository and use-case behavior
- Permission and superadmin authorization
- Narrow and wide layouts
- Create/edit route navigation
- Widget authorization fallbacks
