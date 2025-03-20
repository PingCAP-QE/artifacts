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

async function generateShellScript(
  imageUrlWithTag: string,
  yamlFile: string,
  outFile: string,
) {
  // Extract image URL and tag
  const [imageUrl, tag] = imageUrlWithTag.split(":");

  // Read YAML config
  const config = yaml.parse(
    await Deno.readTextFile(yamlFile),
  ) as { image_copy_rules: Config };

  // Retrieve rules for the source repository from the YAML config
  const rules = (config.image_copy_rules[imageUrl] || []).filter((r) =>
    r.tags_regex.some((regex) => new RegExp(regex).test(tag))
  );

  rules.forEach((r) => {
    r.tags_regex = r.tags_regex.filter((regex) => new RegExp(regex).test(tag));
  });

  if (rules.length === 0) {
    console.info("🤷 No delivery rule matched.");
    return;
  }

  // Open output file
  const file = await Deno.open(outFile, {
    create: true,
    write: true,
    truncate: true,
  });

  // Loop through rules
  for (const rule of rules) {
    const {
      description = "",
      dest_repositories,
      constant_tags = [],
      tag_regex_replace = "",
      tags_regex = [],
    } = rule;

    console.log(
      `Matching rule found for image URL '${imageUrlWithTag}':`,
    );
    console.log(`\tDescription: ${description}`);
    console.log(`\tSource Repository: ${imageUrl}`);

    // Copy image to destination repositories using crane copy command
    for (const destRepo of dest_repositories) {
      console.log(`\tDestination Repository: ${destRepo}`);
      await file.write(
        new TextEncoder().encode(
          `crane copy ${imageUrlWithTag} ${destRepo}:${tag}\n`,
        ),
      );
      for (const constTag of constant_tags) {
        console.log(`\tAdditional tag: ${constTag}`);
        await file.write(
          new TextEncoder().encode(
            `crane tag ${destRepo}:${tag} ${constTag}\n`,
          ),
        );
      }
      if (tag_regex_replace != "") {
        const converted = tag.replace(
          new RegExp(tags_regex[0]),
          tag_regex_replace,
        );
        console.log(`\tAdditional tag: ${converted}`);
        await file.write(
          new TextEncoder().encode(
            `crane tag ${destRepo}:${tag} ${converted}\n`,
          ),
        );
      }
    }
  }

  // Close output file
  file.close();
}

// Parse command-line arguments
const {
  image_url,
  yaml_file = "./packages/delivery.yaml",
  outfile = "./delivery-images.sh",
} = parseArgs(Deno.args);

// Example usage
await generateShellScript(image_url, yaml_file, outfile);
