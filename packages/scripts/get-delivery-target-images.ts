#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net
import * as yaml from "jsr:@std/yaml@1.0.5";
import { parseArgs } from "jsr:@std/cli@1.0.9";
import { retryAsync } from "https://deno.land/x/retry@v2.0.0/mod.ts";
import { parse, parseRange, satisfies } from "jsr:@std/semver@^1.0.3";

// Hosts a remote delivery config may be loaded from. The release pipeline reads
// it from jsDelivr; add a host here only after deciding it is trusted.
const ALLOWED_CONFIG_HOSTS = ["cdn.jsdelivr.net"];

// Caps for the rule regexes. Tags are short and the rules are ours, so anything
// longer is a mistake or an attempt to make matching expensive.
const MAX_REGEX_LENGTH = 128;

const REPOSITORY_RE = /^[a-z0-9.-]+(:[0-9]+)?\/[a-z0-9._/-]+$/;
const TAG_RE = /^[A-Za-z0-9][A-Za-z0-9._+-]{0,127}$/;

interface Rule {
  description?: string;
  tags_regex: string[];
  dest_repositories: string[];
  constant_tags?: string[];
  tag_regex_replace?: string;
}

interface Config {
  [sourceRepo: string]: Rule[];
}

function fail(message: string): never {
  console.error(`❌ ${message}`);
  Deno.exit(2);
}

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

/** Compile a rule regex, refusing input that is oversized or obviously quadratic. */
function compileRuleRegex(source: string, where: string): RegExp {
  if (source.length === 0 || source.length > MAX_REGEX_LENGTH) {
    fail(`${where}: regex length must be 1..${MAX_REGEX_LENGTH}`);
  }
  // `(a+)+`-style nesting is what makes matching blow up; none of our rules use it.
  if (/\([^()]*[*+]\)[*+{]/.test(source)) {
    fail(`${where}: nested quantifier is not allowed`);
  }
  try {
    return new RegExp(source);
  } catch {
    fail(`${where}: invalid regular expression`);
  }
}

function assertStringArray(
  value: unknown,
  where: string,
  options: { minItems: number; pattern?: RegExp; label: string },
): string[] {
  if (!Array.isArray(value)) {
    fail(`${where}: ${options.label} must be a list`);
  }
  if (value.length < options.minItems) {
    fail(`${where}: ${options.label} must have at least ${options.minItems} item(s)`);
  }
  return value.map((item, index) => {
    if (typeof item !== "string") {
      fail(`${where}: ${options.label}[${index}] must be a string`);
    }
    if (options.pattern && !options.pattern.test(item)) {
      fail(`${where}: ${options.label}[${index}] is not a valid value`);
    }
    return item;
  });
}

/**
 * Validate the shape of `image_copy_rules` before any rule is used.
 *
 * This is the subset of schemas/delivery-schema.json the script actually
 * depends on: a wrong shape here used to surface as a TypeError halfway through
 * the run, after some targets had already been emitted.
 */
function validateDeliveryConfig(raw: unknown): Config {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    fail("delivery config must be a mapping");
  }
  const rules = (raw as Record<string, unknown>).image_copy_rules;
  if (rules === null || typeof rules !== "object" || Array.isArray(rules)) {
    fail("delivery config is missing the image_copy_rules mapping");
  }

  const config: Config = {};
  for (const [sourceRepo, value] of Object.entries(rules as Record<string, unknown>)) {
    if (!REPOSITORY_RE.test(sourceRepo)) {
      fail(`invalid image_copy_rules key: not a repository reference`);
    }
    if (!Array.isArray(value)) {
      fail(`invalid image_copy_rules entry: rules must be a list`);
    }
    config[sourceRepo] = value.map((rule, index) => {
      const where = `${sourceRepo}[${index}]`;
      if (rule === null || typeof rule !== "object" || Array.isArray(rule)) {
        fail(`${where}: rule must be a mapping`);
      }
      const fields = rule as Record<string, unknown>;
      const tagsRegex = assertStringArray(fields.tags_regex, where, {
        minItems: 1,
        label: "tags_regex",
      });
      for (const source of tagsRegex) compileRuleRegex(source, where);

      const destRepositories = assertStringArray(
        fields.dest_repositories,
        where,
        { minItems: 1, pattern: REPOSITORY_RE, label: "dest_repositories" },
      );
      const constantTags = fields.constant_tags === undefined
        ? []
        : assertStringArray(fields.constant_tags, where, {
          minItems: 0,
          pattern: TAG_RE,
          label: "constant_tags",
        });

      if (
        fields.tag_regex_replace !== undefined &&
        typeof fields.tag_regex_replace !== "string"
      ) {
        fail(`${where}: tag_regex_replace must be a string`);
      }

      return {
        description: typeof fields.description === "string"
          ? fields.description
          : undefined,
        tags_regex: tagsRegex,
        dest_repositories: destRepositories,
        constant_tags: constantTags,
        tag_regex_replace: fields.tag_regex_replace as string | undefined,
      };
    });
  }
  return config;
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
