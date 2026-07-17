import pluginWebc from "@11ty/eleventy-plugin-webc";
import { InputPathToUrlTransformPlugin } from "@11ty/eleventy";
import { eleventyImagePlugin } from "@11ty/eleventy-img";
import bundlerPlugin from "@11ty/eleventy-plugin-bundle";
import postcss from "postcss";
import autoprefixer from "autoprefixer";
import cssnano from "cssnano";
import htmlmin from "html-minifier";
import utopia from "postcss-utopia";

const core11tyOptions = {
	dir: {
		input: "src/routes",
		output: "docs",
		includes: "../includes",  // relative to input directory
		layouts: "../layouts",    // relative to input directory
		data: "../data"           // relative to input directory
	}
};

/** @param {import('@11ty/eleventy').UserConfig} eleventyConfig */
export default function(eleventyConfig) {
	eleventyConfig.ignores.add("README.md");

	// Required by pluginWebc.
	eleventyConfig.addPlugin(InputPathToUrlTransformPlugin);

	// Webc components "autoload" + load "vendor" components.
	eleventyConfig.addPlugin(pluginWebc, {
		components: [
			"./src/components/**/*.webc",
			"npm:@11ty/is-land/*.webc",
			"npm:@11ty/eleventy-img/*.webc"
		]
	});

	// HTML minification.
	eleventyConfig.addTransform("htmlmin", function (content) {
		if (this.page.outputPath && this.page.outputPath.endsWith(".html")) {
			let minified = htmlmin.minify(content, {
				useShortDoctype: true,
				removeComments: true,
				collapseWhitespace: true,
			});
			return minified;
		}
		return content;
	});

	// CSS + JS optimization.
	eleventyConfig.addPlugin(bundlerPlugin, {
		transforms: [
			async function(content) {
				if (this.type === 'css') {
					// Same as Eleventy transforms, this.page is available here.
					const result = await postcss([utopia, autoprefixer, cssnano]).process(content, {
						from: this.page.inputPath,
						to: null
					});
					return result.css;
				}
				return content;
			}
		]
	});

	// Images optimization.
	eleventyConfig.addPlugin(eleventyImagePlugin, {
		formats: ["webp", "jpeg"],
		urlPath: "/img/optimized/",
		defaultAttributes: {
			loading: "lazy",
			decoding: "async",
		},
	});

	eleventyConfig.setServerOptions({
		domDiff: false
	});

	// "Static" assets (e.g. logo img, favicon, robots.txt, etc).
	eleventyConfig.addPassthroughCopy({ "src/static": '.' });

	return core11tyOptions;
};
