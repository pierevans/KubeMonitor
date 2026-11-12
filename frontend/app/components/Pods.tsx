
"use client";

import React from "react";

type Pod = {
  name: string;
  status: string;
  ready: boolean;
  cpu: number | null;
  createdAt: string | null;
};

const Pods = ({ pods = [] }: { pods?: Pod[] }) => {

  const running = pods.filter(
    (pod) => pod.status === "Running" && pod.ready
  ).length;

  const getAge = (createdAt: string | null) => {
    if (!createdAt) return "N/A";

    const difference = Date.now() - new Date(createdAt).getTime();

    if (!Number.isFinite(difference) || difference < 0) {
      return "N/A";
    }

    const minutes = Math.floor(difference / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d`;
    if (hours > 0) return `${hours}h`;
    return `${minutes}m`;
  };

  const getStatusColor = (status: string, ready: boolean) => {
    if (status === "Running" && ready) {
      return "bg-green-100 text-green-700";
    }

    if (status === "Pending" || status === "ContainerCreating") {
      return "bg-yellow-100 text-yellow-700";
    }

    return "bg-red-100 text-red-700";
  };

  return (
    <div className="w-[98%] min-h-100 bg-white drop-shadow-sm mt-10 rounded-xl border border-gray-300 py-3 px-7">

      {/* HEADER */}
      <div className="flex items-center justify-between">
        <h1>Running Pods</h1>

        <div className="flex items-center gap-2 rounded-full px-3 py-1 bg-blue-100 text-blue-600 w-fit">
          <div className="w-2 h-2 rounded-full bg-blue-600"></div>
          <p>{running} running</p>
        </div>
      </div>

      {/* TABLE HEADER */}
      <ul className="flex items-center mt-5 text-gray-500">
        <li className="basis-7/15">Pod name</li>
        <li className="basis-4/15">Status</li>
        <li className="basis-2/15">CPU</li>
        <li className="basis-2/15">Age</li>
      </ul>

      {/* POD ROWS */}
      <div className="mt-4">
        {pods.length === 0 ? (
          <p className="text-gray-400 text-center py-10">
            No Pod information available
          </p>
        ) : (
          pods.map((pod) => (
            <div
              key={pod.name}
              className="flex items-center border-t border-gray-100 py-4 text-sm"
            >
              {/* POD NAME */}
              <div className="basis-7/15 pr-3 min-w-0">
                <p className="font-medium text-gray-800 break-all">
                  {pod.name}
                </p>
              </div>

              {/* STATUS */}
              <div className="basis-4/15">
                <span
                  className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                    pod.status,
                    pod.ready
                  )}`}
                >
                  <span className="w-1.5 h-1.5 bg-current rounded-full" />
                  {pod.status}
                  {pod.status === "Running" && !pod.ready
                    ? " (Not Ready)"
                    : ""}
                </span>
              </div>

              {/* CPU */}
              <div className="basis-2/15 text-gray-700">
                {pod.cpu !== null ? `${pod.cpu} mCPU` : "N/A"}
              </div>

              {/* AGE */}
              <div className="basis-2/15 text-gray-700">
                {getAge(pod.createdAt)}
              </div>
            </div>
          ))
        )}
      </div>

    </div>
  );
};

export default Pods;
