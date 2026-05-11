---
# Metadata
title: Slide Deck Cover With Background
date: 2026-05-07
author: Nicolas Goudry
affiliation: https://github.com/nicolas-goudry
lang: en-US

# Marp config
paginate: false
transition: none
---

<style scoped>
  /* Allow multiple backgrounds container to fill whole slide width */
  div[data-marpit-advanced-background-container] {
    width: 100%! important;
  }

  /* Superpose portrait background image on full-width background */
  div[data-marpit-advanced-background-container] figure:last-child {
    position: absolute;
    width: 40%;
    height: 100%;
    background-size: contain;
  }

  h1 {
    margin-block-start: 6rem !important;
    margin-block-end: .3rem;
    padding-block-end: 0;
    text-shadow: 0 0 5px rgba(22, 43, 70, 1);
  }

  h1 code {
    text-shadow: none;
  }

  .event-details {
    position: absolute;
    bottom: 1rem;
    right: 1rem;
    text-align: right;
  }

  .event-name {
    color: var(--blue);
    font-size: 1.3rem;
    font-weight: bold;
    line-height: 1;
  }

  .event-timelocation {
    color: var(--peach);
    font-style: italic;
    font-size: 0.75rem;
  }
</style>

![bg](../assets/images/bg/marketing-cover.jpg)
![bg grayscale left:35%](../assets/images/misc/portrait.png)

# Slide Deck Cover<br/>With Background

<div class="event-details">
  <div class="event-name">
    Event Name Here
  </div>
  <div class="event-timelocation">
  1970, 1<sup>st</sup> January — Greenwich, England
  </div>
</div>
