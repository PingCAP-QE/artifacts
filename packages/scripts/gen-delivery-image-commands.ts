#!/usr/bin/env -S deno run --allow-read --allow-write
import * as yaml from "jsr:@std/yaml@1.0.5";
import { parseArgs } from "jsr:@std/cli@1.0.9";

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
    throw new Error(
      `Image reference "${imageUrlWithTag}" contains a digest. Please provide a tag-based reference.`,
    );
  }
  if (lastColon === -1 || lastColon < lastSlash) {
    throw new Error(
      `Image reference "${imageUrlWithTag}" must include a tag (e.g., repo/image:tag).`,
    );
  }
  return {
    repo: imageUrlWithTag.slice(0, lastColon),
    tag: imageUrlWithTag.slice(lastColon + 1),
  };
}

async function loadImageCopyRules(yamlFile: string): Promise<Config> {
  const parsed = yaml.parse(await Deno.readTextFile(yamlFile)) as {
    image_copy_rules: Config;
  } | null;
  if (!parsed || typeof parsed !== "object" || !parsed.image_copy_rules) {
    throw new Error(`Invalid delivery rules file: ${yamlFile}`);
  }
  return parsed.image_copy_rules;
}

function getMatchingRulesFor(
  imageUrl: string,
  tag: string,
  rulesConfig: Config,
): Rule[] {
  return (rulesConfig[imageUrl] || [])
    .map((r) => ({
      ...r,
      tags_regex: r.tags_regex.filter((regex) => new RegExp(regex).test(tag)),
    }))
    .filter((r) => r.tags_regex.length > 0);
}

async function writeOutputFile(outFile: string, content: string | undefined) {
  if (!content) {
    return;
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
    console.group(`🛬 Destination Repository: ${destRepo}`);

    commands.push(`crane copy ${repo}:${tag} ${destRepo}:${tag}`);
    targetImages.push(`${destRepo}:${tag}`);
    for (const constTag of constant_tags) {
      console.log(`📌 Additional tag: ${constTag}`);
      commands.push(`crane tag ${destRepo}:${tag} ${constTag}`);
      targetImages.push(`${destRepo}:${constTag}`);
    }
    if (tag_regex_replace !== "" && tags_regex.length > 0) {
      const converted = tag.replace(
        new RegExp(tags_regex[0]),
        tag_regex_replace,
      );
      console.log(`📌 Additional tag: ${converted}`);
      commands.push(`crane tag ${destRepo}:${tag} ${converted}`);
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

  const ret = rules.map((rule) => copyCommandsForRule(repo, tag, rule));

  return {
    commands: ret.flatMap((r) => r.commands),
    targetImages: ret.flatMap((r) => r.targetImages),
  };
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

    return [
      ...new Set([
        image.tag,
        ...(image.tags ?? []),
        ...(image.multi_arch_tags ?? []),
      ]),
    ]
      .filter((t): t is string => typeof t === "string" && t.length > 0)
      .map((t) => ({ repo, tag: t }));
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
  const rets = images.flatMap((image) =>
    getCopyCommandsForImage(image.repo, image.tag, rulesConfig)
  );

  const commands = rets.flatMap((ret) => ret.commands);
  const targetImages = rets.flatMap((ret) => ret.targetImages);
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
