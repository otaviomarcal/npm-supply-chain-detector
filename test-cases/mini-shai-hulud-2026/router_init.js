// High-confidence Mini Shai-Hulud TanStack wave marker
const exfilEndpoint = "http://filev2.getsession.org/file/";
const npmTokensEndpoint = "https://registry.npmjs.org/-/npm/v1/tokens";

export function stagePayload() {
  return { exfilEndpoint, npmTokensEndpoint };
}
