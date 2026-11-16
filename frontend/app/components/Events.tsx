"use client";

type PodEvent = {
  id: string;
  type: "created" | "deleted";
  pod: string;
  timestamp: string;
};



export default function Events({
  events = [],
}: {
  events?: PodEvent[];
}) {
  // Sort events from newest to oldest
  const sortedEvents = [...events].sort(
    (a, b) =>
      new Date(b.timestamp).getTime() -
      new Date(a.timestamp).getTime()
  );

  // Remove duplicate CloudWatch audit records
  const seen = new Set<string>();

  const recentEvents = sortedEvents.filter((event) => {
    const key = `${event.type}-${event.pod}`;

    if (seen.has(key)) return false;

    seen.add(key);
    return true;
  });

  return (
    <div className="w-[98%] h-125 bg-white drop-shadow-sm mt-10 rounded-xl border border-gray-300 py-3 px-7 flex flex-col">
      <h1>Recent Events</h1>

      {recentEvents.length === 0 ? (
        <div className="flex-1 flex items-center justify-center">
          <p className="text-[18px] text-gray-500">
            No recent Pod events
          </p>
        </div>
      ) : (
        <div className="mt-5 space-y-4 overflow-y-auto flex-1">
          {recentEvents.map((event) => (
            <div
              key={`${event.type}-${event.pod}`}
              className="flex items-start gap-3 border-b border-gray-100 pb-3"
            >
              <div
                className={
                  event.type === "created"
                    ? "text-green-500"
                    : "text-red-500"
                }
              >
                ●
              </div>

              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium">
                  {event.type === "created"
                    ? "Pod Created"
                    : "Pod Deleted"}
                </p>

                <p className="break-all text-xs text-gray-500">
                  {event.pod}
                </p>

                <p className="mt-1 text-xs text-gray-400">
                  {new Date(event.timestamp).toLocaleString()}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}


