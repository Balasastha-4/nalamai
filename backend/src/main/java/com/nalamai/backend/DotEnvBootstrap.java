package com.nalamai.backend;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Loads {@code .env} into system properties before Spring starts so JDBC and other
 * {@code ${ENV:default}} placeholders work under DevTools (restart classloader breaks
 * {@code spring.config.import} file paths that are relative to {@code target/classes}).
 */
final class DotEnvBootstrap {

	private DotEnvBootstrap() {
	}

	static void loadLocalEnvFiles() {
		String userDir = System.getProperty("user.dir");
		if (userDir == null || userDir.isBlank()) {
			return;
		}
		Path base = Path.of(userDir);
		Map<String, String> merged = new LinkedHashMap<>();
		// Repo-root .env first, then cwd .env overrides (e.g. backend/.env when cwd is backend/)
		mergeInto(merged, base.resolve("..").resolve(".env").normalize());
		mergeInto(merged, base.resolve(".env"));
		for (Map.Entry<String, String> e : merged.entrySet()) {
			String key = e.getKey();
			if (System.getenv(key) != null) {
				continue;
			}
			if (System.getProperty(key) != null) {
				continue;
			}
			System.setProperty(key, e.getValue());
		}
	}

	private static void mergeInto(Map<String, String> target, Path file) {
		if (!Files.isRegularFile(file)) {
			return;
		}
		try {
			for (String raw : Files.readAllLines(file, StandardCharsets.UTF_8)) {
				String line = raw.trim();
				if (line.isEmpty() || line.startsWith("#")) {
					continue;
				}
				int eq = line.indexOf('=');
				if (eq <= 0) {
					continue;
				}
				String key = line.substring(0, eq).trim();
				String value = line.substring(eq + 1).trim();
				if (value.length() >= 2
						&& ((value.startsWith("\"") && value.endsWith("\""))
								|| (value.startsWith("'") && value.endsWith("'")))) {
					value = value.substring(1, value.length() - 1);
				}
				if (!key.isEmpty()) {
					target.put(key, value);
				}
			}
		} catch (IOException ignored) {
			// optional local files
		}
	}
}
