// Shared parsing and validation for `packages/delivery.yaml`.
//
// Two scripts read the same rule file and both put what they read into shell
// commands: `gen-delivery-image-commands.ts` emits the `crane` commands that the
// delivery job runs with push credentials, and `get-delivery-target-images.ts`
// lists the expected targets for the release GA wait gate. Validating the rules
// and the values in one place keeps the two readers from drifting apart, and
// keeps a permissive rule from becoming a shell injection.

// Caps for the rule regexes. Tags are short and the rules are ours, so anything
// longer is a mistake or an attempt to make matching expensive.
export const MAX_REGEX_LENGTH = 128;

export const REPOSITORY_RE = /^[a-z0-9.-]+(:[0-9]+)?\/[a-z0-9._/-]+$/;
export const TAG_RE = /^[A-Za-z0-9][A-Za-z0-9._+-]{0,127}$/;

export interface Rule {
  description?: string;
  tags_regex: string[];
  dest_repositories: string[];
  constant_tags?: string[];
  tag_regex_replace?: string;
}

export interface Config {
  [sourceRepo: string]: Rule[];
}

/** Report a bad input the same way in both scripts and stop. */
export function fail(message: string): never {
  console.error(`❌ ${message}`);
  Deno.exit(2);
}

/** Compile a rule regex, refusing input that is oversized or obviously quadratic. */
export function compileRuleRegex(source: string, where: string): RegExp {
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

export function assertStringArray(
  value: unknown,
  where: string,
  options: { minItems: number; pattern?: RegExp; label: string },
): string[] {
  if (!Array.isArray(value)) {
    fail(`${where}: ${options.label} must be a list`);
  }
  if (value.length < options.minItems) {
    fail(
      `${where}: ${options.label} must have at least ${options.minItems} item(s)`,
    );
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
 * This is the subset of schemas/delivery-schema.json the scripts actually
 * depend on: a wrong shape here used to surface as a TypeError halfway through
 * the run, after some targets had already been emitted.
 */
export function validateDeliveryConfig(raw: unknown): Config {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    fail("delivery config must be a mapping");
  }
  const rules = (raw as Record<string, unknown>).image_copy_rules;
  if (rules === null || typeof rules !== "object" || Array.isArray(rules)) {
    fail("delivery config is missing the image_copy_rules mapping");
  }

  const config: Config = {};
  for (
    const [sourceRepo, value] of Object.entries(
      rules as Record<string, unknown>,
    )
  ) {
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

/** Rules whose `tags_regex` matches this tag, with only the matching regexes kept. */
export function getMatchingRulesFor(
  imageUrl: string,
  tag: string,
  rulesConfig: Config,
): Rule[] {
  return (rulesConfig[imageUrl] || [])
    .map((r) => ({
      ...r,
      tags_regex: r.tags_regex.filter((regex) =>
        compileRuleRegex(regex, imageUrl).test(tag)
      ),
    }))
    .filter((r) => r.tags_regex.length > 0);
}

/**
 * Quote a value for a single-quoted POSIX shell word.
 *
 * The values that reach a generated script are already restricted by the regexes
 * above, so this is defence in depth: it keeps the emitted script correct even
 * if a future rule grows a character the regexes allow but the shell treats
 * specially.
 */
export function shellQuote(value: string): string {
  return `'${value.replaceAll("'", "'\\''")}'`;
}
