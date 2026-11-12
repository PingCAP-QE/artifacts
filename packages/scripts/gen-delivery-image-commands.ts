#!/usr/bin/env -S deno run --allow-read --allow-write
import * as yaml from "jsr:@std/yaml@1.0.5";
import { parseArgs } from "jsr:@std/cli@1.0.9";
import {
  type Config,
  fail,
  getMatchingRulesFor,
  REPOSITORY_RE,
  type Rule,
  shellQuote,
  TAG_RE,
  validateDeliveryConfig,
} from "./lib/delivery-config.ts";

interface ImageEntry {
  repo: string;
  tag: string;
  digest?: string;
  tags?: string[];
  multi_arch_tags?: string[];
}

interface ImagesFile {
  images: ImageEntry[];
}

// Utilities
function parseImageRef(imageUrlWithTag: string): {
  repo: string;
  tag: string;
} {
  // Handles refs like: "registry:5000/namespace/repo:tag"
  // Finds the last ":" that appears after the last "/"
  const lastSlash = imageUrlWithTag.lastIndexOf("/");
  const lastColon = imageUrlWithTag.lastIndexOf(":");
  const atIdx = imageUrlWithTag.indexOf("@");
  if (atIdx !== -1) {
    // Digest specified; not supported in single-image mode for matching by tag
    fail(
      `Image reference "${imageUrlWithTag}" contains a digest. Please provide a tag-based reference.`,
    );
  }
  if (lastColon === -1 || lastColon < lastSlash) {
    fail(
      `Image reference "${imageUrlWithTag}" must include a tag (e.g., repo/image:tag).`,
    );
  }
  const repo = imageUrlWithTag.slice(0, lastColon);
  const tag = imageUrlWithTag.slice(lastColon + 1);
  assertImageRef(repo, tag, "image reference");
  return { repo, tag };
}

/**
 * The source repo and tag come from the build stage's result file and end up in
 * the `crane` commands the delivery job runs with push credentials, so a value
 * outside the expected character set must stop the run instead of being quoted
 * into a shell script.
 */
function assertImageRef(repo: string, tag: string, where: string) {
  if (!REPOSITORY_RE.test(repo)) {
    fail(`${where}: "${repo}" is not a valid repository reference`);
  }
  if (!TAG_RE.test(tag)) {
    fail(`${where}: "${tag}" is not a valid image tag`);
  }
}

async function loadImageCopyRules(yamlFile: string) {
  let parsed: unknown = null;
  try {
    parsed = yaml.parse(await Deno.readTextFile(yamlFile));
  } catch (error) {
    fail(`cannot read delivery rules file ${yamlFile}: ${error}`);
  }
  return validateDeliveryConfig(parsed);
}

async function writeOutputFile(outFile: string, content: string | undefined) {
  if (!content) {
    return;
  }

  if (outFile.length === 0 || outFile.split(/[/\\]/).includes("..")) {
    fail(`refusing to write to output path "${outFile}"`);
  }

  using file = await Deno.open(outFile, {
    create: true,
    write: true,
    truncate: true,
  });

  await file.write(new TextEncoder().encode(content));
}

function copyCommandsForRule(
  repo: string,
  tag: string,
  rule: Rule,
) {
  const {
    description = "",
    dest_repositories,
    constant_tags = [],
    tag_regex_replace = "",
    tags_regex = [],
  } = rule;

  const commands: string[] = [];
  const targetImages: string[] = [];
  console.group(`🎯 Matching rule found for image URL '${repo}:${tag}':`);
  console.log(`📜 Description: ${description}`);
  console.log(`🛫 Source Repository: ${repo}`);
  for (const destRepo of dest_repositories) {
    if (!REPOSITORY_RE.test(destRepo)) {
      fail(
        `delivery rule for '${repo}': "${destRepo}" is not a valid destination repository`,
      );
    }
    console.group(`🛬 Destination Repository: ${destRepo}`);

    commands.push(
      `crane copy ${shellQuote(`${repo}:${tag}`)} ${
        shellQuote(`${destRepo}:${tag}`)
      }`,
    );
    targetImages.push(`${destRepo}:${tag}`);
    for (const constTag of constant_tags) {
      if (!TAG_RE.test(constTag)) {
        fail(
          `delivery rule for '${repo}': "${constTag}" is not a valid constant tag`,
        );
      }
      console.log(`📌 Additional tag: ${constTag}`);
      commands.push(
        `crane tag ${shellQuote(`${destRepo}:${tag}`)} ${
          shellQuote(constTag)
        }`,
      );
      targetImages.push(`${destRepo}:${constTag}`);
    }
    if (tag_regex_replace !== "" && tags_regex.length > 0) {
      const converted = tag.replace(
        new RegExp(tags_regex[0]),
        tag_regex_replace,
      );
      if (!TAG_RE.test(converted)) {
        fail(
          `delivery rule for '${repo}': rewritten tag "${converted}" is not a valid image tag`,
        );
      }
      console.log(`📌 Additional tag: ${converted}`);
      commands.push(
        `crane tag ${shellQuote(`${destRepo}:${tag}`)} ${
          shellQuote(converted)
        }`,
      );
      targetImages.push(`${destRepo}:${converted}`);
    }

    console.groupEnd();
  }
  console.groupEnd();

  return { commands, targetImages };
}

