import { parse } from "https://deno.land/std@0.194.0/flags/mod.ts";
import * as yaml from "https://deno.land/std@0.214.0/yaml/mod.ts";

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
} = parse(Deno.args);

// Example usage
await generateShellScript(image_url, yaml_file, outfile);
