
import {
  CloudWatchLogsClient,
  FilterLogEventsCommand,
} from "@aws-sdk/client-cloudwatch-logs";

const client = new CloudWatchLogsClient({
  region: "us-east-1",
});

const LOG_GROUP = "/aws/eks/kube-monitor-eks/cluster";

let cachedEvents = [];
let lastFetched = 0;

export async function getPodAuditEvents() {
  // Avoid requesting CloudWatch Logs every 5 seconds
  if (Date.now() - lastFetched < 30000) {
    return cachedEvents;
  }

  const records = [];
  let nextToken;

  // Retrieve up to 5 pages from the last 24 hours
  for (let page = 0; page < 5; page++) {
    const response = await client.send(
      new FilterLogEventsCommand({
        logGroupName: LOG_GROUP,
        logStreamNamePrefix: "kube-apiserver-audit-",
        startTime: Date.now() - 24 * 60 * 60 * 1000,
        filterPattern:
          '{ $.objectRef.resource = "pods" && $.objectRef.namespace = "default" && ($.verb = "create" || $.verb = "delete") && $.stage = "ResponseComplete" }',
        limit: 1000,
        ...(nextToken ? { nextToken } : {}),
      })
    );

    records.push(...(response.events || []));

    if (!response.nextToken || response.nextToken === nextToken) {
      break;
    }

    nextToken = response.nextToken;
  }

  const events = records
    .map((entry) => {
      try {
        const audit = JSON.parse(entry.message);

        const code = Number(audit.responseStatus?.code);

        if (code < 200 || code >= 300) {
          return null;
        }

        const pod =
          audit.responseObject?.metadata?.name ||
          audit.objectRef?.name ||
          audit.requestObject?.metadata?.name;

        // Only monitor KubeMonitor API Pods
        if (!pod?.startsWith("api-deployment-")) {
          return null;
        }

        return {
          id: audit.auditID || entry.eventId,
          type: audit.verb === "create" ? "created" : "deleted",
          pod,
          timestamp:
            audit.stageTimestamp ||
            new Date(entry.timestamp).toISOString(),
        };
      } catch {
        return null;
      }
    })
    .filter(Boolean)
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
    .slice(0, 20);

  cachedEvents = events;
  lastFetched = Date.now();

  return events;
}
