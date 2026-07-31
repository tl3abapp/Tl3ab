# تلعب؟ (Padel App)

Two separate projects:

- Flutter app: `./`
- NestJS API: `./padel-api`

## 1) Run backend (local)

```bash
cd padel-api
cp .env.example .env
npm install
npm run start:dev
```

Default local API URL:
- `http://127.0.0.1:3000`

## 2) Run Flutter app

iOS/macOS:

```bash
flutter run --dart-define=PADEL_API_URL=http://127.0.0.1:3000
```

Android emulator:

```bash
flutter run --dart-define=PADEL_API_URL=http://10.0.2.2:3000
```

Web:

```bash
flutter run -d chrome --dart-define=PADEL_API_URL=http://127.0.0.1:3000
```

## 3) Web build (easy upload)

```bash
flutter build web --release --dart-define=PADEL_API_URL=https://YOUR-API.onrender.com
```

Upload the generated `build/web` folder to any static host (Vercel/Netlify/Cloudflare Pages).

## 4) Mobile release builds

Use your production API URL in every store build. Do not ship with localhost.

Android App Bundle:

```bash
flutter build appbundle --release --dart-define=PADEL_API_URL=https://YOUR-API.onrender.com
```

Android APK for direct testing:

```bash
flutter build apk --release --dart-define=PADEL_API_URL=https://YOUR-API.onrender.com
```

iOS archive prep without code signing:

```bash
flutter build ios --release --no-codesign --dart-define=PADEL_API_URL=https://YOUR-API.onrender.com
```

For Play Store signing, copy `android/key.properties.example` to `android/key.properties`, create an upload keystore, and keep both `android/key.properties` and the `.jks` file private. They are ignored by git.

Release identifiers:

- Android application id: `com.tl3abapp.tl3ab`
- iOS bundle id: `com.tl3abapp.tl3ab`

## 5) Backend deploy (Render + Neon)

- Set `DATABASE_URL` to your Neon Postgres URL.
- Set `DB_SYNC=true` for MVP auto schema sync.
- Start command on Render:

```bash
npm run start:prod
```

## Notes

- App name: `تلعب؟`
- Profile photo is persisted in backend and also cached locally for safer restore after sign out/sign in.
- Account controls include:
  - deactivate for 40 days (scheduled deletion)
  - reactivate account
  - permanent delete
- Notifications are available in-app (including invite/join updates).
- Smartwatch support uses mirrored phone notifications (Apple Watch / Wear OS).
