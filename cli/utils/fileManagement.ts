import { existsSync, mkdirSync, writeFileSync } from "fs";
import { confirmation, createLoadingAnimation, warning } from "./outputMesages";

/**
 * Checks if a directory exists at the given path, creates it if not
 *
 * Validates the existence of the specified directory path.
 * If the directory does not exist, it creates it and provides
 * user feedback through loading animations and confirmation messages.
 *
 * @param {string} path - Directory path to check/create
 */
export async function checkDirectoryPath(path: string) {
  if (existsSync(path)) return;

  warning(`Directory not found at ${path}`);
  const { start, stop } = createLoadingAnimation(`Creating ${path}...`);
  start();
  mkdirSync(path, { recursive: true });
  await stop(2000);
  confirmation(`${path} created.`);
}

export async function writeFilePath(path: string, content: string) {
  const { start, stop } = createLoadingAnimation(
    `Creating file at ${path}...`,
    "sand"
  );
  start();

  await Bun.write(path, content);

  await stop(1500);
}
