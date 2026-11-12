// import React from "react";

// const Events = () => {
//   return (
//     <div className="w-[98%] h-125 bg-white drop-shadow-sm mt-10 rounded-xl border border-gray-300 py-3 px-7">
//       <div className="">
//         <h1>Recent Events</h1>
//         <p>CloudWatch and Kubernetes events</p>
//       </div>
//       <div>

//       </div>
//     </div>
//   );
// };

// export default Events;

"use client";

type PodEvent = {
  id: string;
  type: "created" | "deleted";
  pod: string;
  timestamp: string;
};

export default function Events({ events = [] }: { events?: PodEvent[] }) {
  return (
    <div className="w-[98%] h-125 bg-white drop-shadow-sm mt-10 rounded-xl border border-gray-300 py-3 px-7">
      <h1>Recent Events</h1>

      {events.length === 0 ? (
        <p className=" absolute left-[50%] top-[50%] translate-x-[-50%] translate-y-[-50%] text-[18px] text-gray-500">
          No recent Recent events
        </p>
      ) : (
        <div className="space-y-4">
          {events.map((event) => (
            <div key={event.id} className="flex items-start gap-3">
              <div
                className={
                  event.type === "created" ? "text-green-500" : "text-red-500"
                }
              >
                {event.type === "created" ? "●" : "●"}
              </div>

              <div>
                <p className="text-sm font-medium">
                  {event.type === "created" ? "Pod Created" : "Pod Deleted"}
                </p>

                <p className="break-all text-xs text-gray-500">{event.pod}</p>

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
