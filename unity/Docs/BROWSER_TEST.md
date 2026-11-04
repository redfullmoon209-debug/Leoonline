# Unity WebGL playtest through a browser (no local Unity install for players)

## Status
A **build-and-deploy pipeline** is configured as source, not proof of a successful Unity WebGL build. Do not claim the /unity/ link is playable until the GitHub Actions run reports green, deploy-pages succeeds, and a real browser smoke test completes.

- Target URL after successful deployment:
  https://redfullmoon209-debug.github.io/Leoonline/unity/
- Existing Godot game stays:
  https://redfullmoon209-debug.github.io/Leoonline/
- GitHub Actions: **Unity WebGL Browser Preview** (branch unity-mmorpg-foundation).
- First test scene: 3D primitive demo, not the final FemaleLeo model and not yet networked MMO.
- Initial controls target desktop keyboard/mouse; touch controls need a separate mobile implementation.

## How the cloud pipeline works
1. GameCI \`unity-builder@v4\` runs Unity 6.3 LTS WebGL inside a GitHub-hosted cloud environment; developer machines do not need Unity installed.
2. \`Leoonline.EditorTools.UnityWebGLBuild.Build()\` makes the 3D scene using primitive assets, exports WebGL to \`unity/build/WebGL\`, using **uncompressed** files suitable for static Pages hosting.
3. The workflow verifies expected files and uploads the actual WebGL build.
4. To preserve the existing Godot game, the deploy job downloads the latest successful \`publish-pages.yml\` Pages artifact from main, expands its tarball, adds the Unity output to \`/unity/\`, and redeploys one combined site.
5. Changes to \`publish-pages.yml\` in the same PR can keep the Unity export in the site during later Godot redeployments, by downloading the most recent successful Unity WebGL build artifact.

## Blocker: Unity license/activation
Unity Editor needs a licensed account even in GitHub Actions. The connected repository has not been shown to have a usable Unity license. **No ChatGPT or GitHub API can manufacture or bypass a Unity license.** Do not place secrets in code, PR text, issue comments, chat, or committed files.

For a valid Unity Pro/Enterprise serial-based CI setup:
- Add \`UNITY_EMAIL\`, \`UNITY_PASSWORD\`, and \`UNITY_SERIAL\` through
  GitHub repository **Settings > Secrets and variables > Actions > New repository secret**.
- For license-file based installations supported by the GameCI action, it expects \`UNITY_LICENSE\` plus account credentials; **Unity Personal can no longer use manual activation through the legacy Unity website**. Consult current official Unity licensing terms and GameCI activation docs.
- Alternative for Unity Personal users: configure **Unity Build Automation** in Unity Cloud through the account owner, connect this GitHub repository and WebGL build target, then download/host the produced build (the GameCI workflow will need adjusting).
- Never disclose a Unity account password to ChatGPT.

## Start/run checks
- Push to the \`unity-mmorpg-foundation\` branch starts the workflow automatically.
- With a valid license, it builds and attempts to publish to the preview URL; failures are visible in the GitHub Actions logs.
- GitHub Pages deploy permissions, artifact availability, cloud usage quotas, and Unity compilation issues may still require adjustments.
- The PR remains draft until the actual browser is verified. GitHub Actions deployment of a PR branch can be subject to repository environment restrictions.
- The legacy Godot Pages artifact expires; if a fresh artifact is unavailable, re-run the existing main \`publish-pages.yml\` workflow, not a destructive Pages replacement.

## Production caution
The published code is an OFFLINE local test. Browser support does **not** make it a real MMORPG. Multiplayer, PK, arena, guild war, authenticated identities and authoritative server will be separate future milestones.
