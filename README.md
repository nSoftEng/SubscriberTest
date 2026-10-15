<h1 align="center">🧾 SubscriberTest</h1>

<p align="center" style="font-size: 1.2rem">
  A small Ruby sales-tax calculator that turns plain-text receipts into totals,
  classifying unknown products with a local LLM instead of a hardcoded list.
</p>

<hr />

## The problem

Calculating sales tax on a receipt sounds trivial until you have to deal with
exemptions (books, food, medicine), import duties, and rounding rules, all from
nothing but a list of free-text lines like:

```
2 book at 12.49
1 imported bottle of perfume at 27.99
```

The classic version of this exercise ships with a fixed table of
product → category. Real input doesn't come with that table: a new product
description shows up and something has to decide whether it's a book, food,
medicine, or none of those.

## This solution

SubscriberTest parses raw receipt text into domain objects, asks a local
[Ollama](https://ollama.com) model to classify each product description it
doesn't already know how to categorize, and applies tax rules to produce a
formatted receipt with taxes and totals — without needing a predefined
product/category table.

- **`InputParser`** — turns each `"<qty> <description> at <price>"` line into a `LineItem`, skipping blank or malformed lines
- **`ProductClassifier`** — asks a local LLM (via Ollama) which category a product description falls into, and defaults to `:other` if it can't get a confident answer
- **`TaxCalculator`** + **`TaxRule`** — pluggable rules (`BasicSalesTaxRule`, `ImportDutyRule`) that apply a rate and round to the nearest nickel
- **`Receipt`** — accumulates `LineItem`s and renders the final formatted output

No network access to Ollama? `ProductClassifier` fails closed: anything it
can't classify is treated as `:other` (full tax rate), and parsing continues
instead of crashing.

## Table of contents

<!-- START doctoc -->
<!-- END doctoc -->

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [From the command line](#from-the-command-line)
  - [With Docker](#with-docker)
- [Input format](#input-format)
- [Tax rules](#tax-rules)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Error handling](#error-handling)
- [Testing](#testing)
- [FAQ](#faq)
- [License](#license)

## Requirements

- Ruby (see `Dockerfile` for the version this project is built/tested against)
- [Bundler](https://bundler.io)
- An [Ollama](https://ollama.com) server reachable at `OLLAMA_URL` (defaults to
  `http://localhost:11434`), with the model set in `OLLAMA_MODEL` pulled
  (defaults to `qwen3:0.6b`) — only needed to classify products; see
  [Error handling](#error-handling) for what happens without it

## Installation

```sh
bundle install
```

## Usage

### From the command line

The program reads the receipt from STDIN — there's no file argument, so run
it and type the receipt directly:

```sh
ruby main.rb
```

It greets you with a header explaining what to do and how to leave:

```
=== Sales Tax Calculator ===
Enter one item per line as: <quantity> <description> at <price>
Example: 2 book at 12.49

Type 'checkout' when you're done adding items to see the receipt.
Type 'exit' to quit without calculating.
```

Type one item per line. When you're done, type `checkout` to see the
receipt, or `exit` to leave without calculating anything.

For example, typing:

```
2 book at 12.49
1 music CD at 14.99
1 chocolate bar at 0.85
checkout
```

prints:

```
2 book: 24.98
1 music CD: 16.49
1 chocolate bar: 0.85
Sales Taxes: 1.50
Total: 42.32
```

After the receipt, the program doesn't exit — it asks what to do next:

```
Type 'new' to start a new basket, or 'exit' to quit.
```

Type `new` to go back to an empty basket (the header is shown again), or
`exit` to close the program.

### With Docker

Use `docker compose run`, not `docker compose up` — `up` starts both
services in the background and only streams their logs, it does **not**
connect your terminal's STDIN to the container.

```sh
docker compose run --rm sales-tax
```

This builds the image if needed, starts the `ollama` dependency for you, and
wires `OLLAMA_URL`/`OLLAMA_MODEL` automatically. It behaves exactly like
running locally: same header, `checkout`/`exit` while building a basket, and
the `new`/`exit` prompt after each receipt.

## Input format

Each line must match `"<quantity> <description> at <price>"`:

```
2 book at 12.49
```

- `quantity` — a positive integer
- `description` — free text; the word "imported" (case-insensitive, anywhere
  in the description) marks the product as imported
- `price` — the shelf price, with or without a decimal part

Blank lines and lines that don't match this pattern are silently skipped, and
so is any single line that fails validation (e.g. a quantity of `0`) — the
rest of the receipt is still parsed.

## Tax rules

| Rule | Rate | Applies to |
| --- | --- | --- |
| `BasicSalesTaxRule` | 10% | Everything except `book`, `food`, and `medical` products |
| `ImportDutyRule` | 5% | Any product marked as imported, with no exemptions |

Each applicable rule's tax is calculated on the base price, rounded up
independently to the nearest `0.05`, and then summed — matching the classic
"round each tax component, not the total" rounding rule.

## Configuration

| Environment variable | Default | Description |
| --- | --- | --- |
| `OLLAMA_URL` | `http://localhost:11434` | Base URL of the Ollama server used for classification |
| `OLLAMA_MODEL` | `qwen3:0.6b` | Model name Ollama should use to classify product descriptions |

## Architecture

```
main.rb
  └─ InputParser#parse
       ├─ builds Product (via ProductClassifier#classify for category)
       └─ builds LineItem (via TaxCalculator#calculate for tax_amount)
            └─ Receipt#add_item
```

| Class | Responsibility |
| --- | --- |
| `Product` | Validated value object: name, base price, category, imported flag |
| `LineItem` | A quantity of a `Product`, computing shelf price, tax, and total |
| `Receipt` | A collection of `LineItem`s, rendering the final receipt text |
| `InputParser` | Parses raw text into a `Receipt` |
| `ProductClassifier` | Classifies a description into a category via Ollama |
| `TaxCalculator` | Applies a set of `TaxRule`s to a `Product` |
| `TaxRule` | Interface for a single tax rule (`BasicSalesTaxRule`, `ImportDutyRule`) |

## Error handling

- **Ollama unreachable, slow, or returns an unusable answer** — `ProductClassifier`
  raises `ProductClassificationError` internally; `InputParser` catches it,
  logs a warning to STDERR, and defaults the product to `:other` rather than
  failing the whole receipt.
- **A line matches the input format but fails domain validation** (e.g.
  quantity `0`) — `InputParser` catches the resulting `LineItemValidationError`,
  logs a warning, and skips just that line.
- **Untrusted product descriptions** — the text sent to the LLM is wrapped in
  an explicit `<product>...</product>` delimiter with instructions to treat it
  as data, not commands, and the model's answer is validated against a fixed
  category whitelist before being trusted.

## Testing

```sh
bundle exec rspec
```

Lint the codebase with:

```sh
bundle exec rubocop
```

## FAQ

<details>
<summary>Why classify products with an LLM instead of a lookup table?</summary>

The classic kata assumes you're told each product's category up front. This
project instead treats the category as something that has to be inferred from
free text, the way it would need to be for real, unstructured receipt data.
`ProductClassifier` is an isolated, swappable dependency — `InputParser`
only depends on it responding to `#classify`.
</details>

<details>
<summary>What happens if I don't have Ollama running?</summary>

Every product gets classified as `:other` (full sales tax, no exemption), and
a warning is printed to STDERR for each one. Parsing still succeeds.
</details>

<details>
<summary>How is rounding handled?</summary>

Each tax rule's amount is rounded up independently to the nearest `0.05`
before the rule amounts are summed, matching the expected behavior from the
original kata's test cases.
</details>

## License

[MIT](LICENSE)
