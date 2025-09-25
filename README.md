---
title: DS 553 Case Study 1
emoji: 💬
colorFrom: yellow
colorTo: purple
sdk: docker
app_port: 7860
tags:
  - streamlit
app_file: app.py
pinned: false
hf_oauth: true
hf_oauth_scopes:
- inference-api
---

## Deployment

Changes are synced from `main` to the HuggingFace space. 

Spaces link: https://huggingface.co/spaces/wegold/cs553-cs-1

Note: GitHub actions test are DISABLED right now, since it increase our HuggingFace usage.

Note 2: Spaces automatically exposes secrets as environment variables accessible inside the docker container, so you just 
need to make sure the secret is set for the space.

## Running Locally

Easier running:

- `pip install -r requirements.txt`
- `python app.py`

For all development, run locally.

To do this, use Docker!

Install:
https://docs.docker.com/desktop/

If on Windows, install WSL first!

https://learn.microsoft.com/en-us/windows/wsl/install

Once you are ready, run it in the following way:

Make sure Docker Desktop is running.

Then,

`./run-dev.sh`

You might need to do `chmod +x run-dev.sh`