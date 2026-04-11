---
title: "Example Lecture"
author: Your Name
title-slide-attributes:
  data-background-image: img/dalmeny.jpg
  data-background-size: cover
---

# Basic Slides

## First Slide

This is an example lecture slide. Edit this file or create new lecture markdown files in the `lectures/` directory.

- Bullet points work as expected
- Use `##` headings for new slides
- Use `#` headings for section title slides

## Columns Example

:::::::::::::: {.columns}

:::{.column width="50%"}

Left column content goes here.

:::

:::{.column width="50%"}

Right column content goes here.

:::

::::::::::::::

## Headings

### Sub headings

Sub headings show up in the slide

### Next Heading

Here's another one.

## Slide with Background Image {background-image="img/sullivans.jpg" background-size="cover"}

Content can overlay a background image.

Image of [Sullivans Creek, ANU Campus, Canberra](https://en.wikipedia.org/wiki/Sullivans_Creek).

## Speaker Notes

This slide has speaker notes — press `S` in the browser to open the presenter view.

:::notes
These are speaker notes. They are only visible in presenter view, not to the audience.
You can write as much detail here as you like.
:::

## Citations

You can cite references from `references.bib` using pandoc citation syntax [@Norman:2013].

Conference papers can also be cited [@example-paper:2024].

You can also include a page number [@Norman:2013, p42].

# Callout Boxes

## Info Box

::: {.info-box}
**Info:** Use an info box to highlight background reading, useful links, or supplementary context.
:::

## Warning Box

::: {.warn-box}
**Warning:** Use a warning box to flag common mistakes or things students should watch out for.
:::

## Error Box

::: {.error-box}
**Error:** Use an error box to highlight something that is incorrect or must be avoided.
:::

## Success Box

::: {.success-box}
**Success:** Use a success box to show a correct approach, expected output, or a positive outcome.
:::

# Activity Slides

## Think Activity

::: {.think-box}
**Think:** Take 2 minutes to think about how you would approach this problem before we discuss it as a group.
:::

## Talk Activity

::: {.talk-box}
**Talk:** Turn to the person next to you and discuss: what are the trade-offs between these two approaches?
:::

## Push Activity

::: {.push-box}
**Push:** Extend your solution to handle edge cases. Can you make it work for negative numbers too?
:::

## Extension Activity

::: {.extension-box}
**Extension:** If you finish early, look up how this technique is applied in a real-world system and share your findings.
:::

## Activity Section Box

::: {.activity}
**Your Turn:** Complete the exercise on the worksheet. You have 10 minutes.

1. Step one
2. Step two
3. Step three
:::

## Questions

::: {.questions}
**Any Questions?** Slides and resources are on the course website.
:::

## References
