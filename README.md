# myperformance-driver

## Signature Bridge (.NET 8 WPF)

- Project: `SignatureBridge`
- Local API:
  - `GET http://localhost:12345/show?url=https://...`
  - `GET http://localhost:12345/idle`
  - `GET http://localhost:12345/status`
- Config file: `SignatureBridge/config.json`
  - `LogoUri` (image displayed in idle state)
  - `PreferredScreenDeviceName` (optional monitor device name)
  - `PreferredResolution` (optional fallback like `1024x600`)
  - `ApiToken` (optional; if set, include `token` query or `X-SignatureBridge-Token` header)
- Installer script: `installer/SignatureBridge.iss`
