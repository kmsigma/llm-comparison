# LLM Comparison

As part of my home life, I've got a home lab.  And I like to run various workloads on that lab.  Since I'm a nerd, I've been trying to get a highly-available kubernetes cluster setup on three physical machines with shared storage.  Since I'm _very_ new to Kubernetes at the time of writing, I turned to the internet to help me get started. My research in that area will ultimately be posted in a different repo.

## This repo

Large Language Models (LLMs) are a great tool for doing quick research on technical things, but each one seems to have their own hallucinations.  In this particular repo, I'm going to try and collect my findings on as many LLMs as I can in my spare time.

I started with a simple [prompt](prompt.md) that I felt was a slow-pitch.  It checked if the LLM "knew" how to read a GitHub repository, could do a little research on a well known documentation site, and build a functional script.  The results varied, and I'm providing my own commentary within the scripts themselves.

Responses:

| LLM | Engine | Response | Response Feedback | Script | Script Corrections/Feedback | Grade | Does it Run? |
|-----|--------|----------|-------------------|--------|-----------------------------|-------|--------------|
| Copilot | Think Deeper | [Response](copilot-thinkdeeper/response.md) | [Response Feedback](copilot-thinkdeeper/response-feedback.md) | [Script](copilot-thinkdeeper/script.ps1) | [Script Corrections](copilot-thinkdeeper/script-corrections.ps1) | ⭐⭐⭐⭐ (4/5) | 👎 |
| ChatGPT | (vanilla) | [Response](chatgpt/response.md) | | [Script](chatgpt/script.ps1) | | | ❓ |
| Liquid AI | LFM2-1.2b | [Response](liquid.ai-lfm2-1.2b/response.md) | | [Script](liquid.ai-lfm2-1.2b/script.ps1) | | | ❓ |
| Liquid AI | LFM2-2.6b | [Response](liquid.ai-lfm2-2.6b/response.md) | | [Script](liquid.ai-lfm2-2.6b/script.ps1) | | | ❓ |
| Liquid AI | LFM2-8B-A1B | [Response](liquid.ai-lfm2-8b-a1b/response.md) | | [Script](liquid.ai-lfm2-8b-a1b/script.ps1) | | | ❓ |

## Notes

The 'Responses' from each LLM is presented as close to the original response in a Markdown format.  Some LLMs have custom wrappers for certain elements which I will not be attempting to replicate.

I elected to skip the "follow-up" responses from the LLMs ("What would you like me to do next?")
