import { readdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";

const replacements = [
  {
    path: "mobile/packages/luqa_api/lib/model/create_session_request.dart",
    generated:
      "'CreateSessionRequest[email=$email, password=$password, deviceId=$deviceId, deviceName=$deviceName]'",
    safe:
      "'CreateSessionRequest[email=$email, password=[REDACTED], deviceId=$deviceId, deviceName=$deviceName]'",
  },
  {
    path: "mobile/packages/luqa_api/lib/model/session_credentials.dart",
    generated:
      "'SessionCredentials[user=$user, accessToken=$accessToken, accessExpiresAt=$accessExpiresAt, refreshToken=$refreshToken, refreshExpiresAt=$refreshExpiresAt]'",
    safe:
      "'SessionCredentials[user=$user, accessToken=[REDACTED], accessExpiresAt=$accessExpiresAt, refreshToken=[REDACTED], refreshExpiresAt=$refreshExpiresAt]'",
  },
];

for (const replacement of replacements) {
  const source = await readFile(replacement.path, "utf8");
  if (!source.includes(replacement.generated)) {
    throw new Error(
      `Generated credential model changed; review redaction for ${replacement.path}`,
    );
  }
  await writeFile(
    replacement.path,
    source.replace(replacement.generated, replacement.safe),
  );
}

async function filesBelow(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  return (
    await Promise.all(
      entries.map((entry) => {
        const path = join(directory, entry.name);
        return entry.isDirectory() ? filesBelow(path) : [path];
      }),
    )
  ).flat();
}

for (const path of await filesBelow("mobile/packages/luqa_api")) {
  if (!path.endsWith(".md")) continue;
  const source = await readFile(path, "utf8");
  const normalized = source.replace(/[ \t]+$/gm, "").replace(/\n+$/, "\n");
  if (source !== normalized) await writeFile(path, normalized);
}
