---
name: polymarket
description: Query Polymarket prediction markets for probability data and research insights on real-world events.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [Research, Polymarket, Prediction-Markets, Probability, Events]
    related_skills: []
---

# Polymarket

## Purpose

- Use this skill to pull live prediction market data for research and forecasting workflows.
- Polymarket is useful for probability-oriented views of current events, elections, macro themes, and sports or policy questions.
- Treat the market price as a crowd-implied probability signal, not ground truth.

## API Surface

- Base reference: `https://clob.polymarket.com/`
- Public market discovery is commonly accessed through the gamma API.
- Start with active markets and then filter by topic or keyword.

## Fetch Active Markets

```bash
curl "https://gamma-api.polymarket.com/markets?active=true&limit=20"
```

- This returns a JSON list of market objects.
- Use small limits during exploration and larger limits when building a topic watcher.

## Important Market Fields

- `question`
- `outcomes`
- `outcomePrices`
- `volume`

These are usually enough for first-pass research.

## Interpret the Data

- `question` is the market prompt.
- `outcomes` lists the named outcomes, often `Yes` and `No`.
- `outcomePrices` represents the current market-implied probabilities.
- `volume` helps indicate liquidity and how much weight to assign the price signal.

## Probability Interpretation

- Interpret a price like `0.65` as roughly a 65 percent implied chance.
- Lower-liquidity markets may be noisier.
- High probability is not certainty.
- Large probability moves over time can matter more than a single point estimate.

## Python Example

```python
import requests

url = "https://gamma-api.polymarket.com/markets?active=true&limit=20"
markets = requests.get(url, timeout=20).json()

for market in markets:
    question = market.get("question")
    prices = market.get("outcomePrices")
    print(question, prices)
```

- This is the minimum useful fetch loop.
- Add defensive parsing because API field presence can vary.

## Filter by Category or Keyword

- Filter by category when tracking a domain like politics, crypto, or macro.
- Filter by keyword when you care about a specific topic such as `tariffs`, `Fed`, or `OpenAI`.
- Keep the raw result set if you want to backtest or compare price movement later.

Simple pattern:

```python
keyword = "election"
filtered = [
    m for m in markets
    if keyword.lower() in (m.get("question", "")).lower()
]
```

## Research Use Cases

- calibration research
- current event probabilities
- forecasting support
- comparing market odds to analyst narratives
- monitoring how expectations move after news breaks

## Practical Workflow

1. Pull active markets.
2. Filter to the topic you care about.
3. Extract `question`, `outcomes`, `outcomePrices`, and `volume`.
4. Rank by liquidity or relevance.
5. Compare probability shifts over time for insight.

## Caveats

- Prediction markets reflect tradable sentiment, not guaranteed truth.
- Low volume can distort the apparent probability.
- Market structure and fees can affect behavior.
- Always interpret results in context of liquidity and market design.

## Summary

- Use Polymarket for research into crowd-implied probabilities on real-world events.
- Start with `https://clob.polymarket.com/` and fetch active markets via `https://gamma-api.polymarket.com/markets?active=true&limit=20`.
- Useful market fields include `question`, `outcomes`, `outcomePrices`, and `volume`.
- A price such as `0.65` can be read as about a 65 percent implied chance.
- Use simple Python `requests` scripts or `curl`, then filter by category or keyword for forecasting and calibration workflows.
