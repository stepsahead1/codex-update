# codex-update

This file is designed to address error https://github.com/openai/codex/issues/49418

I quote: 
"When Codex CLI is upgraded, the managed app-server/daemon should be updated automatically to the same version.

Currently, upgrading the CLI does not necessarily update the managed app-server. This can leave the CLI and the background server on different versions, which is confusing and can preserve bugs that were already fixed in newer releases."


This script updates the Codex CLI, stops any running Codex app-server instances, updates the daemon/server package, and then starts the updated daemon and app server.


