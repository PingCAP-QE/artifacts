#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net
import * as yaml from "jsr:@std/yaml@1.0.5";
import { parseArgs } from "jsr:@std/cli@1.0.9";
import { retryAsync } from "https://deno.land/x/retry@v2.0.0/mod.ts";
import { parse, parseRange, satisfies } from "jsr:@std/semver@^1.0.3";
import {
  compileRuleRegex,
  fail,
  REPOSITORY_RE,
  type Config,
  type Rule,
  validateDeliveryConfig,
} from "./lib/delivery-config.ts";

// Hosts a remote delivery config may be loaded from. The release pipeline reads
// it from jsDelivr; add a host here only after deciding it is trusted.
const ALLOWED_CONFIG_HOSTS = ["cdn.jsdelivr.net"];

/**
 * Decide where the delivery config comes from and refuse anything else.
 * Returns the URL for a remote config, or null for a local path.
 */
function resolveConfigRef(configRef: string): URL | null {
  // Anything with a scheme is treated as remote (file:, http:, ftp:, ...).
  if (/^[A-Za-z][A-Za-z0-9+.-]*:/.test(configRef)) {
    let url: URL;
    try {
      url = new URL(configRef);
    } catch {
      fail("invalid delivery config reference: not a valid URL");
    }
    if (url.protocol !== "https:") {
      fail(
        `invalid delivery config reference: only https is accepted, got ${url.protocol}`,
      );
    }
    if (url.username !== "" || url.password !== "") {
      fail("invalid delivery config reference: userinfo is not allowed");
    }
    if (!ALLOWED_CONFIG_HOSTS.includes(url.hostname)) {
      fail(
        `invalid delivery config reference: ${url.origin} is not an allowed host ` +
          `(${ALLOWED_CONFIG_HOSTS.join(", ")})`,
      );
    }
    if (url.pathname.split("/").includes("..")) {
      fail("invalid delivery config reference: path traversal is not allowed");
    }
    return url;
  }

  if (configRef.split(/[/\\]/).includes("..")) {
    fail("invalid delivery config path: path traversal is not allowed");
  }
  return null;
}

function srcImages(
  version: string,
  registry: string,
) {
  const images = [
    "pingcap/tidb/images/br",
    "pingcap/tidb/images/dumpling",
    "pingcap/tidb/images/tidb-lightning",
    "pingcap/tidb/images/tidb-server",
    "pingcap/monitoring/image",
    "pingcap/ng-monitoring/image",
    "pingcap/tidb-dashboard/image",
    "pingcap/tiflash/image",
    "pingcap/tiflow/images/cdc",
    "pingcap/tiflow/images/dm",
    "pingcap/tiflow/images/tiflow",
    "tikv/pd/image",
    "tikv/tikv/image",
  ];

  // "tidb-binlog" repo stops to release since 8.4.0, but the history release branches is still there and keep releasing patches.
  const binlogAliveRange = parseRange("<8.4.0-0");
  if (satisfies(parse(version), binlogAliveRange)) {
    images.push("pingcap/tidb-binlog/image");
  }

  // "ticdc" repo will release from from 9.0.0, it's a new repo for new CDC component.
  const ticdcStartedRange = parseRange(">=9.0.0-0");
  if (!satisfies(parse(version), ticdcStartedRange)) {
    images.push("pingcap/ticdc/image");
  }

  const enterpriseImages = [
    "pingcap/tidb/images/br",
    "pingcap/tidb/images/dumpling",
    "pingcap/tidb/images/tidb-lightning",
    "pingcap/tidb/images/tidb-server",
    "pingcap/tiflash/image",
    "tikv/pd/image",
    "tikv/tikv/image",
  ];

  const ret: string[] = [];
  for (const img of images) {
    ret.push(`${registry}/${img}:${version}`);
  }
  for (const img of enterpriseImages) {
    ret.push(`${registry}/${img}:${version}-enterprise`);
  }

  return ret;
}

function getDeliveryTargetImages(imageUrlWithTag: string, config: Config) {
  const [imageUrl, tag] = imageUrlWithTag.split(":");
  const ret: string[] = [];

  // Retrieve rules for the source repository from the YAML config
  (config[imageUrl] || [])
    .filter((r) => r.tags_regex.some((regex) => new RegExp(regex).test(tag)))
    .forEach((rule) => {
      const {
        dest_repositories,
        constant_tags = [],
        tag_regex_replace = "",
        tags_regex = [],
      } = rule;

      for (const destRepo of dest_repositories) {
        ret.push(`${destRepo}:${tag}`);
        for (const constTag of constant_tags) {
          ret.push(`${destRepo}:${constTag}`);
        }
        if (tag_regex_replace != "") {
          const converted = tag.replace(
            new RegExp(tags_regex[0]),
            tag_regex_replace,
          );
          ret.push(`${destRepo}:${converted}`);
        }
      }
    });

  return ret;
}

async function main(
  version: string,
  registry: string,
  configFileOrUrl: string,
  outFile: string,
) {
  if (!REPOSITORY_RE.test(registry)) {
    fail("invalid --registry: not a registry/repository reference");
  }
  try {
    parse(version);
  } catch {
    fail("invalid --version: not a semantic version");
  }

  // Read delivery config, from a local path or an allowlisted https URL only.
  const remote = resolveConfigRef(configFileOrUrl);
  let yamlContent: string;
  if (remote) {
    const response = await retryAsync(
      async () => await fetch(remote),
      { delay: 1000, maxTry: 5 },
    );
    if (!response.ok) {
      fail(
        `failed to load the delivery config: HTTP ${response.status} from ${remote.origin}`,
      );
    }
    yamlContent = await response.text();
  } else {
    yamlContent = await Deno.readTextFile(configFileOrUrl);
  }

  const config = validateDeliveryConfig(yaml.parse(yamlContent));
  const dstImages = srcImages(version, registry).map((srcImage) =>
    getDeliveryTargetImages(srcImage, config)
  ).flat();

  // Save results.
  const contentStr = yaml.stringify(dstImages);
  await Deno.writeTextFile(outFile, contentStr, {
    create: true,
    append: false,
  });
  console.info("✅ target image urls are saved in ", outFile);
}

// Parse command-line arguments
const {
  version,
  registry = "us-docker.pkg.dev/pingcap-testing-account/hub",
  config = "./packages/delivery.yaml",
  save_to = "./delivery-target-images.yaml",
} = parseArgs(Deno.args);

// Example usage
// ./get-delivery-target-images.ts --config=../delivery.yaml --version=v8.5.0
await main(version, registry, config, save_to);
Deno.exit(0);
