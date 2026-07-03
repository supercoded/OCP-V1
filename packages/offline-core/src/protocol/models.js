export const DeliveryState = Object.freeze({
  QUEUED: "queued",
  SENT: "sent",
  ACKED: "acked",
  FAILED: "failed"
});

export function toRadioStartConfig(configId) {
  return {
    toRadio: {
      startConfig: true,
      wantConfigId: configId
    }
  };
}