// Single-image mode (backward compatible)
function getCopyCommandsForImage(
  repo: string,
  tag: string,
  rulesConfig: Config,
) {
  const rules = getMatchingRulesFor(repo, tag, rulesConfig);
  if (rules.length === 0) {
    console.info(
      `🤷 No delivery rule matched for image URL '${repo}:${tag}'.`,
    );
    return { commands: [], targetImages: [] };
  }

  return rules.reduce(
    (acc, rule) => {
      const { commands, targetImages } = copyCommandsForRule(repo, tag, rule);
      acc.commands.push(...commands);
      acc.targetImages.push(...targetImages);
      return acc;
    },
    { commands: [] as string[], targetImages: [] as string[] },
  );
}

async function parseImagesFromFile(imagesFilePath: string) {
  const imagesFileContent = await Deno.readTextFile(imagesFilePath);
  // yaml.parse can parse JSON as well since JSON is a subset of YAML.
  const parsed = yaml.parse(imagesFileContent) as
    | ImagesFile
    | ImageEntry[]
    | null;

  let images: ImageEntry[];
  if (Array.isArray(parsed)) {
    images = parsed as ImageEntry[];
  } else if (
    parsed && typeof parsed === "object" &&
    Array.isArray((parsed as ImagesFile).images)
  ) {
    images = (parsed as ImagesFile).images;
  } else {
    throw new Error(
      `Invalid images input file: ${imagesFilePath}. Expected an object with an "images" array or an array of image entries.`,
    );
  }

  return images.flatMap((image) => {
    if (!image || typeof image !== "object") return [];

    const repo = image.repo;
    if (typeof repo !== "string" || repo.trim().length === 0) return [];

    const tags = [
      ...new Set([
        image.tag,
        ...(image.tags ?? []),
        ...(image.multi_arch_tags ?? []),
      ]),
    ].filter((t): t is string => typeof t === "string" && t.length > 0);

    for (const tag of tags) assertImageRef(repo, tag, "images file");

    return tags.map((tag) => ({ repo, tag }));
  });
}

// Single-image mode (backward compatible)
async function generateShellScriptSingle(
  imageUrlWithTag: string,
  rulesFile: string,
  commandOutputFile: string,
  targetImagesOutputFile: string,
) {
  const { repo, tag } = parseImageRef(imageUrlWithTag);
  const rulesConfig = await loadImageCopyRules(rulesFile);
  const { commands, targetImages } = getCopyCommandsForImage(
    repo,
    tag,
    rulesConfig,
  );
  if (commands.length === 0) {
    return;
  }

  await writeOutputFile(commandOutputFile, commands.join("\n"));
  await writeOutputFile(
    targetImagesOutputFile,
    yaml.stringify({ images: targetImages }),
  );
}

// Multi-image mode (YAML/JSON structured file)
async function generateShellScriptMulti(
  imagesFilePath: string,
  rulesFile: string,
  commandOutputFile: string,
  targetImagesOutputFile: string,
) {
  const images = await parseImagesFromFile(imagesFilePath);
  const rulesConfig = await loadImageCopyRules(rulesFile);
  const { commands, targetImages } = images.reduce(
    (acc, image) => {
      const result = getCopyCommandsForImage(
        image.repo,
        image.tag,
        rulesConfig,
      );
      acc.commands.push(...result.commands);
      acc.targetImages.push(...result.targetImages);
      return acc;
    },
    { commands: [] as string[], targetImages: [] as string[] },
  );

  if (commands.length === 0) {
    return;
  }

  await writeOutputFile(commandOutputFile, commands.join("\n"));
  await writeOutputFile(
    targetImagesOutputFile,
    yaml.stringify({ images: targetImages }),
  );
}

async function main() {
  const flags = parseArgs(Deno.args, {
    boolean: ["help"],
    string: [
      "image_url",
      "images_file",
      "yaml_file",
      "outfile",
      "images_outfile",
    ],
    default: {
      yaml_file: "./packages/delivery.yaml",
      outfile: "./delivery-images.sh",
      images_outfile: "./delivery-target-images.yaml",
    },
    alias: {
      help: "h",
    },
  });

  function printUsage() {
    console.info(`
Usage: deno run gen-delivery-image-commands.ts --image_url=<repo/image:tag> OR --images_file=<path/to/images.(yaml|json)> [--yaml_file=./packages/delivery.yaml] [--outfile=./delivery-images.sh]

Options:
  -h, --help                                  Show help
  --image_url=<repo/image:tag>                image url
  --images_file=<path/to/images.(yaml|json)>  images file
  --yaml_file=<path/to/delivery.yaml>         delivery rule yaml file
  --outfile=<path/to/delivery-images.sh>      command save to file
  --images_outfile=<path/to/delivery-images.yaml>  output yaml list of '<repo>:<tag>' target images
`);
  }

  if (flags.help) {
    printUsage();
    Deno.exit(0);
  }

  if (!flags.image_url && !flags.images_file) {
    console.error(
      "Error: The '--image_url' or '--images_file' parameter is required.",
    );
    printUsage();
    Deno.exit(1); // Exit with a non-zero status code to indicate an error.
  }

  if (flags.image_url && flags.images_file) {
    console.error(
      "Please provide only one of --image_url or --images_file, not both.",
    );
    printUsage();
    Deno.exit(1);
  }

  if (flags.images_file) {
    await generateShellScriptMulti(
      flags.images_file,
      flags.yaml_file,
      flags.outfile,
      flags.images_outfile,
    );
  } else if (flags.image_url) {
    await generateShellScriptSingle(
      flags.image_url,
      flags.yaml_file,
      flags.outfile,
      flags.images_outfile,
    );
  }
}

if (import.meta.main) {
  await main();
  Deno.exit(0);
}
